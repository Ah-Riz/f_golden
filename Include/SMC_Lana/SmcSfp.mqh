//+------------------------------------------------------------------+
//| SMC_Lana SFP — swing failure pattern on chart TF                  |
//| Uses completed pivots (no HTF lookahead).                         |
//+------------------------------------------------------------------+
#ifndef SMC_LANA_SFP_MQH
#define SMC_LANA_SFP_MQH

#include "SmcTypes.mqh"
#include "SmcObjects.mqh"
#include "SmcAlert.mqh"

SmcSFP g_smc_sfps[SMC_IND_MAX_SFP];
int    g_smc_sfp_n = 0;

double g_smc_sfp_last_ph = 0.0;
double g_smc_sfp_last_pl = 0.0;
datetime g_smc_sfp_ph_t = 0;
datetime g_smc_sfp_pl_t = 0;

void SmcSfpReset()
{
   g_smc_sfp_n = 0;
   g_smc_sfp_last_ph = 0.0;
   g_smc_sfp_last_pl = 0.0;
   g_smc_sfp_ph_t = 0;
   g_smc_sfp_pl_t = 0;
}

void SmcSfpUnshift(const SmcSFP &s)
{
   for(int i = MathMin(g_smc_sfp_n, SMC_IND_MAX_SFP - 1); i > 0; i--)
      g_smc_sfps[i] = g_smc_sfps[i - 1];
   g_smc_sfps[0] = s;
   g_smc_sfps[0].used = true;
   if(g_smc_sfp_n < SMC_IND_MAX_SFP)
      g_smc_sfp_n++;
}

bool SmcSfpPivotHigh(MqlRates &rates[], const int n, const int len, double &px, datetime &t)
{
   int c = len;
   if(c + len >= n || c < len)
      return false;
   double v = rates[c].high;
   for(int i = 1; i <= len; i++)
   {
      if(rates[c + i].high >= v) return false;
      if(rates[c - i].high > v)  return false;
   }
   px = v;
   t = rates[c].time;
   return true;
}

bool SmcSfpPivotLow(MqlRates &rates[], const int n, const int len, double &px, datetime &t)
{
   int c = len;
   if(c + len >= n || c < len)
      return false;
   double v = rates[c].low;
   for(int i = 1; i <= len; i++)
   {
      if(rates[c + i].low <= v) return false;
      if(rates[c - i].low < v)  return false;
   }
   px = v;
   t = rates[c].time;
   return true;
}

void SmcSfpStep(MqlRates &rates[], const int rates_n, const SmcIndConfig &cfg)
{
   if(!cfg.sfp_show || rates_n < cfg.pivot_len * 2 + 3)
      return;

   double ph = 0.0, pl = 0.0;
   datetime pht = 0, plt = 0;
   if(SmcSfpPivotHigh(rates, rates_n, cfg.pivot_len, ph, pht))
   {
      g_smc_sfp_last_ph = ph;
      g_smc_sfp_ph_t = pht;
   }
   if(SmcSfpPivotLow(rates, rates_n, cfg.pivot_len, pl, plt))
   {
      g_smc_sfp_last_pl = pl;
      g_smc_sfp_pl_t = plt;
   }

   double hi = rates[0].high;
   double lo = rates[0].low;
   double cl = rates[0].close;

   // Bearish SFP: wick above prior swing high, close back below
   if(g_smc_sfp_last_ph > 0.0 && hi > g_smc_sfp_last_ph && cl < g_smc_sfp_last_ph &&
      hi > rates[1].high)
   {
      SmcSFP s;
      ZeroMemory(s);
      s.used = true;
      s.bull = false;
      s.y = g_smc_sfp_last_ph;
      s.loc = rates[0].time;
      s.ancor = hi;
      SmcSfpUnshift(s);
      SmcAlertFire(9, false, "SFP Created");
      g_smc_sfp_last_ph = 0.0; // consume
   }
   // Bullish SFP: wick below prior swing low, close back above
   if(g_smc_sfp_last_pl > 0.0 && lo < g_smc_sfp_last_pl && cl > g_smc_sfp_last_pl &&
      lo < rates[1].low)
   {
      SmcSFP s;
      ZeroMemory(s);
      s.used = true;
      s.bull = true;
      s.y = g_smc_sfp_last_pl;
      s.loc = rates[0].time;
      s.ancor = lo;
      SmcSfpUnshift(s);
      SmcAlertFire(9, true, "SFP Created");
      g_smc_sfp_last_pl = 0.0;
   }
}

void SmcSfpDraw(const SmcIndConfig &cfg)
{
   SmcObjDeleteKind("SFP_");
   if(!cfg.sfp_show)
      return;
   datetime t_ext = iTime(_Symbol, PERIOD_CURRENT, 0) + PeriodSeconds() * 15;
   int show = MathMin(g_smc_sfp_n, 10);
   for(int i = 0; i < show; i++)
   {
      if(!g_smc_sfps[i].used) continue;
      color css = cfg.sfp_css;
      if(cfg.sfp_show_level)
      {
         string n = StringFormat("%sSFP_L_%d", SMC_IND_PREFIX, i);
         SmcObjTrend(n, g_smc_sfps[i].loc, g_smc_sfps[i].y,
                     t_ext, g_smc_sfps[i].y, css, STYLE_DASH);
      }
      if(cfg.sfp_fill)
      {
         string f = StringFormat("%sSFP_F_%d", SMC_IND_PREFIX, i);
         double top = MathMax(g_smc_sfps[i].y, g_smc_sfps[i].ancor);
         double btm = MathMin(g_smc_sfps[i].y, g_smc_sfps[i].ancor);
         SmcObjRect(f, g_smc_sfps[i].loc, top, t_ext, btm, css, css, true);
      }
      string lbl = StringFormat("%sSFP_T_%d", SMC_IND_PREFIX, i);
      SmcObjText(lbl, g_smc_sfps[i].loc, g_smc_sfps[i].y,
                 g_smc_sfps[i].bull ? "SFP▲" : "SFP▼", css, 8);
   }
}

#endif
