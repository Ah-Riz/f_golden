//+------------------------------------------------------------------+
//| SMC_Lana FVG — 3-candle fair value gaps + overlap/mitigate        |
//+------------------------------------------------------------------+
#ifndef SMC_LANA_FVG_MQH
#define SMC_LANA_FVG_MQH

#include "SmcTypes.mqh"
#include "SmcObjects.mqh"
#include "SmcAlert.mqh"

SmcFVG g_smc_blfvg[SMC_IND_MAX_FVG];
SmcFVG g_smc_brfvg[SMC_IND_MAX_FVG];
int    g_smc_blfvg_n = 0;
int    g_smc_brfvg_n = 0;

void SmcFvgReset()
{
   g_smc_blfvg_n = 0;
   g_smc_brfvg_n = 0;
}

void SmcFvgUnshift(SmcFVG &arr[], int &n, const SmcFVG &f, const int keep)
{
   for(int i = MathMin(n, SMC_IND_MAX_FVG - 1); i > 0; i--)
      arr[i] = arr[i - 1];
   arr[0] = f;
   arr[0].used = true;
   if(n < SMC_IND_MAX_FVG)
      n++;
   if(keep >= 0 && n > keep)
      n = keep;
}

bool SmcFvgOverlapHit(const SmcFVG &a, const SmcFVG &b)
{
   return (a.btm > b.btm && a.btm < b.top) ||
          (a.top < b.top && a.btm > b.btm) ||
          (a.top > b.top && a.btm < b.btm) ||
          (a.top < b.top && a.top > b.btm);
}

void SmcFvgOverlap()
{
   if(g_smc_blfvg_n > 1)
   {
      for(int i = g_smc_blfvg_n - 1; i >= 1; i--)
      {
         if(SmcFvgOverlapHit(g_smc_blfvg[i], g_smc_blfvg[0]))
         {
            for(int j = i; j < g_smc_blfvg_n - 1; j++)
               g_smc_blfvg[j] = g_smc_blfvg[j + 1];
            g_smc_blfvg_n--;
         }
      }
   }
   if(g_smc_brfvg_n > 1)
   {
      for(int i = g_smc_brfvg_n - 1; i >= 1; i--)
      {
         if(SmcFvgOverlapHit(g_smc_brfvg[i], g_smc_brfvg[0]))
         {
            for(int j = i; j < g_smc_brfvg_n - 1; j++)
               g_smc_brfvg[j] = g_smc_brfvg[j + 1];
            g_smc_brfvg_n--;
         }
      }
   }
}

