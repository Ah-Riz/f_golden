//+------------------------------------------------------------------+
//| GRAI MTF stack — H4 direction → H1 trend → M15 pullback → M5 entry |
//| H4→bias only when g_mtf_h4_writes_bias; M5 loose drops EMA band.    |
//| Unknown/invalid → WAIT (block). No profit claim.                   |
//+------------------------------------------------------------------+
#ifndef GRAI_MTF_STACK_MQH
#define GRAI_MTF_STACK_MQH

#include "Types.mqh"
#include "AuditLog.mqh"
#include "Bias.mqh"

bool g_mtf_use_stack = false;
bool g_mtf_use_h4    = false;
bool g_mtf_use_h1    = false;
bool g_mtf_use_m15   = false;
bool g_mtf_use_m5    = false;
// Default true so v0.3.2 (no Inp) keeps H4→bias overwrite; v0.3.3+ sets from input.
bool g_mtf_h4_writes_bias = true;
// Default false = strict M5 (EMA near-band); v0.3.4 may set loose via input.
bool g_mtf_m5_loose = false;

int  g_mtf_h4 = GRAI_BIAS_FLAT;
int  g_mtf_h1 = GRAI_BIAS_FLAT;
bool g_mtf_m15_long_ok  = false;
bool g_mtf_m15_short_ok = false;
bool g_mtf_m5_long_ok   = false;
bool g_mtf_m5_short_ok  = false;
bool g_mtf_data_ok      = true;

double GRAI_MtfEma(const ENUM_TIMEFRAMES tf, const int period, const int shift)
{
   return iMA_MT4(_Symbol, tf, period, 0, MODE_EMA, PRICE_CLOSE, shift);
}

// Simple ATR from True Range average (closed bars). shift = first bar of window.
double GRAI_MtfAtr(const ENUM_TIMEFRAMES tf, const int period, const int shift)
{
   if(period < 1)
      return 0.0;
   MqlRates r[];
   ArraySetAsSeries(r, true);
   const int need = period + 1;
   const int n = CopyRates(_Symbol, tf, shift, need, r);
   if(n < need)
      return 0.0;
   double sum = 0.0;
   for(int i = 0; i < period; i++)
   {
      const double tr1 = r[i].high - r[i].low;
      const double tr2 = MathAbs(r[i].high - r[i + 1].close);
      const double tr3 = MathAbs(r[i].low  - r[i + 1].close);
      sum += MathMax(tr1, MathMax(tr2, tr3));
   }
   return sum / (double)period;
}

bool GRAI_MtfNearBand(const double px, const double ema, const double atr)
{
   if(ema <= 0.0 || atr <= 0.0)
      return false;
   return (MathAbs(px - ema) <= 0.5 * atr);
}

int GRAI_MtfH4Direction()
{
   const double c   = iClose_MT4(_Symbol, PERIOD_H4, 1);
   const double e20 = GRAI_MtfEma(PERIOD_H4, 20, 1);
   const double e50 = GRAI_MtfEma(PERIOD_H4, 50, 1);
   const double e200 = GRAI_MtfEma(PERIOD_H4, 200, 1);
   if(c <= 0.0 || e20 <= 0.0 || e50 <= 0.0 || e200 <= 0.0)
   {
      g_mtf_data_ok = false;
      return GRAI_BIAS_FLAT;
   }
   if(c > e200 && e20 > e50)
      return GRAI_BIAS_LONG;
   if(c < e200 && e20 < e50)
      return GRAI_BIAS_SHORT;
   return GRAI_BIAS_FLAT;
}

