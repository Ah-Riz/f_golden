//+------------------------------------------------------------------+
//| GRAI SmcLana — 1:1 logic port of pine/SMC_Lana.pine (primary)     |
//| Structure BOS/CHoCH, volumetric OB, mapping, liquidity prints.    |
//| Drawings: optional via GRAI_SmcDraw (SmcDraw.mqh).                |
//+------------------------------------------------------------------+
#ifndef GRAI_SMC_LANA_MQH
#define GRAI_SMC_LANA_MQH

#include "Types.mqh"
#include "AuditLog.mqh"

#define GRAI_SMC_MAX_OB   32
#define GRAI_SMC_MAX_PV   64
#define GRAI_SMC_ATR_LEN  200

enum ENUM_GRAI_SMC_OBMITI
{
   GRAI_SMC_MITI_CLOSE = 0,
   GRAI_SMC_MITI_WICK  = 1,
   GRAI_SMC_MITI_AVG   = 2
};

struct GRAI_SmcConfig
{
   int    pivot_len;       // mslen default 5
   bool   buildsweep;      // default true
   bool   adjusted_points; // msmode Adjusted Points
   bool   ob_length_mode;  // Length vs Full
   int    ob_miti;         // ENUM_GRAI_SMC_OBMITI
   int    ob_keep;         // oblast
   bool   hide_overlap;
   bool   show_breakers;
   int    lookback;        // mswindow / swingLimit scale
   bool   use_ob_filter;
   bool   use_liq_filter;
   bool   require_sweep;   // soft: prefer post-sweep (off = trend only hard)
};

struct GRAI_SmcMS
{
   int    zn;
   double zz;
   double bos;
   double choch;
   int    loc;      // bar_index absolute
   int    temp;
   int    trend;    // 1 bull -1 bear 0 none
   int    start;    // 0 init 1 first 2 run
   double main_px;
   int    xloc;
   bool   upsweep;
   bool   dnsweep;
   string txt;
   bool   bos_valid;
   bool   choch_valid;
};

struct GRAI_SmcOB
{
   bool   used;
   bool   bull;
   double top;
   double btm;
   double avg;
   datetime loc_time;
   double vol;
   int    dir;
   bool   isbb;
};

struct GRAI_SmcSnapshot
{
   bool   ready;
   int    trend;          // 1 / -1 / 0
   string txt;            // bos / choch / ""
   double bos;
   double choch;
   bool   upsweep;
   bool   dnsweep;
   bool   bos_valid;
   bool   choch_valid;
   int    map_trend;
   bool   liq_print_up;
   bool   liq_print_dn;
   bool   has_bull_ob;
   bool   has_bear_ob;
   double bull_ob_top;
   double bull_ob_btm;
   double bear_ob_top;
   double bear_ob_btm;
   bool   bull_ob_mitigated;
   bool   bear_ob_mitigated;
   string last_event;
};

GRAI_SmcConfig   g_grai_smc_cfg;
GRAI_SmcMS       g_grai_smc_ms;
GRAI_SmcOB       g_grai_smc_blob[GRAI_SMC_MAX_OB];
GRAI_SmcOB       g_grai_smc_brob[GRAI_SMC_MAX_OB];
int              g_grai_smc_blob_n = 0;
int              g_grai_smc_brob_n = 0;
GRAI_SmcSnapshot g_grai_smc_snap;

// pivot stacks (most recent at 0)
double g_grai_smc_php[GRAI_SMC_MAX_PV];
int    g_grai_smc_phn[GRAI_SMC_MAX_PV];
int    g_grai_smc_php_n = 0;
double g_grai_smc_plp[GRAI_SMC_MAX_PV];
int    g_grai_smc_pln[GRAI_SMC_MAX_PV];
int    g_grai_smc_plp_n = 0;

double g_grai_smc_up = 0.0;
double g_grai_smc_dn = 0.0;
bool   g_grai_smc_up_set = false;
bool   g_grai_smc_dn_set = false;

// mapping()
double g_grai_smc_map_up = 0.0;
double g_grai_smc_map_dn = 0.0;
bool   g_grai_smc_map_up_set = false;
bool   g_grai_smc_map_dn_set = false;
int    g_grai_smc_map_trend = 0;
int    g_grai_smc_map_idx = 0;

// posLIQ
double g_grai_smc_liq_up = 0.0;
double g_grai_smc_liq_dn = 0.0;
bool   g_grai_smc_liq_up_allow = true;
bool   g_grai_smc_liq_dn_allow = true;

datetime g_grai_smc_last_bar = 0;
bool     g_grai_smc_warmed = false;
int      g_grai_smc_bar_abs = 0; // synthetic bar_index

// OHLC working set for current process bar (series: 0=current)
MqlRates g_grai_smc_rates[];
int      g_grai_smc_rates_n = 0;

void GRAI_SmcConfigDefaults()
{
   ZeroMemory(g_grai_smc_cfg);
   g_grai_smc_cfg.pivot_len       = 5;
   g_grai_smc_cfg.buildsweep      = true;
   g_grai_smc_cfg.adjusted_points = true;
   g_grai_smc_cfg.ob_length_mode  = true;
   g_grai_smc_cfg.ob_miti         = GRAI_SMC_MITI_CLOSE;
   g_grai_smc_cfg.ob_keep         = 5;
   g_grai_smc_cfg.hide_overlap    = true;
   g_grai_smc_cfg.show_breakers   = false;
   g_grai_smc_cfg.lookback        = 500;
   g_grai_smc_cfg.use_ob_filter   = true;
   g_grai_smc_cfg.use_liq_filter  = false;
   g_grai_smc_cfg.require_sweep   = false;
}

