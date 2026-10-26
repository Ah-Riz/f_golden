//+------------------------------------------------------------------+
//| SMC_Lana MTF highs/lows — completed HTF bars only (no lookahead)  |
//+------------------------------------------------------------------+
#ifndef SMC_LANA_MTF_MQH
#define SMC_LANA_MTF_MQH

#include "SmcTypes.mqh"
#include "SmcObjects.mqh"

bool SmcMtfPrevHL(const ENUM_TIMEFRAMES tf, double &ph, double &pl,
                  datetime &ph_t, datetime &pl_t)
{
   // shift 1 = last completed HTF bar
   MqlRates r[];
   ArraySetAsSeries(r, true);
   int n = CopyRates(_Symbol, tf, 1, 3, r);
   if(n < 1)
      return false;
   ph = r[0].high;
   pl = r[0].low;
   ph_t = r[0].time;
   pl_t = r[0].time;
   // find where high/low occurred within that bar using chart TF
   return true;
}

// Approximate quarterly: previous completed calendar quarter high/low from D1
bool SmcMtfQuarterHL(double &ph, double &pl, datetime &ph_t, datetime &pl_t)
{
   MqlRates r[];
   ArraySetAsSeries(r, true);
   int n = CopyRates(_Symbol, PERIOD_D1, 0, 200, r);
   if(n < 30)
      return false;
   MqlDateTime dt;
   TimeToStruct(r[0].time, dt);
   int cur_q = (dt.mon - 1) / 3;
   int cur_y = dt.year;
   // walk until leave previous quarter
   bool in_prev = false;
   ph = 0.0;
   pl = 1.0e100;
   ph_t = 0;
   pl_t = 0;
   for(int i = 1; i < n; i++)
   {
      TimeToStruct(r[i].time, dt);
      int q = (dt.mon - 1) / 3;
      int y = dt.year;
      bool prev = (y < cur_y) || (y == cur_y && q < cur_q);
      if(!prev)
         continue;
      if(!in_prev)
      {
         // first bar of previous quarter from the end
         int target_q = q;
         int target_y = y;
         in_prev = true;
         for(int j = i; j < n; j++)
         {
            TimeToStruct(r[j].time, dt);
            int qj = (dt.mon - 1) / 3;
            if(dt.year != target_y || qj != target_q)
               break;
            if(r[j].high >= ph) { ph = r[j].high; ph_t = r[j].time; }
            if(r[j].low  <= pl) { pl = r[j].low;  pl_t = r[j].time; }
         }
         break;
      }
   }
   return (ph > 0.0 && pl < 1.0e100);
}

bool SmcMtfYearHL(double &ph, double &pl, datetime &ph_t, datetime &pl_t)
{
   MqlRates r[];
   ArraySetAsSeries(r, true);
   int n = CopyRates(_Symbol, PERIOD_MN1, 0, 24, r);
   if(n < 2)
      return false;
   MqlDateTime dt;
   TimeToStruct(r[0].time, dt);
   int cur_y = dt.year;
   ph = 0.0;
   pl = 1.0e100;
   ph_t = 0;
   pl_t = 0;
   bool found = false;
   for(int i = 1; i < n; i++)
   {
      TimeToStruct(r[i].time, dt);
      if(dt.year != cur_y - 1)
      {
         if(found) break;
         continue;
      }
      found = true;
      if(r[i].high >= ph) { ph = r[i].high; ph_t = r[i].time; }
      if(r[i].low  <= pl) { pl = r[i].low;  pl_t = r[i].time; }
   }
   return found;
}

void SmcMtfDrawOne(const string tag, const bool enabled, const color css,
                   const double ph, const double pl,
                   const datetime ph_t, const datetime pl_t)
{
   if(!enabled)
      return;
   datetime ext = iTime(_Symbol, PERIOD_CURRENT, 0) + PeriodSeconds() * 20;
   string nh = SMC_IND_PREFIX + "MTF_" + tag + "H";
   string nl = SMC_IND_PREFIX + "MTF_" + tag + "L";
   string th = SMC_IND_PREFIX + "MTF_" + tag + "HT";
   string tl = SMC_IND_PREFIX + "MTF_" + tag + "LT";
   datetime hx = (ph_t > 0) ? ph_t : ext - PeriodSeconds() * 50;
   datetime lx = (pl_t > 0) ? pl_t : ext - PeriodSeconds() * 50;
   SmcObjTrend(nh, hx, ph, ext, ph, css, STYLE_DASH);
   SmcObjTrend(nl, lx, pl, ext, pl, css, STYLE_DASH);
   SmcObjText(th, ext, ph, "P" + tag + "H", css, 8, ANCHOR_LEFT);
   SmcObjText(tl, ext, pl, "P" + tag + "L", css, 8, ANCHOR_LEFT);
}

void SmcMtfDraw(const SmcIndConfig &cfg)
{
   SmcObjDeleteKind("MTF_");
   double ph, pl;
   datetime pht, plt;
   if(cfg.lvl_daily && SmcMtfPrevHL(PERIOD_D1, ph, pl, pht, plt))
      SmcMtfDrawOne("D", true, cfg.css_d, ph, pl, pht, plt);
   if(cfg.lvl_weekly && SmcMtfPrevHL(PERIOD_W1, ph, pl, pht, plt))
      SmcMtfDrawOne("W", true, cfg.css_w, ph, pl, pht, plt);
   if(cfg.lvl_monthly && SmcMtfPrevHL(PERIOD_MN1, ph, pl, pht, plt))
      SmcMtfDrawOne("M", true, cfg.css_m, ph, pl, pht, plt);
   if(cfg.lvl_quarterly && SmcMtfQuarterHL(ph, pl, pht, plt))
      SmcMtfDrawOne("Q", true, cfg.css_q, ph, pl, pht, plt);
   if(cfg.lvl_yearly && SmcMtfYearHL(ph, pl, pht, plt))
      SmcMtfDrawOne("Y", true, cfg.css_y, ph, pl, pht, plt);
}

#endif