int GRAI_MtfH1Trend()
{
   const double c   = iClose_MT4(_Symbol, PERIOD_H1, 1);
   const double e20 = GRAI_MtfEma(PERIOD_H1, 20, 1);
   const double e50 = GRAI_MtfEma(PERIOD_H1, 50, 1);
   if(c <= 0.0 || e20 <= 0.0 || e50 <= 0.0)
   {
      g_mtf_data_ok = false;
      return GRAI_BIAS_FLAT;
   }
   if(e20 > e50 && c > e20)
      return GRAI_BIAS_LONG;
   if(e20 < e50 && c < e20)
      return GRAI_BIAS_SHORT;
   return GRAI_BIAS_FLAT;
}

void GRAI_MtfEvalM15()
{
   g_mtf_m15_long_ok = false;
   g_mtf_m15_short_ok = false;
   const double lo  = iLow_MT4(_Symbol, PERIOD_M15, 1);
   const double hi  = iHigh_MT4(_Symbol, PERIOD_M15, 1);
   const double e20 = GRAI_MtfEma(PERIOD_M15, 20, 1);
   const double e50 = GRAI_MtfEma(PERIOD_M15, 50, 1);
   const double atr = GRAI_MtfAtr(PERIOD_M15, 14, 1);
   if(lo <= 0.0 || hi <= 0.0 || e20 <= 0.0 || e50 <= 0.0 || atr <= 0.0)
   {
      g_mtf_data_ok = false;
      return;
   }
   g_mtf_m15_long_ok  = (GRAI_MtfNearBand(lo, e20, atr) || GRAI_MtfNearBand(lo, e50, atr));
   g_mtf_m15_short_ok = (GRAI_MtfNearBand(hi, e20, atr) || GRAI_MtfNearBand(hi, e50, atr));
}

void GRAI_MtfEvalM5()
{
   g_mtf_m5_long_ok = false;
   g_mtf_m5_short_ok = false;
   const double o   = iOpen_MT4(_Symbol, PERIOD_M5, 1);
   const double h   = iHigh_MT4(_Symbol, PERIOD_M5, 1);
   const double l   = iLow_MT4(_Symbol, PERIOD_M5, 1);
   const double c   = iClose_MT4(_Symbol, PERIOD_M5, 1);
   if(o <= 0.0 || h <= 0.0 || l <= 0.0 || c <= 0.0)
   {
      g_mtf_data_ok = false;
      return;
   }
   const double mid = 0.5 * (h + l);
   if(g_mtf_m5_loose)
   {
      // Loose: directional candle + close vs mid only (no EMA band).
      if(c > o && c >= mid)
         g_mtf_m5_long_ok = true;
      if(c < o && c <= mid)
         g_mtf_m5_short_ok = true;
      return;
   }
   const double e20 = GRAI_MtfEma(PERIOD_M5, 20, 1);
   const double e50 = GRAI_MtfEma(PERIOD_M5, 50, 1);
   const double atr = GRAI_MtfAtr(PERIOD_M5, 14, 1);
   if(e20 <= 0.0 || e50 <= 0.0 || atr <= 0.0)
   {
      g_mtf_data_ok = false;
      return;
   }
   // Strict: bullish/bearish + close half + low/high in EMA band
   if(c > o && c >= mid && (GRAI_MtfNearBand(l, e20, atr) || GRAI_MtfNearBand(l, e50, atr)))
      g_mtf_m5_long_ok = true;
   if(c < o && c <= mid && (GRAI_MtfNearBand(h, e20, atr) || GRAI_MtfNearBand(h, e50, atr)))
      g_mtf_m5_short_ok = true;
}