void GRAI_SmcResetEngine()
{
   ZeroMemory(g_grai_smc_ms);
   g_grai_smc_ms.txt = "";
   g_grai_smc_blob_n = 0;
   g_grai_smc_brob_n = 0;
   g_grai_smc_php_n = 0;
   g_grai_smc_plp_n = 0;
   g_grai_smc_up_set = false;
   g_grai_smc_dn_set = false;
   g_grai_smc_map_up_set = false;
   g_grai_smc_map_dn_set = false;
   g_grai_smc_map_trend = 0;
   g_grai_smc_liq_up_allow = true;
   g_grai_smc_liq_dn_allow = true;
   g_grai_smc_warmed = false;
   g_grai_smc_bar_abs = 0;
   ZeroMemory(g_grai_smc_snap);
   g_grai_smc_snap.txt = "";
   g_grai_smc_snap.last_event = "";
}

double GRAI_SmcATR(const int shift, const int period)
{
   if(g_grai_smc_rates_n <= shift + period)
      return 0.0;
   double sum = 0.0;
   for(int i = shift; i < shift + period; i++)
   {
      double tr = g_grai_smc_rates[i].high - g_grai_smc_rates[i].low;
      if(i + 1 < g_grai_smc_rates_n)
      {
         double a = MathAbs(g_grai_smc_rates[i].high - g_grai_smc_rates[i + 1].close);
         double b = MathAbs(g_grai_smc_rates[i].low  - g_grai_smc_rates[i + 1].close);
         tr = MathMax(tr, MathMax(a, b));
      }
      sum += tr;
   }
   return sum / (double)period;
}

bool GRAI_SmcPivotHigh(const int left, const int right, const int center_shift, double &out_px)
{
   // center at center_shift confirmed when we have right bars newer (lower shift)
   if(center_shift - right < 0 || center_shift + left >= g_grai_smc_rates_n)
      return false;
   double c = g_grai_smc_rates[center_shift].high;
   for(int i = 1; i <= left; i++)
      if(g_grai_smc_rates[center_shift + i].high >= c)
         return false;
   for(int i = 1; i <= right; i++)
      if(g_grai_smc_rates[center_shift - i].high > c)
         return false;
   out_px = c;
   return true;
}

bool GRAI_SmcPivotLow(const int left, const int right, const int center_shift, double &out_px)
{
   if(center_shift - right < 0 || center_shift + left >= g_grai_smc_rates_n)
      return false;
   double c = g_grai_smc_rates[center_shift].low;
   for(int i = 1; i <= left; i++)
      if(g_grai_smc_rates[center_shift + i].low <= c)
         return false;
   for(int i = 1; i <= right; i++)
      if(g_grai_smc_rates[center_shift - i].low < c)
         return false;
   out_px = c;
   return true;
}

void GRAI_SmcPhpUnshift(const double px, const int abs_bar)
{
   for(int i = MathMin(g_grai_smc_php_n, GRAI_SMC_MAX_PV - 1); i > 0; i--)
   {
      g_grai_smc_php[i] = g_grai_smc_php[i - 1];
      g_grai_smc_phn[i] = g_grai_smc_phn[i - 1];
   }
   g_grai_smc_php[0] = px;
   g_grai_smc_phn[0] = abs_bar;
   if(g_grai_smc_php_n < GRAI_SMC_MAX_PV)
      g_grai_smc_php_n++;
}

void GRAI_SmcPlpUnshift(const double px, const int abs_bar)
{
   for(int i = MathMin(g_grai_smc_plp_n, GRAI_SMC_MAX_PV - 1); i > 0; i--)
   {
      g_grai_smc_plp[i] = g_grai_smc_plp[i - 1];
      g_grai_smc_pln[i] = g_grai_smc_pln[i - 1];
   }
   g_grai_smc_plp[0] = px;
   g_grai_smc_pln[0] = abs_bar;
   if(g_grai_smc_plp_n < GRAI_SMC_MAX_PV)
      g_grai_smc_plp_n++;
}

void GRAI_SmcPhpClear() { g_grai_smc_php_n = 0; }
void GRAI_SmcPlpClear() { g_grai_smc_plp_n = 0; }

int GRAI_SmcFind(const bool use_max, const bool sweep, const bool useob, const int cur_abs)
{
   int anchor = sweep ? g_grai_smc_ms.xloc : g_grai_smc_ms.loc;
   int span = cur_abs - anchor;
   if(span < 0)
      span = 0;
   double minv = 1.0e100;
   double maxv = 0.0;
   int idx = 0;
   int lim = span;
   if(!sweep && span - 1 > 0)
      lim = span - 1;
   for(int i = 0; i <= lim && i < g_grai_smc_rates_n; i++)
   {
      if(use_max)
      {
         if(g_grai_smc_rates[i].high >= maxv)
         {
            maxv = g_grai_smc_rates[i].high;
            minv = g_grai_smc_rates[i].low;
            idx = i;
         }
      }
      else
      {
         if(g_grai_smc_rates[i].low <= minv)
         {
            minv = g_grai_smc_rates[i].low;
            maxv = g_grai_smc_rates[i].high;
            idx = i;
         }
      }
   }
   if(useob)
   {
      if(use_max && idx + 1 < g_grai_smc_rates_n &&
         g_grai_smc_rates[idx + 1].high > g_grai_smc_rates[idx].high)
         idx = idx + 1;
      if(!use_max && idx + 1 < g_grai_smc_rates_n &&
         g_grai_smc_rates[idx + 1].low < g_grai_smc_rates[idx].low)
         idx = idx + 1;
   }
   return idx;
}

void GRAI_SmcObTrim(GRAI_SmcOB &arr[], int &n)
{
   int keep = g_grai_smc_cfg.ob_keep;
   if(keep < 0)
      keep = 0;
   if(n > keep)
      n = keep;
}

