//+------------------------------------------------------------------+
//| SMC_Lana_OB engine — OB birth from structure + Touch mitigation   |
//| Draws OB rectangles only (SNR). No BOS/CHoCH/FVG/SFP drawings.    |
//+------------------------------------------------------------------+
#ifndef SMC_LANA_OB_ENGINE_MQH
#define SMC_LANA_OB_ENGINE_MQH

#include "SmcObObjects.mqh"

#define SMC_OB_MAX     32
#define SMC_OB_MAX_PV  64
#define SMC_OB_ATR_LEN 200

enum ENUM_SMC_OB_MITI
{
   SMC_OB_MITI_TOUCH = 0, // wick or body enters zone → remove
   SMC_OB_MITI_CLOSE = 1,
   SMC_OB_MITI_WICK  = 2,
   SMC_OB_MITI_AVG   = 3
};

struct SmcObCfg
{
   int             pivot_len;
   bool            adjusted_points;
   bool            build_sweep;
   bool            ob_length_mode;
   int             ob_len;
   int             ob_miti;
   int             ob_keep;
   bool            hide_overlap;
   bool            show_midline;
   color           ob_up;
   color           ob_dn;
   int             lookback;
   ENUM_TIMEFRAMES timeframe; // PERIOD_CURRENT = chart; H1 = HTF OB birth
};

struct SmcObZone
{
   bool     used;
   bool     bull;
   double   top;
   double   btm;
   double   avg;
   datetime loc_time;
};

struct SmcObMS
{
   double bos;
   double choch;
   int    loc;
   int    temp;
   int    trend;
   int    start;
   double main_px;
   int    xloc;
   bool   bos_valid;
   bool   choch_valid;
};

SmcObCfg  g_ob_cfg;
SmcObMS   g_ob_ms;
SmcObZone g_ob_blob[SMC_OB_MAX];
SmcObZone g_ob_brob[SMC_OB_MAX];
int       g_ob_blob_n = 0;
int       g_ob_brob_n = 0;

double g_ob_php[SMC_OB_MAX_PV];
int    g_ob_phn[SMC_OB_MAX_PV];
int    g_ob_php_n = 0;
double g_ob_plp[SMC_OB_MAX_PV];
int    g_ob_pln[SMC_OB_MAX_PV];
int    g_ob_plp_n = 0;

double g_ob_up = 0.0, g_ob_dn = 0.0;
bool   g_ob_up_set = false, g_ob_dn_set = false;

MqlRates g_ob_rates[];
int      g_ob_rates_n = 0;
int      g_ob_bar_abs = 0;
bool     g_ob_warmed = false;
datetime g_ob_last_bar = 0;
bool     g_ob_draw_enabled = true; // indicator ON; EA sets false unless InpSmcDraw

void SmcObCfgDefaults(SmcObCfg &c)
{
   ZeroMemory(c);
   c.pivot_len       = 5;
   c.adjusted_points = true;
   c.build_sweep     = true;
   c.ob_length_mode  = true;
   c.ob_len          = 5;
   c.ob_miti         = SMC_OB_MITI_TOUCH;
   c.ob_keep         = 3;
   c.hide_overlap    = true;
   c.show_midline    = false;
   c.ob_up           = C'8,153,129';
   c.ob_dn           = C'242,54,69';
   c.lookback        = 1500;
   c.timeframe       = PERIOD_CURRENT;
}

ENUM_TIMEFRAMES SmcObTf()
{
   return g_ob_cfg.timeframe;
}

void SmcObReset()
{
   ZeroMemory(g_ob_ms);
   g_ob_blob_n = g_ob_brob_n = 0;
   g_ob_php_n = g_ob_plp_n = 0;
   g_ob_up_set = g_ob_dn_set = false;
   g_ob_warmed = false;
   g_ob_bar_abs = 0;
}

double SmcObATR(const int shift, const int period)
{
   if(g_ob_rates_n <= shift + period)
      return 0.0;
   double sum = 0.0;
   for(int i = shift; i < shift + period; i++)
   {
      double tr = g_ob_rates[i].high - g_ob_rates[i].low;
      if(i + 1 < g_ob_rates_n)
      {
         double a = MathAbs(g_ob_rates[i].high - g_ob_rates[i + 1].close);
         double b = MathAbs(g_ob_rates[i].low  - g_ob_rates[i + 1].close);
         tr = MathMax(tr, MathMax(a, b));
      }
      sum += tr;
   }
   return sum / (double)period;
}