// rates series: [0]=current closed being processed, [1]=prev, [2]=older
void SmcFvgStep(MqlRates &rates[], const int rates_n, const SmcIndConfig &cfg)
{
   if(!cfg.show_fvg || rates_n < 3)
      return;

   // Bullish FVG: low[0] > high[2]  (gap up between candle 2 and 0)
   if(rates[0].low > rates[2].high)
   {
      SmcFVG f;
      ZeroMemory(f);
      f.used = true;
      f.bull = true;
      f.top = rates[0].low;
      f.btm = rates[2].high;
      f.loc_time = rates[1].time;
      SmcFvgUnshift(g_smc_blfvg, g_smc_blfvg_n, f, cfg.fvg_keep);
   }
   // Bearish FVG: high[0] < low[2]
   if(rates[0].high < rates[2].low)
   {
      SmcFVG f;
      ZeroMemory(f);
      f.used = true;
      f.bull = false;
      f.top = rates[2].low;
      f.btm = rates[0].high;
      f.loc_time = rates[1].time;
      SmcFvgUnshift(g_smc_brfvg, g_smc_brfvg_n, f, cfg.fvg_keep);
   }

   double hi = rates[0].high;
   double lo = rates[0].low;
   double cl = rates[0].close;
   double op = rates[0].open;

   for(int i = 0; i < g_smc_blfvg_n; i++)
   {
      if(!g_smc_blfvg[i].used) continue;
      if(lo < g_smc_blfvg[i].top && hi > g_smc_blfvg[i].btm)
         SmcAlertFire(8, true, "Price Inside FVG");
      if(!g_smc_blfvg[i].isbb && lo < g_smc_blfvg[i].btm)
      {
         g_smc_blfvg[i].isbb = true;
         g_smc_blfvg[i].bb_time = rates[0].time;
         SmcAlertFire(6, true, "FVG Mitigated");
      }
      // raid: wick through then close back
      if(!g_smc_blfvg[i].israid && lo < g_smc_blfvg[i].btm && cl > g_smc_blfvg[i].btm)
      {
         g_smc_blfvg[i].israid = true;
         g_smc_blfvg[i].raid_y = lo;
         g_smc_blfvg[i].raid_time = rates[0].time;
         SmcAlertFire(7, true, "Raid Found");
      }
      if(g_smc_blfvg[i].isbb && MathMax(cl, op) > g_smc_blfvg[i].top)
      {
         for(int j = i; j < g_smc_blfvg_n - 1; j++)
            g_smc_blfvg[j] = g_smc_blfvg[j + 1];
         g_smc_blfvg_n--;
         i--;
      }
   }
   for(int i = 0; i < g_smc_brfvg_n; i++)
   {
      if(!g_smc_brfvg[i].used) continue;
      if(hi > g_smc_brfvg[i].btm && lo < g_smc_brfvg[i].top)
         SmcAlertFire(8, false, "Price Inside FVG");
      if(!g_smc_brfvg[i].isbb && hi > g_smc_brfvg[i].top)
      {
         g_smc_brfvg[i].isbb = true;
         g_smc_brfvg[i].bb_time = rates[0].time;
         SmcAlertFire(6, false, "FVG Mitigated");
      }
      if(!g_smc_brfvg[i].israid && hi > g_smc_brfvg[i].top && cl < g_smc_brfvg[i].top)
      {
         g_smc_brfvg[i].israid = true;
         g_smc_brfvg[i].raid_y = hi;
         g_smc_brfvg[i].raid_time = rates[0].time;
         SmcAlertFire(7, false, "Raid Found");
      }
      if(g_smc_brfvg[i].isbb && MathMin(cl, op) < g_smc_brfvg[i].btm)
      {
         for(int j = i; j < g_smc_brfvg_n - 1; j++)
            g_smc_brfvg[j] = g_smc_brfvg[j + 1];
         g_smc_brfvg_n--;
         i--;
      }
   }
   SmcFvgOverlap();
}

void SmcFvgDraw(const SmcIndConfig &cfg)
{
   SmcObjDeleteKind("FVG_");
   if(!cfg.show_fvg)
      return;
   datetime t_ext = iTime(_Symbol, PERIOD_CURRENT, 0) + PeriodSeconds() * 20;
   for(int i = 0; i < g_smc_blfvg_n; i++)
   {
      if(!g_smc_blfvg[i].used) continue;
      datetime t2 = g_smc_blfvg[i].isbb && g_smc_blfvg[i].bb_time > 0
                    ? g_smc_blfvg[i].bb_time : t_ext;
      string n = StringFormat("%sFVG_BU_%d", SMC_IND_PREFIX, i);
      SmcObjRect(n, g_smc_blfvg[i].loc_time, g_smc_blfvg[i].top,
                 t2, g_smc_blfvg[i].btm, cfg.fvg_up, cfg.fvg_up, true);
      if(g_smc_blfvg[i].israid)
      {
         string r = StringFormat("%sFVG_BUR_%d", SMC_IND_PREFIX, i);
         SmcObjArrow(r, g_smc_blfvg[i].raid_time, g_smc_blfvg[i].raid_y, cfg.fvg_up, 233);
      }
   }
   for(int i = 0; i < g_smc_brfvg_n; i++)
   {
      if(!g_smc_brfvg[i].used) continue;
      datetime t2 = g_smc_brfvg[i].isbb && g_smc_brfvg[i].bb_time > 0
                    ? g_smc_brfvg[i].bb_time : t_ext;
      string n = StringFormat("%sFVG_BE_%d", SMC_IND_PREFIX, i);
      SmcObjRect(n, g_smc_brfvg[i].loc_time, g_smc_brfvg[i].top,
                 t2, g_smc_brfvg[i].btm, cfg.fvg_dn, cfg.fvg_dn, true);
      if(g_smc_brfvg[i].israid)
      {
         string r = StringFormat("%sFVG_BER_%d", SMC_IND_PREFIX, i);
         SmcObjArrow(r, g_smc_brfvg[i].raid_time, g_smc_brfvg[i].raid_y, cfg.fvg_dn, 234);
      }
   }
}

#endif
