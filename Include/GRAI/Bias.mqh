//+------------------------------------------------------------------+
//| GRAI Bias — SMC-Lana primary trend + optional D1/H4 MA confirm    |
//+------------------------------------------------------------------+
#ifndef GRAI_BIAS_MQH
#define GRAI_BIAS_MQH

#include "Types.mqh"
#include "AuditLog.mqh"
#include "SmcLana.mqh"

int  g_grai_bias = GRAI_BIAS_FLAT;
bool g_grai_use_smc = true;
bool g_grai_use_ma_bias = false; // optional AND; default OFF when SMC full

string GRAI_BiasStr(const int bias)
{
   if(bias == GRAI_BIAS_LONG)  return "LONG";
   if(bias == GRAI_BIAS_SHORT) return "SHORT";
   return "FLAT";
}

int GRAI_MaBiasOnly()
{
   double d1_sma   = iMA_MT4(_Symbol, PERIOD_D1, 200, 0, MODE_SMA, PRICE_CLOSE, 1);
   double d1_close = iClose_MT4(_Symbol, PERIOD_D1, 1);
   double h4_ema   = iMA_MT4(_Symbol, PERIOD_H4, 200, 0, MODE_EMA, PRICE_CLOSE, 1);
   double h4_close = iClose_MT4(_Symbol, PERIOD_H4, 1);
   if(d1_sma <= 0.0 || d1_close <= 0.0 || h4_ema <= 0.0 || h4_close <= 0.0)
      return GRAI_BIAS_FLAT;
   const bool d1_long  = (d1_close > d1_sma);
   const bool d1_short = (d1_close < d1_sma);
   const bool h4_long  = (h4_close > h4_ema);
   const bool h4_short = (h4_close < h4_ema);
   if(d1_long && h4_long)   return GRAI_BIAS_LONG;
   if(d1_short && h4_short) return GRAI_BIAS_SHORT;
   return GRAI_BIAS_FLAT;
}

// Closed-bar SMC (+ optional MA). Unknown → FLAT (WAIT).
int GRAI_BiasUpdate()
{
   int prev = g_grai_bias;
   int bias = GRAI_BIAS_FLAT;

   if(g_grai_use_smc)
   {
      GRAI_SmcUpdate();
      if(GRAI_SmcReady())
      {
         if(GRAI_SmcTrend() == 1)
            bias = GRAI_BIAS_LONG;
         else if(GRAI_SmcTrend() == -1)
            bias = GRAI_BIAS_SHORT;
         else
            bias = GRAI_BIAS_FLAT;
      }
      else
         bias = GRAI_BIAS_FLAT;
   }
   else
      bias = GRAI_MaBiasOnly();

   if(g_grai_use_ma_bias)
   {
      int ma = GRAI_MaBiasOnly();
      if(ma == GRAI_BIAS_FLAT || ma != bias)
         bias = GRAI_BIAS_FLAT;
   }

   g_grai_bias = bias;
   if(prev != g_grai_bias)
      GRAI_Log("BIAS", StringFormat("%s smc=%s ma=%s event=%s",
         GRAI_BiasStr(g_grai_bias),
         GRAI_SmcTrendStr(),
         GRAI_BiasStr(GRAI_MaBiasOnly()),
         g_grai_smc_snap.last_event));
   return g_grai_bias;
}

bool GRAI_BiasAllowsCmd(const int cmd)
{
   if(g_grai_use_smc)
   {
      if(!GRAI_SmcAllowsCmd(cmd))
         return false;
   }
   if(g_grai_bias == GRAI_BIAS_LONG)
      return (cmd == OP_BUY);
   if(g_grai_bias == GRAI_BIAS_SHORT)
      return (cmd == OP_SELL);
   return false;
}

bool GRAI_BiasAligned(const int direction, const int bias)
{
   if(bias == GRAI_BIAS_LONG)
      return (direction == OP_BUY);
   if(bias == GRAI_BIAS_SHORT)
      return (direction == OP_SELL);
   return false;
}

#endif