bool SmcObPivotHigh(const int left, const int right, const int center, double &out_px)
{
   if(center - right < 0 || center + left >= g_ob_rates_n)
      return false;
   double c = g_ob_rates[center].high;
   for(int i = 1; i <= left; i++)
      if(g_ob_rates[center + i].high >= c) return false;
   for(int i = 1; i <= right; i++)
      if(g_ob_rates[center - i].high > c) return false;
   out_px = c;
   return true;
}

bool SmcObPivotLow(const int left, const int right, const int center, double &out_px)
{
   if(center - right < 0 || center + left >= g_ob_rates_n)
      return false;
   double c = g_ob_rates[center].low;
   for(int i = 1; i <= left; i++)
      if(g_ob_rates[center + i].low <= c) return false;
   for(int i = 1; i <= right; i++)
      if(g_ob_rates[center - i].low < c) return false;
   out_px = c;
   return true;
}

void SmcObPhpPush(const double px, const int abs_bar)
{
   for(int i = MathMin(g_ob_php_n, SMC_OB_MAX_PV - 1); i > 0; i--)
   { g_ob_php[i] = g_ob_php[i - 1]; g_ob_phn[i] = g_ob_phn[i - 1]; }
   g_ob_php[0] = px; g_ob_phn[0] = abs_bar;
   if(g_ob_php_n < SMC_OB_MAX_PV) g_ob_php_n++;
}

void SmcObPlpPush(const double px, const int abs_bar)
{
   for(int i = MathMin(g_ob_plp_n, SMC_OB_MAX_PV - 1); i > 0; i--)
   { g_ob_plp[i] = g_ob_plp[i - 1]; g_ob_pln[i] = g_ob_pln[i - 1]; }
   g_ob_plp[0] = px; g_ob_pln[0] = abs_bar;
   if(g_ob_plp_n < SMC_OB_MAX_PV) g_ob_plp_n++;
}

int SmcObFind(const bool use_max, const bool useob, const int cur_abs)
{
   int span = cur_abs - g_ob_ms.loc;
   if(span < 0) span = 0;
   double minv = 1.0e100, maxv = 0.0;
   int idx = 0;
   int lim = (span - 1 > 0) ? span - 1 : span;
   for(int i = 0; i <= lim && i < g_ob_rates_n; i++)
   {
      if(use_max)
      {
         if(g_ob_rates[i].high >= maxv)
         { maxv = g_ob_rates[i].high; idx = i; }
      }
      else
      {
         if(g_ob_rates[i].low <= minv)
         { minv = g_ob_rates[i].low; idx = i; }
      }
   }
   if(useob)
   {
      if(use_max && idx + 1 < g_ob_rates_n &&
         g_ob_rates[idx + 1].high > g_ob_rates[idx].high)
         idx++;
      if(!use_max && idx + 1 < g_ob_rates_n &&
         g_ob_rates[idx + 1].low < g_ob_rates[idx].low)
         idx++;
   }
   return idx;
}

void SmcObTrim(int &n)
{
   int keep = MathMax(0, g_ob_cfg.ob_keep);
   if(n > keep) n = keep;
}

void SmcObPush(SmcObZone &arr[], int &n, const SmcObZone &z)
{
   for(int i = MathMin(n, SMC_OB_MAX - 1); i > 0; i--)
      arr[i] = arr[i - 1];
   arr[0] = z;
   arr[0].used = true;
   if(n < SMC_OB_MAX) n++;
   SmcObTrim(n);
}

void SmcObFn(const bool bull, const double cords, const int idx)
{
   if(idx < 0 || idx >= g_ob_rates_n) return;
   SmcObZone z;
   ZeroMemory(z);
   z.used = true;
   z.bull = bull;
   z.loc_time = g_ob_rates[idx].time;
   if(bull)
   {
      z.top = cords;
      z.btm = g_ob_rates[idx].low;
      z.avg = 0.5 * (cords + z.btm);
      SmcObPush(g_ob_blob, g_ob_blob_n, z);
   }
   else
   {
      z.top = g_ob_rates[idx].high;
      z.btm = cords;
      z.avg = 0.5 * (cords + z.top);
      SmcObPush(g_ob_brob, g_ob_brob_n, z);
   }
}

bool SmcObZoneOverlap(const SmcObZone &a, const SmcObZone &b)
{
   return (a.btm > b.btm && a.btm < b.top) ||
          (a.top < b.top && a.btm > b.btm) ||
          (a.top > b.top && a.btm < b.btm) ||
          (a.top < b.top && a.top > b.btm);
}

