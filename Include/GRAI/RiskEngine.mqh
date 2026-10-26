//+------------------------------------------------------------------+
//| GRAI RiskEngine — hard caps; GLM cannot raise these               |
//+------------------------------------------------------------------+
#ifndef GRAI_RISK_ENGINE_MQH
#define GRAI_RISK_ENGINE_MQH

#include "AuditLog.mqh"
#include "Types.mqh"

struct GRAI_RiskConfig
{
   double risk_pct_equity;      // base / floor for ladder
   double max_episode_risk_pct; // hard ceiling vs equity
   double max_open_risk_pct;
   double max_daily_loss_pct;
   double max_equity_dd_pct;
   int    max_layers;
   int    max_trades;
   double max_margin_usage;     // 0..1
   bool   adverse_averaging;    // live default false
   bool   llm_enabled;
   bool   deterministic_fallback; // live false
};

GRAI_RiskConfig g_grai_risk;

// Deterministic risk ladder (LLM cannot raise)
double g_grai_active_risk_pct  = 1.0;
double g_grai_risk_ladder_base = 1.0;
double g_grai_risk_ladder_step = 0.5;
double g_grai_risk_ladder_max  = 2.0;

void GRAI_RiskDefaults()
{
   ZeroMemory(g_grai_risk);
   g_grai_risk.risk_pct_equity       = 1.0;
   g_grai_risk.max_episode_risk_pct  = 3.0;
   g_grai_risk.max_open_risk_pct     = 5.0;
   g_grai_risk.max_daily_loss_pct    = 5.0;
   g_grai_risk.max_equity_dd_pct     = 5.0;
   g_grai_risk.max_layers            = 5;
   g_grai_risk.max_trades            = 5;
   g_grai_risk.max_margin_usage      = 0.5;
   g_grai_risk.adverse_averaging     = false;
   g_grai_risk.llm_enabled           = false;
   g_grai_risk.deterministic_fallback = false;
   g_grai_active_risk_pct  = 1.0;
   g_grai_risk_ladder_base = 1.0;
   g_grai_risk_ladder_step = 0.5;
   g_grai_risk_ladder_max  = 2.0;
}

void GRAI_RiskLadderInit(const double base, const double step, const double max_pct)
{
   g_grai_risk_ladder_base = (base > 0.0 ? base : 1.0);
   g_grai_risk_ladder_step = (step > 0.0 ? step : 0.5);
   g_grai_risk_ladder_max  = (max_pct > g_grai_risk_ladder_base ? max_pct : g_grai_risk_ladder_base);
   g_grai_active_risk_pct  = g_grai_risk_ladder_base;
   g_grai_risk.risk_pct_equity = g_grai_risk_ladder_base;
}

void GRAI_RiskLadderReset(const string reason)
{
   g_grai_active_risk_pct = g_grai_risk_ladder_base;
   GRAI_Log("RISK_RESET", StringFormat("%s risk=%.1f%%", reason, g_grai_active_risk_pct));
}

void GRAI_RiskOnEquityKill()
{
   GRAI_Log("KILL", "equity_dd");
   GRAI_RiskLadderReset("dd");
}

// After episode/basket close: bump only on trend-aligned win; wrong-bias loss → 1%.
void GRAI_RiskLadderOnClose(const int direction, const int bias, const double realized)
{
   const bool aligned =
      (bias == GRAI_BIAS_LONG  && direction == OP_BUY) ||
      (bias == GRAI_BIAS_SHORT && direction == OP_SELL);
   if(realized > 0.0 && aligned)
   {
      double next = g_grai_active_risk_pct + g_grai_risk_ladder_step;
      if(next > g_grai_risk_ladder_max)
         next = g_grai_risk_ladder_max;
      if(next > g_grai_active_risk_pct + 1e-12)
      {
         g_grai_active_risk_pct = next;
         GRAI_Log("RISK_UP", StringFormat("risk=%.1f%% dir=%d bias=%d pnl=%.2f",
            g_grai_active_risk_pct, direction, bias, realized));
      }
      return;
   }
   if(realized < 0.0 && !aligned)
      GRAI_RiskLadderReset("wrong_bias_loss");
}

int GRAI_ClassCap(const int cls) // ENUM_GRAI_CLASS
{
   if(cls == 1) return 1;  // LPM
   if(cls == 2) return 5;  // MPM
   if(cls == 3) return g_grai_risk.max_layers; // HPM
   return 1; // UNCONFIRMED
}

int GRAI_AllowedLayers(const int class_cap, const int risk_cap,
                       const int margin_cap, const int episode_rem,
                       const int glm_rec) // glm_rec <0 = ignore
{
   int a = class_cap;
   if(risk_cap < a) a = risk_cap;
   if(margin_cap < a) a = margin_cap;
   if(episode_rem < a) a = episode_rem;
   if(glm_rec >= 0 && glm_rec < a) a = glm_rec;
   if(a < 0) a = 0;
   return a;
}

// lots from % equity and SL distance (broker tick value)
double GRAI_LotsFromRisk(const double equity, const double risk_pct,
                         const double sl_distance, const double tick_size,
                         const double tick_value, const double vol_min,
                         const double vol_step, const double vol_max)
{
   if(risk_pct <= 0.0 || sl_distance <= 0.0 || tick_size <= 0.0 || tick_value <= 0.0)
      return 0.0;
   double cash = equity * (risk_pct / 100.0);
   double loss_per_lot = (sl_distance / tick_size) * tick_value;
   if(loss_per_lot <= 0.0)
      return 0.0;
   double lots = cash / loss_per_lot;
   if(vol_step > 0.0)
      lots = MathFloor(lots / vol_step) * vol_step;
   if(lots < vol_min) lots = 0.0;
   if(vol_max > 0.0 && lots > vol_max) lots = vol_max;
   return lots;
}

bool GRAI_RiskPassNewLayer(const int current_layers, const double layer_risk_cash,
                           const double equity, const double remaining_episode_risk)
{
   if(current_layers >= g_grai_risk.max_layers)
   {
      GRAI_Log("RISK_FAIL", "max_layers");
      return false;
   }
   if(current_layers >= g_grai_risk.max_trades)
   {
      GRAI_Log("RISK_FAIL", "max_trades");
      return false;
   }
   if(layer_risk_cash > remaining_episode_risk + 1e-12)
   {
      GRAI_Log("RISK_FAIL", "episode_risk");
      return false;
   }
   double ep_cap = equity * (g_grai_risk.max_episode_risk_pct / 100.0);
   if(layer_risk_cash > ep_cap + 1e-12)
   {
      GRAI_Log("RISK_FAIL", "episode_cap");
      return false;
   }
   GRAI_Log("RISK_PASS", StringFormat("layers=%d risk=%.4f", current_layers + 1, layer_risk_cash));
   return true;
}

#endif