void GRAI_SmcObUnshift(GRAI_SmcOB &arr[], int &n, const GRAI_SmcOB &ob)
{
   for(int i = MathMin(n, GRAI_SMC_MAX_OB - 1); i > 0; i--)
      arr[i] = arr[i - 1];
   arr[0] = ob;
   arr[0].used = true;
   if(n < GRAI_SMC_MAX_OB)
      n++;
   GRAI_SmcObTrim(arr, n);
}

void GRAI_SmcFnOB(const bool bull, const double cords, const int idx)
{
   if(idx < 0 || idx >= g_grai_smc_rates_n)
      return;
   GRAI_SmcOB o;
   ZeroMemory(o);
   o.used = true;
   o.bull = bull;
   o.loc_time = g_grai_smc_rates[idx].time;
   o.vol = (double)g_grai_smc_rates[idx].tick_volume;
   o.dir = (g_grai_smc_rates[idx].close > g_grai_smc_rates[idx].open) ? 1 : -1;
   o.isbb = false;
   if(bull)
   {
      o.top = cords;
      o.btm = g_grai_smc_rates[idx].low;
      o.avg = 0.5 * (cords + o.btm);
      GRAI_SmcObUnshift(g_grai_smc_blob, g_grai_smc_blob_n, o);
   }
   else
   {
      o.top = g_grai_smc_rates[idx].high;
      o.btm = cords;
      o.avg = 0.5 * (cords + o.top);
      GRAI_SmcObUnshift(g_grai_smc_brob, g_grai_smc_brob_n, o);
   }
}

bool GRAI_SmcMitiHitBull(const GRAI_SmcOB &o, const double open_, const double close_,
                         const double high_, const double low_)
{
   if(g_grai_smc_cfg.ob_miti == GRAI_SMC_MITI_WICK)
      return (low_ < o.btm);
   if(g_grai_smc_cfg.ob_miti == GRAI_SMC_MITI_AVG)
      return (low_ < o.avg);
   return (MathMin(close_, open_) < o.btm);
}

bool GRAI_SmcMitiHitBear(const GRAI_SmcOB &o, const double open_, const double close_,
                         const double high_, const double low_)
{
   if(g_grai_smc_cfg.ob_miti == GRAI_SMC_MITI_WICK)
      return (high_ > o.top);
   if(g_grai_smc_cfg.ob_miti == GRAI_SMC_MITI_AVG)
      return (high_ > o.avg);
   return (MathMax(close_, open_) > o.top);
}

void GRAI_SmcMitigated()
{
   double o = g_grai_smc_rates[0].open;
   double c = g_grai_smc_rates[0].close;
   double h = g_grai_smc_rates[0].high;
   double l = g_grai_smc_rates[0].low;
   for(int i = 0; i < g_grai_smc_blob_n; i++)
   {
      if(!g_grai_smc_blob[i].used)
         continue;
      if(!g_grai_smc_blob[i].isbb)
      {
         if(GRAI_SmcMitiHitBull(g_grai_smc_blob[i], o, c, h, l))
         {
            g_grai_smc_blob[i].isbb = true;
            g_grai_smc_snap.last_event = "OB_MITI_BULL";
            if(!g_grai_smc_cfg.show_breakers)
            {
               for(int j = i; j < g_grai_smc_blob_n - 1; j++)
                  g_grai_smc_blob[j] = g_grai_smc_blob[j + 1];
               g_grai_smc_blob_n--;
               i--;
            }
         }
      }
      else
      {
         if(g_grai_smc_cfg.ob_miti == GRAI_SMC_MITI_WICK ? (h > g_grai_smc_blob[i].top)
            : g_grai_smc_cfg.ob_miti == GRAI_SMC_MITI_AVG ? (h > g_grai_smc_blob[i].avg)
            : (MathMax(c, o) > g_grai_smc_blob[i].top))
         {
            for(int j = i; j < g_grai_smc_blob_n - 1; j++)
               g_grai_smc_blob[j] = g_grai_smc_blob[j + 1];
            g_grai_smc_blob_n--;
            i--;
         }
      }
   }
   for(int i = 0; i < g_grai_smc_brob_n; i++)
   {
      if(!g_grai_smc_brob[i].used)
         continue;
      if(!g_grai_smc_brob[i].isbb)
      {
         if(GRAI_SmcMitiHitBear(g_grai_smc_brob[i], o, c, h, l))
         {
            g_grai_smc_brob[i].isbb = true;
            g_grai_smc_snap.last_event = "OB_MITI_BEAR";
            if(!g_grai_smc_cfg.show_breakers)
            {
               for(int j = i; j < g_grai_smc_brob_n - 1; j++)
                  g_grai_smc_brob[j] = g_grai_smc_brob[j + 1];
               g_grai_smc_brob_n--;
               i--;
            }
         }
      }
      else
      {
         if(g_grai_smc_cfg.ob_miti == GRAI_SMC_MITI_WICK ? (l < g_grai_smc_brob[i].btm)
            : g_grai_smc_cfg.ob_miti == GRAI_SMC_MITI_AVG ? (l < g_grai_smc_brob[i].avg)
            : (MathMin(c, o) < g_grai_smc_brob[i].btm))
         {
            for(int j = i; j < g_grai_smc_brob_n - 1; j++)
               g_grai_smc_brob[j] = g_grai_smc_brob[j + 1];
            g_grai_smc_brob_n--;
            i--;
         }
      }
   }
}