void SmcObOverlap()
{
   if(!g_ob_cfg.hide_overlap) return;
   if(g_ob_blob_n > 1)
   {
      for(int i = g_ob_blob_n - 1; i >= 1; i--)
      {
         if(SmcObZoneOverlap(g_ob_blob[i], g_ob_blob[0]))
         {
            for(int j = i; j < g_ob_blob_n - 1; j++)
               g_ob_blob[j] = g_ob_blob[j + 1];
            g_ob_blob_n--;
         }
      }
   }
   if(g_ob_brob_n > 1)
   {
      for(int i = g_ob_brob_n - 1; i >= 1; i--)
      {
         if(SmcObZoneOverlap(g_ob_brob[i], g_ob_brob[0]))
         {
            for(int j = i; j < g_ob_brob_n - 1; j++)
               g_ob_brob[j] = g_ob_brob[j + 1];
            g_ob_brob_n--;
         }
      }
   }
}

bool SmcObHitBull(const SmcObZone &z, const double o, const double c,
                  const double h, const double l)
{
   if(g_ob_cfg.ob_miti == SMC_OB_MITI_TOUCH)
      return (l < z.top && h > z.btm); // any touch into zone
   if(g_ob_cfg.ob_miti == SMC_OB_MITI_WICK)
      return (l < z.btm);
   if(g_ob_cfg.ob_miti == SMC_OB_MITI_AVG)
      return (l < z.avg);
   return (MathMin(c, o) < z.btm);
}

bool SmcObHitBear(const SmcObZone &z, const double o, const double c,
                  const double h, const double l)
{
   if(g_ob_cfg.ob_miti == SMC_OB_MITI_TOUCH)
      return (h > z.btm && l < z.top);
   if(g_ob_cfg.ob_miti == SMC_OB_MITI_WICK)
      return (h > z.top);
   if(g_ob_cfg.ob_miti == SMC_OB_MITI_AVG)
      return (h > z.avg);
   return (MathMax(c, o) > z.top);
}

void SmcObMitigate()
{
   double o = g_ob_rates[0].open;
   double c = g_ob_rates[0].close;
   double h = g_ob_rates[0].high;
   double l = g_ob_rates[0].low;
   datetime t = g_ob_rates[0].time;
   for(int i = 0; i < g_ob_blob_n; i++)
   {
      if(!g_ob_blob[i].used) continue;
      if(g_ob_blob[i].loc_time == t) continue; // birth bar: no same-bar kill
      if(SmcObHitBull(g_ob_blob[i], o, c, h, l))
      {
         for(int j = i; j < g_ob_blob_n - 1; j++)
            g_ob_blob[j] = g_ob_blob[j + 1];
         g_ob_blob_n--;
         i--;
      }
   }
   for(int i = 0; i < g_ob_brob_n; i++)
   {
      if(!g_ob_brob[i].used) continue;
      if(g_ob_brob[i].loc_time == t) continue;
      if(SmcObHitBear(g_ob_brob[i], o, c, h, l))
      {
         for(int j = i; j < g_ob_brob_n - 1; j++)
            g_ob_brob[j] = g_ob_brob[j + 1];
         g_ob_brob_n--;
         i--;
      }
   }
}

