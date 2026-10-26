//+------------------------------------------------------------------+
//| SMC_Lana liquidity extras — premium/discount + strong/weak HL     |
//| Port of commented Pine upphl/dnphl/midphl/hqlzone.                 |
//+------------------------------------------------------------------+
#ifndef SMC_LANA_LIQ_MQH
#define SMC_LANA_LIQ_MQH

#include "SmcTypes.mqh"
#include "SmcObjects.mqh"

double   g_smc_hl_topy = 0.0;
double   g_smc_hl_btmy = 0.0;
datetime g_smc_hl_topt = 0;
datetime g_smc_hl_btmt = 0;
double   g_smc_hl_tup = 0.0;
double   g_smc_hl_tdn = 0.0;
datetime g_smc_hl_tupx = 0;
datetime g_smc_hl_tdnx = 0;
double   g_smc_hl_uV = 0.0;
double   g_smc_hl_dV = 0.0;
int      g_smc_hl_out = 0; // 0 high regime, 1 low regime

void SmcLiqHlReset()
{
   g_smc_hl_topy = g_smc_hl_btmy = 0.0;
   g_smc_hl_topt = g_smc_hl_btmt = 0;
   g_smc_hl_tup = g_smc_hl_tdn = 0.0;
   g_smc_hl_tupx = g_smc_hl_tdnx = 0;
   g_smc_hl_uV = g_smc_hl_dV = 0.0;
   g_smc_hl_out = 0;
}

void SmcLiqZhl(MqlRates &rates[], const int rates_n, const int len,
               double &top, double &btm, bool &has_top, bool &has_btm)
{
   has_top = false;
   has_btm = false;
   top = 0.0;
   btm = 0.0;
   if(rates_n <= len + 1)
      return;
   double upper = rates[len].high;
   double lower = rates[len].low;
   for(int i = 0; i <= len; i++)
   {
      if(rates[i].high > upper) upper = rates[i].high;
      if(rates[i].low  < lower) lower = rates[i].low;
   }
   // Pine: out := high[len] > upper ? 0 : low[len] < lower ? 1 : out[1]
   // Using rolling: if pivot-like break of channel
   static int s_out = 0;
   double hi_len = rates[len].high;
   double lo_len = rates[len].low;
   // recompute upper/lower excluding the len bar itself for break detection
   upper = rates[0].high;
   lower = rates[0].low;
   for(int i = 0; i < len; i++)
   {
      if(rates[i].high > upper) upper = rates[i].high;
      if(rates[i].low  < lower) lower = rates[i].low;
   }
   int prev = s_out;
   if(hi_len > upper) s_out = 0;
   else if(lo_len < lower) s_out = 1;
   g_smc_hl_out = s_out;
   if(s_out == 0 && prev != 0)
   {
      top = hi_len;
      has_top = true;
   }
   if(s_out == 1 && prev != 1)
   {
      btm = lo_len;
      has_btm = true;
   }
}

void SmcLiqHlStep(MqlRates &rates[], const int rates_n, const SmcIndConfig &cfg, const int trend)
{
   if(!cfg.show_hl && !cfg.show_pd_zone)
      return;
   if(rates_n < cfg.zone_len + 2)
      return;

   double top = 0.0, btm = 0.0;
   bool has_top = false, has_btm = false;
   SmcLiqZhl(rates, rates_n, cfg.zone_len, top, btm, has_top, has_btm);

   if(has_top)
   {
      g_smc_hl_topy = top;
      g_smc_hl_topt = rates[cfg.zone_len].time;
      g_smc_hl_tup = top;
      g_smc_hl_tupx = rates[cfg.zone_len].time;
      g_smc_hl_uV = (double)rates[cfg.zone_len].tick_volume;
   }
   if(has_btm)
   {
      g_smc_hl_btmy = btm;
      g_smc_hl_btmt = rates[cfg.zone_len].time;
      g_smc_hl_tdn = btm;
      g_smc_hl_tdnx = rates[cfg.zone_len].time;
      g_smc_hl_dV = (double)rates[cfg.zone_len].tick_volume;
   }

   if(rates[0].high > g_smc_hl_tup)
   {
      g_smc_hl_uV = (double)rates[0].tick_volume;
      g_smc_hl_tup = rates[0].high;
      g_smc_hl_tupx = rates[0].time;
   }
   else if(g_smc_hl_tup > 0.0)
      g_smc_hl_tup = MathMax(rates[0].high, g_smc_hl_tup);

   if(g_smc_hl_tdn <= 0.0)
      g_smc_hl_tdn = rates[0].low;
   if(rates[0].low < g_smc_hl_tdn)
   {
      g_smc_hl_dV = (double)rates[0].tick_volume;
      g_smc_hl_tdn = rates[0].low;
      g_smc_hl_tdnx = rates[0].time;
   }
   else
      g_smc_hl_tdn = MathMin(rates[0].low, g_smc_hl_tdn);
}