void GRAI_SmcOverlapOb()
{
   if(!g_grai_smc_cfg.hide_overlap)
      return;
   // Recent-overlap: drop older that intersect newest (index 0)
   if(g_grai_smc_blob_n > 1)
   {
      GRAI_SmcOB cur = g_grai_smc_blob[0];
      for(int i = g_grai_smc_blob_n - 1; i >= 1; i--)
      {
         GRAI_SmcOB s = g_grai_smc_blob[i];
         bool hit =
            (s.btm > cur.btm && s.btm < cur.top) ||
            (s.top < cur.top && s.btm > cur.btm) ||
            (s.top > cur.top && s.btm < cur.btm) ||
            (s.top < cur.top && s.top > cur.btm);
         if(hit)
         {
            for(int j = i; j < g_grai_smc_blob_n - 1; j++)
               g_grai_smc_blob[j] = g_grai_smc_blob[j + 1];
            g_grai_smc_blob_n--;
         }
      }
   }
   if(g_grai_smc_brob_n > 1)
   {
      GRAI_SmcOB cur = g_grai_smc_brob[0];
      for(int i = g_grai_smc_brob_n - 1; i >= 1; i--)
      {
         GRAI_SmcOB s = g_grai_smc_brob[i];
         bool hit =
            (s.btm > cur.btm && s.btm < cur.top) ||
            (s.top < cur.top && s.btm > cur.btm) ||
            (s.top > cur.top && s.btm < cur.btm) ||
            (s.top < cur.top && s.top > cur.btm);
         if(hit)
         {
            for(int j = i; j < g_grai_smc_brob_n - 1; j++)
               g_grai_smc_brob[j] = g_grai_smc_brob[j + 1];
            g_grai_smc_brob_n--;
         }
      }
   }
}

void GRAI_SmcMappingStep(const int cur_abs)
{
   double hi = g_grai_smc_rates[0].high;
   double lo = g_grai_smc_rates[0].low;
   if(!g_grai_smc_map_up_set)
   {
      g_grai_smc_map_up = hi;
      g_grai_smc_map_up_set = true;
      g_grai_smc_map_idx = cur_abs;
   }
   if(!g_grai_smc_map_dn_set)
   {
      g_grai_smc_map_dn = lo;
      g_grai_smc_map_dn_set = true;
      g_grai_smc_map_idx = cur_abs;
   }
   if(hi > g_grai_smc_map_up)
   {
      g_grai_smc_map_up = hi;
      g_grai_smc_map_dn = lo;
      g_grai_smc_map_trend = 1;
   }
   if(lo < g_grai_smc_map_dn)
   {
      g_grai_smc_map_up = hi;
      g_grai_smc_map_dn = lo;
      g_grai_smc_map_trend = -1;
   }
}

void GRAI_SmcPosLiqStep(const int mslen)
{
   double ph = 0.0, pl = 0.0;
   bool has_ph = GRAI_SmcPivotHigh(mslen, mslen, mslen, ph);
   bool has_pl = GRAI_SmcPivotLow(mslen, mslen, mslen, pl);
   if(has_ph)
      g_grai_smc_liq_up = ph;
   if(has_pl)
      g_grai_smc_liq_dn = pl;

   g_grai_smc_snap.liq_print_up = false;
   g_grai_smc_snap.liq_print_dn = false;
   double hi = g_grai_smc_rates[0].high;
   double lo = g_grai_smc_rates[0].low;
   double cl = g_grai_smc_rates[0].close;
   double hi1 = (g_grai_smc_rates_n > 1) ? g_grai_smc_rates[1].high : hi;
   double lo1 = (g_grai_smc_rates_n > 1) ? g_grai_smc_rates[1].low : lo;

   if(g_grai_smc_liq_up > 0.0 && hi > g_grai_smc_liq_up && cl < g_grai_smc_liq_up &&
      g_grai_smc_liq_up_allow && hi > hi1)
   {
      g_grai_smc_liq_up_allow = false;
      g_grai_smc_snap.liq_print_up = true;
      g_grai_smc_snap.last_event = "LIQ_PRINT_BEAR";
   }
   if(g_grai_smc_liq_dn > 0.0 && lo < g_grai_smc_liq_dn && cl > g_grai_smc_liq_dn &&
      g_grai_smc_liq_dn_allow && lo < lo1)
   {
      g_grai_smc_liq_dn_allow = false;
      g_grai_smc_snap.liq_print_dn = true;
      g_grai_smc_snap.last_event = "LIQ_PRINT_BULL";
   }
   if(has_ph && !g_grai_smc_liq_up_allow)
      g_grai_smc_liq_up_allow = true;
   if(has_pl && !g_grai_smc_liq_dn_allow)
      g_grai_smc_liq_dn_allow = true;
}

void GRAI_SmcEvent(const string ev, const int trend)
{
   g_grai_smc_snap.last_event = ev;
   static datetime s_log = 0;
   if(TimeCurrent() != s_log)
   {
      GRAI_Log("SMC", StringFormat("%s trend=%d", ev, trend));
      s_log = TimeCurrent();
   }
}

