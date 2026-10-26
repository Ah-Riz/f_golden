//+------------------------------------------------------------------+
//| GRAI Lifecycle — v0.4 entry stages, stop modes, manage modes      |
//| Tighten-only protective stops by default. No profit guarantee.    |
//+------------------------------------------------------------------+
#ifndef GRAI_LIFECYCLE_MQH
#define GRAI_LIFECYCLE_MQH

#include "Types.mqh"
#include "AuditLog.mqh"
#include "SmcLana.mqh"

enum ENUM_GRAI_MANAGE_MODE
{
   GRAI_MANAGE_A_STRUCT_FIXED = 0, // Mode A: structural SL, no SL+ trail
   GRAI_MANAGE_B_DELAYED_SLP  = 1, // Mode B: delayed SL+ (default)
   GRAI_MANAGE_C_STRUCT_TRAIL = 2, // Mode C: structure trail after activate
   GRAI_MANAGE_D_HYBRID       = 3  // Mode D: deferred / experimental
};

enum ENUM_GRAI_STOP_MODE
{
   GRAI_STOP_ATR_FLOOR = 0, // v0.3 max(ATR*mult, RiskPoints*point)
   GRAI_STOP_STRUCT_ATR = 1 // confirmed swing +/- ATR buffer
};

enum ENUM_GRAI_ENTRY_STAGE
{
   GRAI_STAGE_CONTEXT   = 1,
   GRAI_STAGE_BIAS      = 2,
   GRAI_STAGE_SETUP     = 3,
   GRAI_STAGE_LOCATION  = 4,
   GRAI_STAGE_TRIGGER   = 5,
   GRAI_STAGE_EXECUTION = 6,
   GRAI_STAGE_RISK      = 7,
   GRAI_STAGE_AUTHORIZE = 8
};

string GRAI_ManageModeStr(const int mode)
{
   if(mode == GRAI_MANAGE_A_STRUCT_FIXED) return "A_STRUCT";
   if(mode == GRAI_MANAGE_B_DELAYED_SLP)  return "B_DELAYED";
   if(mode == GRAI_MANAGE_C_STRUCT_TRAIL) return "C_TRAIL";
   if(mode == GRAI_MANAGE_D_HYBRID)       return "D_HYBRID";
   return "UNKNOWN";
}

string GRAI_StopModeStr(const int mode)
{
   if(mode == GRAI_STOP_ATR_FLOOR)  return "ATR_FLOOR";
   if(mode == GRAI_STOP_STRUCT_ATR) return "STRUCT_ATR";
   return "UNKNOWN";
}

void GRAI_SkipStage(const int stage, const string reason)
{
   GRAI_Log("SKIP_STAGE", StringFormat("stage=%d %s", stage, reason));
}

// Last confirmed pivot low/high from SMC stacks (index 0 = most recent).
bool GRAI_LastConfirmedSwingLow(double &price)
{
   if(g_grai_smc_plp_n <= 0)
      return false;
   price = g_grai_smc_plp[0];
   return (price > 0.0);
}

bool GRAI_LastConfirmedSwingHigh(double &price)
{
   if(g_grai_smc_php_n <= 0)
      return false;
   price = g_grai_smc_php[0];
   return (price > 0.0);
}

// Structural invalidation price for cmd at decision time (no future pivots).
bool GRAI_StructuralInvalidation(const int cmd, const double atr,
                                 const double buffer_atr, double &inval)
{
   double buf = (atr > 0.0 && buffer_atr > 0.0) ? (buffer_atr * atr) : 0.0;
   if(cmd == OP_BUY)
   {
      double sw = 0.0;
      if(!GRAI_LastConfirmedSwingLow(sw))
         return false;
      inval = sw - buf;
      return true;
   }
   if(cmd == OP_SELL)
   {
      double sw = 0.0;
      if(!GRAI_LastConfirmedSwingHigh(sw))
         return false;
      inval = sw + buf;
      return true;
   }
   return false;
}

// Risk distance from entry to planned SL under stop mode.
double GRAI_PlannedRiskDistance(const int cmd, const double entry,
                                const double atr_floor_risk,
                                const int stop_mode,
                                const double atr,
                                const double buffer_atr,
                                const double max_stop_dist,
                                string &fail_reason)
{
   fail_reason = "";
   if(stop_mode == GRAI_STOP_STRUCT_ATR)
   {
      double inval = 0.0;
      if(!GRAI_StructuralInvalidation(cmd, atr, buffer_atr, inval))
      {
         fail_reason = "no_confirmed_swing";
         return 0.0;
      }
      double dist = 0.0;
      if(cmd == OP_BUY)
         dist = entry - inval;
      else
         dist = inval - entry;
      if(dist <= 0.0)
      {
         fail_reason = "struct_sl_wrong_side";
         return 0.0;
      }
      // Never tighter than ATR floor (volatility buffer floor).
      if(atr_floor_risk > 0.0 && dist < atr_floor_risk)
         dist = atr_floor_risk;
      if(max_stop_dist > 0.0 && dist > max_stop_dist)
      {
         fail_reason = "stop_too_wide";
         return 0.0;
      }
      return dist;
   }
   // ATR_FLOOR
   if(atr_floor_risk <= 0.0)
   {
      fail_reason = "risk_zero";
      return 0.0;
   }
   if(max_stop_dist > 0.0 && atr_floor_risk > max_stop_dist)
   {
      fail_reason = "stop_too_wide";
      return 0.0;
   }
   return atr_floor_risk;
}

bool GRAI_NetRRAcceptable(const double risk_dist, const double tp_rr,
                          const double min_net_rr, const double spread_price)
{
   if(risk_dist <= 0.0 || tp_rr <= 0.0)
      return false;
   double reward = tp_rr * risk_dist;
   double net_reward = reward - spread_price;
   double net_risk = risk_dist + spread_price;
   if(net_risk <= 0.0)
      return false;
   return ((net_reward / net_risk) >= min_net_rr);
}

// Closed-bar impulse confirm (bar 1 fully closed).
bool GRAI_ClosedBarImpulse(const int cmd, const double avg_range, const double exp_bar)
{
   if(avg_range <= 0.0 || exp_bar <= 0.0)
      return false;
   double o = iOpen_MT4(_Symbol, 0, 1);
   double c = iClose_MT4(_Symbol, 0, 1);
   double body = MathAbs(c - o);
   if(body < exp_bar * avg_range)
      return false;
   if(cmd == OP_BUY)
      return (c > o);
   if(cmd == OP_SELL)
      return (c < o);
   return false;
}

// Structure trail candidate: beyond last confirmed HL/LH with buffer.
bool GRAI_StructureTrailSL(const int cmd, const double atr, const double buffer_atr,
                           double &trail_sl)
{
   double buf = (atr > 0.0 && buffer_atr > 0.0) ? (buffer_atr * atr) : 0.0;
   if(cmd == OP_BUY)
   {
      double sw = 0.0;
      if(!GRAI_LastConfirmedSwingLow(sw))
         return false;
      trail_sl = sw - buf;
      return true;
   }
   if(cmd == OP_SELL)
   {
      double sw = 0.0;
      if(!GRAI_LastConfirmedSwingHigh(sw))
         return false;
      trail_sl = sw + buf;
      return true;
   }
   return false;
}

bool GRAI_TightenOnlyOk(const int cmd, const double cur_sl, const double new_sl)
{
   if(cur_sl == 0.0)
      return true;
   if(cmd == OP_BUY)
      return (new_sl > cur_sl + _Point * 0.5);
   if(cmd == OP_SELL)
      return (new_sl < cur_sl - _Point * 0.5);
   return false;
}

#endif
