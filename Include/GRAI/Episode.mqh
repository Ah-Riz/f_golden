//+------------------------------------------------------------------+
//| GRAI Episode — one parent entry; MOM_D shares episode_id          |
//+------------------------------------------------------------------+
#ifndef GRAI_EPISODE_MQH
#define GRAI_EPISODE_MQH

#include "Types.mqh"
#include "AuditLog.mqh"

GRAI_Episode g_grai_ep;
ulong        g_grai_ep_seq = 0;

void GRAI_EpisodeReset()
{
   ZeroMemory(g_grai_ep);
}

bool GRAI_EpisodeActive()
{
   return g_grai_ep.active;
}

ulong GRAI_EpisodeOpenEx(const int parent_mom, const int direction,
                         const int regime, const int bias,
                         const double equity_open, const double risk_budget)
{
   if(g_grai_ep.active)
      return g_grai_ep.episode_id;

   g_grai_ep_seq++;
   g_grai_ep.episode_id        = g_grai_ep_seq;
   g_grai_ep.parent_momentum   = parent_mom;
   g_grai_ep.direction         = direction;
   g_grai_ep.regime_at_start   = regime;
   g_grai_ep.bias_at_start     = bias;
   g_grai_ep.equity_at_open    = equity_open;
   g_grai_ep.start_time        = TimeCurrent();
   g_grai_ep.layer_count       = 1;
   g_grai_ep.total_risk_budget = risk_budget;
   g_grai_ep.remaining_risk    = risk_budget;
   g_grai_ep.active            = true;

   GRAI_Log("OPEN", StringFormat(
      "episode=%s mom=%d dir=%d regime=%d bias=%d risk=%.4f role=PARENT_ENTRY",
      IntegerToString((long)g_grai_ep.episode_id), parent_mom, direction, regime, bias, risk_budget));
   return g_grai_ep.episode_id;
}

ulong GRAI_EpisodeOpen(const int parent_mom, const int direction,
                       const int regime, const double risk_budget)
{
   return GRAI_EpisodeOpenEx(parent_mom, direction, regime, GRAI_BIAS_FLAT,
                             AccountEquity(), risk_budget);
}

bool GRAI_EpisodeAddLayer(const double layer_risk)
{
   if(!g_grai_ep.active)
      return false;
   if(layer_risk > g_grai_ep.remaining_risk + 1e-12)
   {
      GRAI_Log("LAYER_REJECT", StringFormat(
         "episode=%s need=%.4f rem=%.4f",
         IntegerToString((long)g_grai_ep.episode_id), layer_risk, g_grai_ep.remaining_risk));
      return false;
   }
   g_grai_ep.layer_count++;
   g_grai_ep.remaining_risk -= layer_risk;
   GRAI_Log("LAYER_ALLOW", StringFormat(
      "episode=%s layers=%d rem=%.4f role=LAYER_CONTINUATION mom=D",
      IntegerToString((long)g_grai_ep.episode_id), g_grai_ep.layer_count, g_grai_ep.remaining_risk));
   return true;
}

void GRAI_EpisodeClose(const string reason, const double realized)
{
   if(!g_grai_ep.active)
      return;
   g_grai_ep.end_time        = TimeCurrent();
   g_grai_ep.exit_reason     = reason;
   g_grai_ep.realized_profit = realized;
   g_grai_ep.active          = false;
   GRAI_Log("CLOSE", StringFormat(
      "episode=%s reason=%s pnl=%.2f layers=%d parent_mom=%d",
      IntegerToString((long)g_grai_ep.episode_id), reason, realized, g_grai_ep.layer_count,
      g_grai_ep.parent_momentum));
}

#endif