// Process one closed bar at rates[0] with absolute bar index cur_abs.
void GRAI_SmcStructureStep(const int cur_abs)
{
   const int mslen = g_grai_smc_cfg.pivot_len;
   double hi = g_grai_smc_rates[0].high;
   double lo = g_grai_smc_rates[0].low;
   double cl = g_grai_smc_rates[0].close;
   double op = g_grai_smc_rates[0].open;
   double cl1 = (g_grai_smc_rates_n > 1) ? g_grai_smc_rates[1].close : cl;
   double op1 = (g_grai_smc_rates_n > 1) ? g_grai_smc_rates[1].open : op;

   double atr = GRAI_SmcATR(0, GRAI_SMC_ATR_LEN);
   if(atr <= 0.0)
      atr = hi - lo;

   int idbull = GRAI_SmcFind(false, false, true, cur_abs);
   int idbear = GRAI_SmcFind(true, false, true, cur_abs);
   double btmP, topP;
   if(g_grai_smc_cfg.ob_length_mode && idbear < g_grai_smc_rates_n)
   {
      double atr_b = GRAI_SmcATR(idbear, GRAI_SMC_ATR_LEN);
      if(atr_b <= 0.0) atr_b = atr;
      btmP = (g_grai_smc_rates[idbear].high - atr_b) < g_grai_smc_rates[idbear].low
             ? g_grai_smc_rates[idbear].low
             : (g_grai_smc_rates[idbear].high - atr_b);
   }
   else
      btmP = (idbear < g_grai_smc_rates_n) ? g_grai_smc_rates[idbear].low : lo;

   if(g_grai_smc_cfg.ob_length_mode && idbull < g_grai_smc_rates_n)
   {
      double atr_u = GRAI_SmcATR(idbull, GRAI_SMC_ATR_LEN);
      if(atr_u <= 0.0) atr_u = atr;
      topP = (g_grai_smc_rates[idbull].low + atr_u) > g_grai_smc_rates[idbull].high
             ? g_grai_smc_rates[idbull].high
             : (g_grai_smc_rates[idbull].low + atr_u);
   }
   else
      topP = (idbull < g_grai_smc_rates_n) ? g_grai_smc_rates[idbull].high : hi;

   // pivots (confirmed at shift=mslen)
   double ph = 0.0, pl = 0.0;
   if(GRAI_SmcPivotHigh(mslen, mslen, mslen, ph))
      GRAI_SmcPhpUnshift(ph, cur_abs - mslen);
   if(GRAI_SmcPivotLow(mslen, mslen, mslen, pl))
      GRAI_SmcPlpUnshift(pl, cur_abs - mslen);

   if(g_grai_smc_php_n > 0 && hi > g_grai_smc_php[0])
      GRAI_SmcPhpClear();
   if(g_grai_smc_plp_n > 0 && lo < g_grai_smc_plp[0])
      GRAI_SmcPlpClear();

   bool crossup = false;
   bool crossdn = false;
   if(!g_grai_smc_up_set)
   {
      g_grai_smc_up = hi;
      g_grai_smc_up_set = true;
   }
   if(!g_grai_smc_dn_set)
   {
      g_grai_smc_dn = lo;
      g_grai_smc_dn_set = true;
   }
   if(hi > g_grai_smc_up)
   {
      g_grai_smc_up = hi;
      g_grai_smc_dn = lo;
      crossup = true;
   }
   if(lo < g_grai_smc_dn)
   {
      g_grai_smc_up = hi;
      g_grai_smc_dn = lo;
      crossdn = true;
   }

   g_grai_smc_ms.upsweep = false;
   g_grai_smc_ms.dnsweep = false;

   if(g_grai_smc_ms.start == 0)
   {
      g_grai_smc_ms.start = 1;
      g_grai_smc_ms.bos = hi;
      g_grai_smc_ms.choch = lo;
      g_grai_smc_ms.bos_valid = true;
      g_grai_smc_ms.choch_valid = true;
      g_grai_smc_ms.loc = cur_abs;
      g_grai_smc_ms.temp = cur_abs;
      g_grai_smc_ms.xloc = cur_abs;
      g_grai_smc_ms.trend = 0;
      g_grai_smc_ms.main_px = hi;
      return;
   }

   if(g_grai_smc_ms.start == 1)
   {
      if(g_grai_smc_cfg.buildsweep && g_grai_smc_ms.choch_valid &&
         lo <= g_grai_smc_ms.choch && cl >= g_grai_smc_ms.choch)
      {
         g_grai_smc_ms.dnsweep = true;
         g_grai_smc_ms.choch = lo;
         g_grai_smc_ms.xloc = cur_abs;
         GRAI_SmcEvent("CHoCH_SWEEP_BEAR", -1);
      }
      else if(g_grai_smc_cfg.buildsweep && g_grai_smc_ms.bos_valid &&
              hi >= g_grai_smc_ms.bos && cl <= g_grai_smc_ms.bos)
      {
         g_grai_smc_ms.upsweep = true;
         g_grai_smc_ms.bos = hi;
         g_grai_smc_ms.xloc = cur_abs;
         GRAI_SmcEvent("CHoCH_SWEEP_BULL", 1);
      }
      else if(g_grai_smc_ms.choch_valid && cl <= g_grai_smc_ms.choch)
      {
         g_grai_smc_ms.txt = "choch";
         GRAI_SmcFnOB(true, topP, idbull);
         g_grai_smc_ms.trend = -1;
         g_grai_smc_ms.choch = g_grai_smc_ms.bos;
         g_grai_smc_ms.bos_valid = false;
         g_grai_smc_ms.choch_valid = g_grai_smc_ms.bos_valid ? true : true;
         // pine: ms.choch := ms.bos; ms.bos := na
         g_grai_smc_ms.choch = g_grai_smc_ms.bos;
         g_grai_smc_ms.choch_valid = true;
         g_grai_smc_ms.bos_valid = false;
         g_grai_smc_ms.start = 2;
         g_grai_smc_ms.loc = cur_abs;
         g_grai_smc_ms.main_px = lo;
         g_grai_smc_ms.temp = cur_abs;
         g_grai_smc_ms.xloc = cur_abs;
         GRAI_SmcEvent("CHoCH_BEAR", -1);
      }
      else if(g_grai_smc_ms.bos_valid && cl >= g_grai_smc_ms.bos)
      {
         g_grai_smc_ms.txt = "choch";
         GRAI_SmcFnOB(false, btmP, idbear);
         g_grai_smc_ms.trend = 1;
         g_grai_smc_ms.bos_valid = false;
         g_grai_smc_ms.start = 2;
         g_grai_smc_ms.loc = cur_abs;
         g_grai_smc_ms.main_px = hi;
         g_grai_smc_ms.temp = cur_abs;
         g_grai_smc_ms.xloc = cur_abs;
         GRAI_SmcEvent("CHoCH_BULL", 1);
      }
      return;
   }

   // start == 2
   if(g_grai_smc_ms.trend == -1)
   {
      if(lo <= g_grai_smc_ms.main_px)
      {
         g_grai_smc_ms.main_px = lo;
         g_grai_smc_ms.temp = cur_abs;
      }
      if(g_grai_smc_cfg.adjusted_points && (cur_abs % (mslen * 2) == 0) &&
         g_grai_smc_ms.bos_valid && g_grai_smc_php_n > 0)
      {
         if(g_grai_smc_php[0] < g_grai_smc_ms.choch)
         {
            g_grai_smc_ms.choch = g_grai_smc_php[0];
            g_grai_smc_ms.loc = g_grai_smc_phn[0];
            g_grai_smc_ms.xloc = g_grai_smc_phn[0];
            g_grai_smc_ms.temp = g_grai_smc_phn[0];
         }
      }
      if(!g_grai_smc_ms.bos_valid)
      {
         if(crossup && cl > op && cl1 > op1)
         {
            g_grai_smc_ms.bos = g_grai_smc_ms.main_px;
            g_grai_smc_ms.bos_valid = true;
            g_grai_smc_ms.loc = g_grai_smc_ms.temp;
            g_grai_smc_ms.xloc = g_grai_smc_ms.loc;
         }
      }
      if(g_grai_smc_cfg.buildsweep && g_grai_smc_ms.bos_valid &&
         lo <= g_grai_smc_ms.bos && cl >= g_grai_smc_ms.bos)
      {
         g_grai_smc_ms.dnsweep = true;
         g_grai_smc_ms.bos = lo;
         g_grai_smc_ms.xloc = cur_abs;
         GRAI_SmcEvent("BOS_SWEEP_BEAR", -1);
      }
      else if(g_grai_smc_ms.bos_valid && cl <= g_grai_smc_ms.bos)
      {
         g_grai_smc_ms.txt = "bos";
         g_grai_smc_ms.zz = g_grai_smc_ms.bos;
         g_grai_smc_ms.zn = cur_abs;
         GRAI_SmcFnOB(false, btmP, idbear);
         int id = GRAI_SmcFind(true, false, false, cur_abs);
         g_grai_smc_ms.xloc = cur_abs;
         g_grai_smc_ms.bos_valid = false;
         g_grai_smc_ms.choch = g_grai_smc_rates[id].high;
         g_grai_smc_ms.choch_valid = true;
         g_grai_smc_ms.loc = cur_abs - id;
         GRAI_SmcEvent("BOS_BEAR", -1);
      }
      else if(g_grai_smc_cfg.buildsweep && g_grai_smc_ms.choch_valid &&
              hi >= g_grai_smc_ms.choch && cl <= g_grai_smc_ms.choch)
      {
         g_grai_smc_ms.upsweep = true;
         g_grai_smc_ms.choch = hi;
         g_grai_smc_ms.xloc = cur_abs;
         GRAI_SmcEvent("CHoCH_SWEEP_BULL", 1);
      }
      else if(g_grai_smc_ms.choch_valid && cl >= g_grai_smc_ms.choch)
      {
         g_grai_smc_ms.txt = "choch";
         g_grai_smc_ms.zz = g_grai_smc_ms.choch;
         g_grai_smc_ms.zn = cur_abs;
         GRAI_SmcFnOB(true, topP, idbull);
         int id = GRAI_SmcFind(false, false, false, cur_abs);
         if(!g_grai_smc_ms.bos_valid)
            g_grai_smc_ms.choch = g_grai_smc_rates[id].low;
         else
            g_grai_smc_ms.choch = g_grai_smc_ms.bos;
         g_grai_smc_ms.choch_valid = true;
         g_grai_smc_ms.bos_valid = false;
         g_grai_smc_ms.main_px = hi;
         g_grai_smc_ms.trend = 1;
         g_grai_smc_ms.loc = cur_abs;
         g_grai_smc_ms.xloc = cur_abs;
         g_grai_smc_ms.temp = cur_abs;
         GRAI_SmcEvent("CHoCH_BULL", 1);
      }
   }
   else if(g_grai_smc_ms.trend == 1)
   {
      if(hi >= g_grai_smc_ms.main_px)
      {
         g_grai_smc_ms.main_px = hi;
         g_grai_smc_ms.temp = cur_abs;
      }
      if(!g_grai_smc_ms.bos_valid)
      {
         if(crossdn && cl < op && cl1 < op1)
         {
            g_grai_smc_ms.bos = g_grai_smc_ms.main_px;
            g_grai_smc_ms.bos_valid = true;
            g_grai_smc_ms.loc = g_grai_smc_ms.temp;
            g_grai_smc_ms.xloc = g_grai_smc_ms.loc;
         }
      }
      if(g_grai_smc_cfg.adjusted_points && (cur_abs % (mslen * 2) == 0) &&
         g_grai_smc_ms.bos_valid && g_grai_smc_plp_n > 0)
      {
         if(g_grai_smc_plp[0] > g_grai_smc_ms.choch)
         {
            g_grai_smc_ms.choch = g_grai_smc_plp[0];
            g_grai_smc_ms.loc = g_grai_smc_pln[0];
            g_grai_smc_ms.xloc = g_grai_smc_pln[0];
            g_grai_smc_ms.temp = g_grai_smc_pln[0];
         }
      }
      if(g_grai_smc_cfg.buildsweep && g_grai_smc_ms.bos_valid &&
         hi >= g_grai_smc_ms.bos && cl <= g_grai_smc_ms.bos)
      {
         g_grai_smc_ms.upsweep = true;
         g_grai_smc_ms.bos = hi;
         g_grai_smc_ms.xloc = cur_abs;
         GRAI_SmcEvent("BOS_SWEEP_BULL", 1);
      }
      else if(g_grai_smc_ms.bos_valid && cl >= g_grai_smc_ms.bos)
      {
         g_grai_smc_ms.txt = "bos";
         g_grai_smc_ms.zz = g_grai_smc_ms.bos;
         g_grai_smc_ms.zn = cur_abs;
         GRAI_SmcFnOB(true, topP, idbull);
         int id = GRAI_SmcFind(false, false, false, cur_abs);
         g_grai_smc_ms.xloc = cur_abs;
         g_grai_smc_ms.bos_valid = false;
         g_grai_smc_ms.choch = g_grai_smc_rates[id].low;
         g_grai_smc_ms.choch_valid = true;
         g_grai_smc_ms.loc = cur_abs - id;
         GRAI_SmcEvent("BOS_BULL", 1);
      }
      else if(g_grai_smc_cfg.buildsweep && g_grai_smc_ms.choch_valid &&
              lo <= g_grai_smc_ms.choch && cl >= g_grai_smc_ms.choch)
      {
         g_grai_smc_ms.dnsweep = true;
         g_grai_smc_ms.choch = lo;
         g_grai_smc_ms.xloc = cur_abs;
         GRAI_SmcEvent("CHoCH_SWEEP_BEAR", -1);
      }
      else if(g_grai_smc_ms.choch_valid && cl <= g_grai_smc_ms.choch)
      {
         g_grai_smc_ms.txt = "choch";
         g_grai_smc_ms.zz = g_grai_smc_ms.choch;
         g_grai_smc_ms.zn = cur_abs;
         GRAI_SmcFnOB(false, btmP, idbear);
         int id = GRAI_SmcFind(true, false, false, cur_abs);
         if(!g_grai_smc_ms.bos_valid)
            g_grai_smc_ms.choch = g_grai_smc_rates[id].high;
         else
            g_grai_smc_ms.choch = g_grai_smc_ms.bos;
         g_grai_smc_ms.choch_valid = true;
         g_grai_smc_ms.bos_valid = false;
         g_grai_smc_ms.main_px = lo;
         g_grai_smc_ms.trend = -1;
         g_grai_smc_ms.loc = cur_abs;
         g_grai_smc_ms.xloc = cur_abs;
         g_grai_smc_ms.temp = cur_abs;
         GRAI_SmcEvent("CHoCH_BEAR", -1);
      }
   }

   GRAI_SmcMitigated();
   GRAI_SmcOverlapOb();
}