void SmcObStructureStep(const int cur_abs)
{
   const int mslen = g_ob_cfg.pivot_len;
   double hi = g_ob_rates[0].high;
   double lo = g_ob_rates[0].low;
   double cl = g_ob_rates[0].close;
   double op = g_ob_rates[0].open;
   double cl1 = (g_ob_rates_n > 1) ? g_ob_rates[1].close : cl;
   double op1 = (g_ob_rates_n > 1) ? g_ob_rates[1].open : op;

   double atr = SmcObATR(0, SMC_OB_ATR_LEN);
   if(atr <= 0.0) atr = hi - lo;
   double atr_ob = atr;
   if(g_ob_cfg.ob_len > 0)
      atr_ob = atr / (5.0 / (double)g_ob_cfg.ob_len);

   int idbull = SmcObFind(false, true, cur_abs);
   int idbear = SmcObFind(true, true, cur_abs);
   double btmP, topP;
   if(g_ob_cfg.ob_length_mode && idbear < g_ob_rates_n)
   {
      double atr_b = SmcObATR(idbear, SMC_OB_ATR_LEN);
      if(atr_b <= 0.0) atr_b = atr_ob;
      else if(g_ob_cfg.ob_len > 0) atr_b = atr_b / (5.0 / (double)g_ob_cfg.ob_len);
      btmP = (g_ob_rates[idbear].high - atr_b) < g_ob_rates[idbear].low
             ? g_ob_rates[idbear].low : (g_ob_rates[idbear].high - atr_b);
   }
   else
      btmP = (idbear < g_ob_rates_n) ? g_ob_rates[idbear].low : lo;

   if(g_ob_cfg.ob_length_mode && idbull < g_ob_rates_n)
   {
      double atr_u = SmcObATR(idbull, SMC_OB_ATR_LEN);
      if(atr_u <= 0.0) atr_u = atr_ob;
      else if(g_ob_cfg.ob_len > 0) atr_u = atr_u / (5.0 / (double)g_ob_cfg.ob_len);
      topP = (g_ob_rates[idbull].low + atr_u) > g_ob_rates[idbull].high
             ? g_ob_rates[idbull].high : (g_ob_rates[idbull].low + atr_u);
   }
   else
      topP = (idbull < g_ob_rates_n) ? g_ob_rates[idbull].high : hi;

   double ph = 0.0, pl = 0.0;
   if(SmcObPivotHigh(mslen, mslen, mslen, ph))
      SmcObPhpPush(ph, cur_abs - mslen);
   if(SmcObPivotLow(mslen, mslen, mslen, pl))
      SmcObPlpPush(pl, cur_abs - mslen);
   if(g_ob_php_n > 0 && hi > g_ob_php[0]) g_ob_php_n = 0;
   if(g_ob_plp_n > 0 && lo < g_ob_plp[0]) g_ob_plp_n = 0;

   bool crossup = false, crossdn = false;
   if(!g_ob_up_set) { g_ob_up = hi; g_ob_up_set = true; }
   if(!g_ob_dn_set) { g_ob_dn = lo; g_ob_dn_set = true; }
   if(hi > g_ob_up) { g_ob_up = hi; g_ob_dn = lo; crossup = true; }
   if(lo < g_ob_dn) { g_ob_up = hi; g_ob_dn = lo; crossdn = true; }

   if(g_ob_ms.start == 0)
   {
      g_ob_ms.start = 1;
      g_ob_ms.bos = hi;
      g_ob_ms.choch = lo;
      g_ob_ms.bos_valid = true;
      g_ob_ms.choch_valid = true;
      g_ob_ms.loc = g_ob_ms.temp = g_ob_ms.xloc = cur_abs;
      g_ob_ms.trend = 0;
      g_ob_ms.main_px = hi;
      return;
   }

   if(g_ob_ms.start == 1)
   {
      if(g_ob_cfg.build_sweep && g_ob_ms.choch_valid &&
         lo <= g_ob_ms.choch && cl >= g_ob_ms.choch)
      {
         g_ob_ms.choch = lo;
         g_ob_ms.xloc = cur_abs;
      }
      else if(g_ob_cfg.build_sweep && g_ob_ms.bos_valid &&
              hi >= g_ob_ms.bos && cl <= g_ob_ms.bos)
      {
         g_ob_ms.bos = hi;
         g_ob_ms.xloc = cur_abs;
      }
      else if(g_ob_ms.choch_valid && cl <= g_ob_ms.choch)
      {
         SmcObFn(true, topP, idbull);
         g_ob_ms.trend = -1;
         g_ob_ms.choch = g_ob_ms.bos;
         g_ob_ms.choch_valid = true;
         g_ob_ms.bos_valid = false;
         g_ob_ms.start = 2;
         g_ob_ms.loc = g_ob_ms.temp = g_ob_ms.xloc = cur_abs;
         g_ob_ms.main_px = lo;
      }
      else if(g_ob_ms.bos_valid && cl >= g_ob_ms.bos)
      {
         SmcObFn(false, btmP, idbear);
         g_ob_ms.trend = 1;
         g_ob_ms.bos_valid = false;
         g_ob_ms.start = 2;
         g_ob_ms.loc = g_ob_ms.temp = g_ob_ms.xloc = cur_abs;
         g_ob_ms.main_px = hi;
      }
      SmcObMitigate();
      SmcObOverlap();
      return;
   }

   if(g_ob_ms.trend == -1)
   {
      if(lo <= g_ob_ms.main_px)
      { g_ob_ms.main_px = lo; g_ob_ms.temp = cur_abs; }
      if(g_ob_cfg.adjusted_points && (cur_abs % (mslen * 2) == 0) &&
         g_ob_ms.bos_valid && g_ob_php_n > 0 && g_ob_php[0] < g_ob_ms.choch)
      {
         g_ob_ms.choch = g_ob_php[0];
         g_ob_ms.loc = g_ob_ms.xloc = g_ob_ms.temp = g_ob_phn[0];
      }
      if(!g_ob_ms.bos_valid && crossup && cl > op && cl1 > op1)
      {
         g_ob_ms.bos = g_ob_ms.main_px;
         g_ob_ms.bos_valid = true;
         g_ob_ms.loc = g_ob_ms.xloc = g_ob_ms.temp;
      }
      if(g_ob_cfg.build_sweep && g_ob_ms.bos_valid &&
         lo <= g_ob_ms.bos && cl >= g_ob_ms.bos)
      {
         g_ob_ms.bos = lo;
         g_ob_ms.xloc = cur_abs;
      }
      else if(g_ob_ms.bos_valid && cl <= g_ob_ms.bos)
      {
         SmcObFn(false, btmP, idbear);
         int id = SmcObFind(true, false, cur_abs);
         g_ob_ms.bos_valid = false;
         g_ob_ms.choch = g_ob_rates[id].high;
         g_ob_ms.choch_valid = true;
         g_ob_ms.loc = cur_abs - id;
         g_ob_ms.xloc = cur_abs;
      }
      else if(g_ob_cfg.build_sweep && g_ob_ms.choch_valid &&
              hi >= g_ob_ms.choch && cl <= g_ob_ms.choch)
      {
         g_ob_ms.choch = hi;
         g_ob_ms.xloc = cur_abs;
      }
      else if(g_ob_ms.choch_valid && cl >= g_ob_ms.choch)
      {
         SmcObFn(true, topP, idbull);
         int id = SmcObFind(false, false, cur_abs);
         g_ob_ms.choch = g_ob_ms.bos_valid ? g_ob_ms.bos : g_ob_rates[id].low;
         g_ob_ms.choch_valid = true;
         g_ob_ms.bos_valid = false;
         g_ob_ms.main_px = hi;
         g_ob_ms.trend = 1;
         g_ob_ms.loc = g_ob_ms.xloc = g_ob_ms.temp = cur_abs;
      }
   }
   else if(g_ob_ms.trend == 1)
   {
      if(hi >= g_ob_ms.main_px)
      { g_ob_ms.main_px = hi; g_ob_ms.temp = cur_abs; }
      if(!g_ob_ms.bos_valid && crossdn && cl < op && cl1 < op1)
      {
         g_ob_ms.bos = g_ob_ms.main_px;
         g_ob_ms.bos_valid = true;
         g_ob_ms.loc = g_ob_ms.xloc = g_ob_ms.temp;
      }
      if(g_ob_cfg.adjusted_points && (cur_abs % (mslen * 2) == 0) &&
         g_ob_ms.bos_valid && g_ob_plp_n > 0 && g_ob_plp[0] > g_ob_ms.choch)
      {
         g_ob_ms.choch = g_ob_plp[0];
         g_ob_ms.loc = g_ob_ms.xloc = g_ob_ms.temp = g_ob_pln[0];
      }
      if(g_ob_cfg.build_sweep && g_ob_ms.bos_valid &&
         hi >= g_ob_ms.bos && cl <= g_ob_ms.bos)
      {
         g_ob_ms.bos = hi;
         g_ob_ms.xloc = cur_abs;
      }
      else if(g_ob_ms.bos_valid && cl >= g_ob_ms.bos)
      {
         SmcObFn(true, topP, idbull);
         int id = SmcObFind(false, false, cur_abs);
         g_ob_ms.bos_valid = false;
         g_ob_ms.choch = g_ob_rates[id].low;
         g_ob_ms.choch_valid = true;
         g_ob_ms.loc = cur_abs - id;
         g_ob_ms.xloc = cur_abs;
      }
      else if(g_ob_cfg.build_sweep && g_ob_ms.choch_valid &&
              lo <= g_ob_ms.choch && cl >= g_ob_ms.choch)
      {
         g_ob_ms.choch = lo;
         g_ob_ms.xloc = cur_abs;
      }
      else if(g_ob_ms.choch_valid && cl <= g_ob_ms.choch)
      {
         SmcObFn(false, btmP, idbear);
         int id = SmcObFind(true, false, cur_abs);
         g_ob_ms.choch = g_ob_ms.bos_valid ? g_ob_ms.bos : g_ob_rates[id].high;
         g_ob_ms.choch_valid = true;
         g_ob_ms.bos_valid = false;
         g_ob_ms.main_px = lo;
         g_ob_ms.trend = -1;
         g_ob_ms.loc = g_ob_ms.xloc = g_ob_ms.temp = cur_abs;
      }
   }

   SmcObMitigate();
   SmcObOverlap();
}