// Recompute stack; overwrite g_grai_bias from H4 only when h4_writes_bias.
void GRAI_MtfUpdate()
{
   if(!g_mtf_use_stack)
      return;

   g_mtf_data_ok = true;
   g_mtf_h4 = GRAI_BIAS_FLAT;
   g_mtf_h1 = GRAI_BIAS_FLAT;
   g_mtf_m15_long_ok = g_mtf_m15_short_ok = false;
   g_mtf_m5_long_ok = g_mtf_m5_short_ok = false;

   if(g_mtf_use_h4)
      g_mtf_h4 = GRAI_MtfH4Direction();
   if(g_mtf_use_h1)
      g_mtf_h1 = GRAI_MtfH1Trend();
   if(g_mtf_use_m15)
      GRAI_MtfEvalM15();
   if(g_mtf_use_m5)
      GRAI_MtfEvalM5();

   if(g_mtf_use_h4 && g_mtf_h4_writes_bias)
   {
      const int prev = g_grai_bias;
      g_grai_bias = g_mtf_h4;
      if(prev != g_grai_bias)
         GRAI_Log("BIAS", StringFormat("%s mtf_h4=%s h1=%s",
            GRAI_BiasStr(g_grai_bias),
            GRAI_BiasStr(g_mtf_h4),
            GRAI_BiasStr(g_mtf_h1)));
   }
}

void GRAI_MtfSkipLog(const string reason, const int cmd)
{
   static datetime s_last = 0;
   static string   s_reason = "";
   if(TimeCurrent() - s_last < 30 && s_reason == reason)
      return;
   GRAI_Log("SKIP", StringFormat("%s cmd=%d h4=%s h1=%s",
      reason, cmd, GRAI_BiasStr(g_mtf_h4), GRAI_BiasStr(g_mtf_h1)));
   s_last = TimeCurrent();
   s_reason = reason;
}

bool GRAI_MtfAllowsCmd(const int cmd)
{
   if(!g_mtf_use_stack)
      return true;
   if(!g_mtf_data_ok)
   {
      GRAI_MtfSkipLog("mtf_data", cmd);
      return false;
   }

   if(g_mtf_use_h4)
   {
      if(g_mtf_h4 == GRAI_BIAS_FLAT)
      {
         GRAI_MtfSkipLog("mtf_h4", cmd);
         return false;
      }
      if(g_mtf_h4 == GRAI_BIAS_LONG && cmd != OP_BUY)
      {
         GRAI_MtfSkipLog("mtf_h4", cmd);
         return false;
      }
      if(g_mtf_h4 == GRAI_BIAS_SHORT && cmd != OP_SELL)
      {
         GRAI_MtfSkipLog("mtf_h4", cmd);
         return false;
      }
   }

   if(g_mtf_use_h1)
   {
      if(g_mtf_h1 == GRAI_BIAS_FLAT)
      {
         GRAI_MtfSkipLog("mtf_h1", cmd);
         return false;
      }
      if(g_mtf_use_h4 && g_mtf_h1 != g_mtf_h4)
      {
         GRAI_MtfSkipLog("mtf_h1", cmd);
         return false;
      }
      if(g_mtf_h1 == GRAI_BIAS_LONG && cmd != OP_BUY)
      {
         GRAI_MtfSkipLog("mtf_h1", cmd);
         return false;
      }
      if(g_mtf_h1 == GRAI_BIAS_SHORT && cmd != OP_SELL)
      {
         GRAI_MtfSkipLog("mtf_h1", cmd);
         return false;
      }
   }

   if(g_mtf_use_m15)
   {
      if(cmd == OP_BUY && !g_mtf_m15_long_ok)
      {
         GRAI_MtfSkipLog("mtf_m15", cmd);
         return false;
      }
      if(cmd == OP_SELL && !g_mtf_m15_short_ok)
      {
         GRAI_MtfSkipLog("mtf_m15", cmd);
         return false;
      }
   }

   if(g_mtf_use_m5)
   {
      if(cmd == OP_BUY && !g_mtf_m5_long_ok)
      {
         GRAI_MtfSkipLog("mtf_m5", cmd);
         return false;
      }
      if(cmd == OP_SELL && !g_mtf_m5_short_ok)
      {
         GRAI_MtfSkipLog("mtf_m5", cmd);
         return false;
      }
   }

   return true;
}

string GRAI_MtfOnOff(const bool v) { return (v ? "ON" : "OFF"); }

#endif