void GRAI_SmcPublishSnap()
{
   g_grai_smc_snap.ready = (g_grai_smc_ms.start >= 2 && g_grai_smc_ms.trend != 0);
   g_grai_smc_snap.trend = g_grai_smc_ms.trend;
   g_grai_smc_snap.txt = g_grai_smc_ms.txt;
   g_grai_smc_snap.bos = g_grai_smc_ms.bos;
   g_grai_smc_snap.choch = g_grai_smc_ms.choch;
   g_grai_smc_snap.bos_valid = g_grai_smc_ms.bos_valid;
   g_grai_smc_snap.choch_valid = g_grai_smc_ms.choch_valid;
   g_grai_smc_snap.upsweep = g_grai_smc_ms.upsweep;
   g_grai_smc_snap.dnsweep = g_grai_smc_ms.dnsweep;
   g_grai_smc_snap.map_trend = g_grai_smc_map_trend;

   g_grai_smc_snap.has_bull_ob = (g_grai_smc_blob_n > 0);
   g_grai_smc_snap.has_bear_ob = (g_grai_smc_brob_n > 0);
   if(g_grai_smc_blob_n > 0)
   {
      g_grai_smc_snap.bull_ob_top = g_grai_smc_blob[0].top;
      g_grai_smc_snap.bull_ob_btm = g_grai_smc_blob[0].btm;
      g_grai_smc_snap.bull_ob_mitigated = g_grai_smc_blob[0].isbb;
   }
   if(g_grai_smc_brob_n > 0)
   {
      g_grai_smc_snap.bear_ob_top = g_grai_smc_brob[0].top;
      g_grai_smc_snap.bear_ob_btm = g_grai_smc_brob[0].btm;
      g_grai_smc_snap.bear_ob_mitigated = g_grai_smc_brob[0].isbb;
   }
}

