//+------------------------------------------------------------------+
//| Deterministic regime (v0.1 minimal)                               |
//+------------------------------------------------------------------+
#ifndef GRAI_REGIME_MQH
#define GRAI_REGIME_MQH

#include "Types.mqh"
#include "AuditLog.mqh"

// Uses chart-TF closed bars via MT4-compat iMA / range. Caller supplies spike/news.
int GRAI_DetectRegime(const bool news_blackout, const bool spike_bar,
                      const double ema_fast0, const double ema_fast1,
                      const double atr_now, const double atr_p50)
{
   if(news_blackout || spike_bar)
   {
      GRAI_Log("REGIME", "ABNORMAL");
      return GRAI_REG_ABNORMAL;
   }
   if(atr_now <= 0.0 || ema_fast0 <= 0.0)
   {
      GRAI_Log("REGIME", "UNKNOWN");
      return GRAI_REG_UNKNOWN;
   }
   if(atr_p50 > 0.0 && atr_now > 1.5 * atr_p50)
   {
      GRAI_Log("REGIME", "HIGH_VOL");
      return GRAI_REG_HIGH_VOL;
   }
   if(atr_p50 > 0.0 && atr_now < 0.6 * atr_p50)
   {
      // still allow trend label below if slope clear
   }
   if(ema_fast0 > ema_fast1)
   {
      GRAI_Log("REGIME", "TREND_UP");
      return GRAI_REG_TREND_UP;
   }
   if(ema_fast0 < ema_fast1)
   {
      GRAI_Log("REGIME", "TREND_DOWN");
      return GRAI_REG_TREND_DOWN;
   }
   GRAI_Log("REGIME", "RANGE");
   return GRAI_REG_RANGE;
}

bool GRAI_RegimeAllowsEntry(const int regime)
{
   return (regime != GRAI_REG_UNKNOWN && regime != GRAI_REG_ABNORMAL);
}

bool g_grai_entries_allowed = true; // set each tick by EA

#endif