void SmcObDraw()
{
   if(!g_ob_draw_enabled)
      return;
   SmcObObjClear();
   datetime t_ext = iTime(_Symbol, SmcObTf(), 0) + PeriodSeconds(SmcObTf()) * 5;
   for(int i = 0; i < g_ob_blob_n; i++)
   {
      if(!g_ob_blob[i].used) continue;
      string n = StringFormat("%sBU_%d", SMC_OB_PREFIX, i);
      SmcObObjRect(n, g_ob_blob[i].loc_time, g_ob_blob[i].top,
                   t_ext, g_ob_blob[i].btm, g_ob_cfg.ob_up, g_ob_cfg.ob_up);
      if(g_ob_cfg.show_midline)
      {
         string m = StringFormat("%sBUM_%d", SMC_OB_PREFIX, i);
         SmcObObjMid(m, g_ob_blob[i].loc_time, g_ob_blob[i].avg, t_ext, g_ob_cfg.ob_up);
      }
   }
   for(int i = 0; i < g_ob_brob_n; i++)
   {
      if(!g_ob_brob[i].used) continue;
      string n = StringFormat("%sBE_%d", SMC_OB_PREFIX, i);
      SmcObObjRect(n, g_ob_brob[i].loc_time, g_ob_brob[i].top,
                   t_ext, g_ob_brob[i].btm, g_ob_cfg.ob_dn, g_ob_cfg.ob_dn);
      if(g_ob_cfg.show_midline)
      {
         string m = StringFormat("%sBEM_%d", SMC_OB_PREFIX, i);
         SmcObObjMid(m, g_ob_brob[i].loc_time, g_ob_brob[i].avg, t_ext, g_ob_cfg.ob_dn);
      }
   }
}