bool GRAI_SmcLoadRates(const int need)
{
   ArraySetAsSeries(g_grai_smc_rates, true);
   int n = CopyRates(_Symbol, PERIOD_CURRENT, 0, need, g_grai_smc_rates);
   g_grai_smc_rates_n = (n > 0) ? n : 0;
   return (g_grai_smc_rates_n >= g_grai_smc_cfg.pivot_len * 2 + 10);
}

void GRAI_SmcWarmup()
{
   int need = MathMax(g_grai_smc_cfg.lookback, GRAI_SMC_ATR_LEN + 50);
   if(!GRAI_SmcLoadRates(need))
      return;

   GRAI_SmcConfig cfg = g_grai_smc_cfg;
   GRAI_SmcResetEngine();
   g_grai_smc_cfg = cfg;

   MqlRates master[];
   int master_n = g_grai_smc_rates_n;
   ArrayResize(master, master_n);
   ArraySetAsSeries(master, true);
   for(int i = 0; i < master_n; i++)
      master[i] = g_grai_smc_rates[i];

   // oldest → newest closed; series: high index = older; skip forming [0]
   int oldest = master_n - 1;
   int newest_closed = 1;
   for(int sh = oldest; sh >= newest_closed; sh--)
   {
      int cnt = master_n - sh;
      ArrayResize(g_grai_smc_rates, cnt);
      ArraySetAsSeries(g_grai_smc_rates, true);
      for(int i = 0; i < cnt; i++)
         g_grai_smc_rates[i] = master[sh + i];
      g_grai_smc_rates_n = cnt;
      g_grai_smc_bar_abs++;
      GRAI_SmcStructureStep(g_grai_smc_bar_abs);
      GRAI_SmcMappingStep(g_grai_smc_bar_abs);
      GRAI_SmcPosLiqStep(g_grai_smc_cfg.pivot_len);
   }
   GRAI_SmcPublishSnap();
   g_grai_smc_warmed = true;
   GRAI_Log("SMC", StringFormat("warmup bars=%d trend=%d ready=%s event=%s",
      g_grai_smc_bar_abs, g_grai_smc_snap.trend,
      (g_grai_smc_snap.ready ? "Y" : "N"), g_grai_smc_snap.last_event));
}