void SmcLiqHlDraw(const SmcIndConfig &cfg, const int trend)
{
   SmcObjDeleteKind("HL_");
   SmcObjDeleteKind("PD_");
   datetime ext = iTime(_Symbol, PERIOD_CURRENT, 0) + PeriodSeconds() * 20;

   if(cfg.show_hl && g_smc_hl_tup > 0.0)
   {
      datetime x1 = (g_smc_hl_tupx > 0) ? g_smc_hl_tupx : ext - PeriodSeconds() * 50;
      SmcObjTrend(SMC_IND_PREFIX + "HL_TOP", x1, g_smc_hl_tup, ext, g_smc_hl_tup,
                  cfg.swing_dn, STYLE_SOLID);
      double denom = g_smc_hl_uV + g_smc_hl_dV;
      double dist = (denom > 0.0) ? MathAbs(g_smc_hl_uV / denom) * 100.0 : 0.0;
      string txt = (trend < 0)
         ? StringFormat("Strong High | %.0f (%.0f%%)", g_smc_hl_uV, dist)
         : StringFormat("Weak High | %.0f (%.0f%%)", g_smc_hl_uV, dist);
      SmcObjText(SMC_IND_PREFIX + "HL_TOPL", ext, g_smc_hl_tup, txt, cfg.swing_dn, 8);
   }
   if(cfg.show_hl && g_smc_hl_tdn > 0.0)
   {
      datetime x1 = (g_smc_hl_tdnx > 0) ? g_smc_hl_tdnx : ext - PeriodSeconds() * 50;
      SmcObjTrend(SMC_IND_PREFIX + "HL_BTM", x1, g_smc_hl_tdn, ext, g_smc_hl_tdn,
                  cfg.swing_up, STYLE_SOLID);
      double denom = g_smc_hl_uV + g_smc_hl_dV;
      double dist = (denom > 0.0) ? MathAbs(g_smc_hl_dV / denom) * 100.0 : 0.0;
      string txt = (trend > 0)
         ? StringFormat("Strong Low | %.0f (%.0f%%)", g_smc_hl_dV, dist)
         : StringFormat("Weak Low | %.0f (%.0f%%)", g_smc_hl_dV, dist);
      SmcObjText(SMC_IND_PREFIX + "HL_BTML", ext, g_smc_hl_tdn, txt, cfg.swing_up, 8);
   }

   if(cfg.show_pd_zone && g_smc_hl_tup > 0.0 && g_smc_hl_tdn > 0.0)
   {
      double avg = 0.5 * (g_smc_hl_tup + g_smc_hl_tdn);
      datetime left = g_smc_hl_tupx;
      if(g_smc_hl_tdnx > left) left = g_smc_hl_tdnx;
      if(left == 0) left = ext - PeriodSeconds() * 50;

      SmcObjTrend(SMC_IND_PREFIX + "PD_MID", left, avg, ext, avg, cfg.fib_css, STYLE_SOLID);
      SmcObjText(SMC_IND_PREFIX + "PD_MIDL", ext, avg, "0.5", cfg.fib_css, 8);

      double prem_btm = 0.95 * g_smc_hl_tup + 0.05 * g_smc_hl_tdn;
      double disc_top = 0.95 * g_smc_hl_tdn + 0.05 * g_smc_hl_tup;
      SmcObjRect(SMC_IND_PREFIX + "PD_PREM", left, g_smc_hl_tup, ext, prem_btm,
                 cfg.swing_dn, cfg.swing_dn, true);
      SmcObjRect(SMC_IND_PREFIX + "PD_DISC", left, disc_top, ext, g_smc_hl_tdn,
                 cfg.swing_up, cfg.swing_up, true);
      SmcObjText(SMC_IND_PREFIX + "PD_PREML", left + (ext - left) / 2, g_smc_hl_tup,
                 "Premium", cfg.swing_dn, 8);
      SmcObjText(SMC_IND_PREFIX + "PD_DISCL", left + (ext - left) / 2, g_smc_hl_tdn,
                 "Discount", cfg.swing_up, 8);
   }
}

#endif