bool SmcObLoadRates(const int need)
{
   ArraySetAsSeries(g_ob_rates, true);
   int n = CopyRates(_Symbol, SmcObTf(), 0, need, g_ob_rates);
   g_ob_rates_n = (n > 0) ? n : 0;
   return (g_ob_rates_n >= g_ob_cfg.pivot_len * 2 + 10);
}

void SmcObWarmup()
{
   int need = MathMax(g_ob_cfg.lookback, SMC_OB_ATR_LEN + 50);
   if(!SmcObLoadRates(need))
      return;
   SmcObCfg cfg = g_ob_cfg;
   SmcObReset();
   g_ob_cfg = cfg;

   MqlRates master[];
   int master_n = g_ob_rates_n;
   ArrayResize(master, master_n);
   ArraySetAsSeries(master, true);
   for(int i = 0; i < master_n; i++)
      master[i] = g_ob_rates[i];

   for(int sh = master_n - 1; sh >= 1; sh--)
   {
      int cnt = master_n - sh;
      ArrayResize(g_ob_rates, cnt);
      ArraySetAsSeries(g_ob_rates, true);
      for(int i = 0; i < cnt; i++)
         g_ob_rates[i] = master[sh + i];
      g_ob_rates_n = cnt;
      g_ob_bar_abs++;
      SmcObStructureStep(g_ob_bar_abs);
   }
   g_ob_warmed = true;
   SmcObDraw();
}

void SmcObUpdate()
{
   datetime t0 = iTime(_Symbol, SmcObTf(), 0);
   if(t0 == 0) return;
   if(!g_ob_warmed)
   {
      SmcObWarmup();
      g_ob_last_bar = t0;
      return;
   }
   if(t0 == g_ob_last_bar)
   {
      SmcObDraw(); // refresh extend-right only
      return;
   }
   g_ob_last_bar = t0;
   int need = MathMax(g_ob_cfg.lookback, SMC_OB_ATR_LEN + 50);
   ArraySetAsSeries(g_ob_rates, true);
   int n = CopyRates(_Symbol, SmcObTf(), 1, need, g_ob_rates);
   if(n < g_ob_cfg.pivot_len * 2 + 10)
      return;
   g_ob_rates_n = n;
   g_ob_bar_abs++;
   SmcObStructureStep(g_ob_bar_abs);
   SmcObDraw();
}

#endif