void GRAI_SmcUpdate()
{
   datetime t0 = iTime(_Symbol, PERIOD_CURRENT, 0);
   if(t0 == 0)
      return;
   if(!g_grai_smc_warmed)
   {
      GRAI_SmcWarmup();
      g_grai_smc_last_bar = t0;
      return;
   }
   if(t0 == g_grai_smc_last_bar)
      return; // wait for new bar; process previous close once
   // new bar → process closed bar (shift 1 as rates[0] after reload)
   g_grai_smc_last_bar = t0;
   int need = MathMax(g_grai_smc_cfg.lookback, GRAI_SMC_ATR_LEN + 50);
   if(!GRAI_SmcLoadRates(need))
      return;
   // Use closed bar: copy so rates[0] = previous closed
   if(g_grai_smc_rates_n < 2)
      return;
   MqlRates closed[];
   int cnt = g_grai_smc_rates_n - 1;
   ArrayResize(closed, cnt);
   ArraySetAsSeries(closed, true);
   for(int i = 0; i < cnt; i++)
      closed[i] = g_grai_smc_rates[i + 1];
   ArrayResize(g_grai_smc_rates, cnt);
   ArraySetAsSeries(g_grai_smc_rates, true);
   for(int i = 0; i < cnt; i++)
      g_grai_smc_rates[i] = closed[i];
   g_grai_smc_rates_n = cnt;

   int prev_trend = g_grai_smc_ms.trend;
   g_grai_smc_bar_abs++;
   GRAI_SmcStructureStep(g_grai_smc_bar_abs);
   GRAI_SmcMappingStep(g_grai_smc_bar_abs);
   GRAI_SmcPosLiqStep(g_grai_smc_cfg.pivot_len);
   GRAI_SmcPublishSnap();
   if(prev_trend != g_grai_smc_ms.trend)
      GRAI_Log("SMC", StringFormat("trend %d -> %d txt=%s", prev_trend, g_grai_smc_ms.trend, g_grai_smc_ms.txt));
}

int GRAI_SmcTrend()
{
   return g_grai_smc_snap.trend;
}

bool GRAI_SmcReady()
{
   return g_grai_smc_snap.ready;
}

// Opposite unmitigated OB blocks fighting entries (Pine OB used as context).
bool GRAI_SmcObBlocksCmd(const int cmd)
{
   if(!g_grai_smc_cfg.use_ob_filter)
      return false;
   if(cmd == OP_BUY && g_grai_smc_snap.has_bear_ob && !g_grai_smc_snap.bear_ob_mitigated)
   {
      // allow BUY only if price not deep inside bear OB body without bull trend — hard block if trend not bull
      if(g_grai_smc_snap.trend != 1)
         return true;
   }
   if(cmd == OP_SELL && g_grai_smc_snap.has_bull_ob && !g_grai_smc_snap.bull_ob_mitigated)
   {
      if(g_grai_smc_snap.trend != -1)
         return true;
   }
   return false;
}

bool GRAI_SmcAllowsCmd(const int cmd)
{
   if(!g_grai_smc_snap.ready || g_grai_smc_snap.trend == 0)
      return false;
   if(g_grai_smc_snap.trend == 1 && cmd != OP_BUY)
      return false;
   if(g_grai_smc_snap.trend == -1 && cmd != OP_SELL)
      return false;
   if(GRAI_SmcObBlocksCmd(cmd))
      return false;
   if(g_grai_smc_cfg.require_sweep)
   {
      // after CHoCH prefer a sweep flag on the path; soft: if last event was choch without later bos ok
      // hard require: need upsweep for buys or dnsweep for sells recently — use current bar flags OR bos txt
      if(cmd == OP_BUY && !(g_grai_smc_snap.upsweep || g_grai_smc_snap.txt == "bos" || g_grai_smc_snap.txt == "choch"))
         return false;
      if(cmd == OP_SELL && !(g_grai_smc_snap.dnsweep || g_grai_smc_snap.txt == "bos" || g_grai_smc_snap.txt == "choch"))
         return false;
   }
   if(g_grai_smc_cfg.use_liq_filter)
   {
      // block BUY right after bearish liquidity print on same bar
      if(cmd == OP_BUY && g_grai_smc_snap.liq_print_up)
         return false;
      if(cmd == OP_SELL && g_grai_smc_snap.liq_print_dn)
         return false;
   }
   // mapping confirm when available
   if(g_grai_smc_map_trend != 0 && g_grai_smc_map_trend != g_grai_smc_snap.trend)
      return false;
   return true;
}

string GRAI_SmcTrendStr()
{
   if(g_grai_smc_snap.trend == 1) return "BULL";
   if(g_grai_smc_snap.trend == -1) return "BEAR";
   return "FLAT";
}

#endif
