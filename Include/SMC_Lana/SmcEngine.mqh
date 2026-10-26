//+------------------------------------------------------------------+
//| SMC_Lana indicator engine — structure / OB / mapping / posLIQ     |
//| Port of pine/SMC_Lana.pine + GRAI SmcLana logic with draw events. |
//+------------------------------------------------------------------+
#ifndef SMC_LANA_ENGINE_MQH
#define SMC_LANA_ENGINE_MQH

#include "SmcTypes.mqh"
#include "SmcObjects.mqh"
#include "SmcAlert.mqh"
#include "SmcFvg.mqh"
#include "SmcSfp.mqh"
#include "SmcLiq.mqh"
#include "SmcMtf.mqh"

SmcIndConfig g_smc_cfg;
SmcMS        g_smc_ms;
SmcOB        g_smc_blob[SMC_IND_MAX_OB];
SmcOB        g_smc_brob[SMC_IND_MAX_OB];
int          g_smc_blob_n = 0;
int          g_smc_brob_n = 0;
SmcSnap      g_smc_snap;

SmcDrawMS    g_smc_bldw[SMC_IND_MAX_DRAW];
SmcDrawMS    g_smc_brdw[SMC_IND_MAX_DRAW];
int          g_smc_bldw_n = 0;
int          g_smc_brdw_n = 0;

double       g_smc_php[SMC_IND_MAX_PV];
int          g_smc_phn[SMC_IND_MAX_PV];
int          g_smc_php_n = 0;
double       g_smc_plp[SMC_IND_MAX_PV];
int          g_smc_pln[SMC_IND_MAX_PV];
int          g_smc_plp_n = 0;

double g_smc_up = 0.0, g_smc_dn = 0.0;
bool   g_smc_up_set = false, g_smc_dn_set = false;

double g_smc_map_up = 0.0, g_smc_map_dn = 0.0;
bool   g_smc_map_up_set = false, g_smc_map_dn_set = false;
int    g_smc_map_trend = 0;
int    g_smc_map_idx = 0;
SmcMapPt g_smc_map_pts[SMC_IND_MAX_MAP];
int      g_smc_map_pts_n = 0;
datetime g_smc_map_sum = 0;
datetime g_smc_map_project = 0;
double   g_smc_map_point = 0.0;

double g_smc_liq_up = 0.0, g_smc_liq_dn = 0.0;
bool   g_smc_liq_up_allow = true, g_smc_liq_dn_allow = true;

// Sweep-area timer (Pine lc)
bool g_smc_lc_start = false;
int  g_smc_lc_count = 0;

// Buyside / sellside
SmcSide g_smc_buyside[SMC_IND_MAX_SIDE];
SmcSide g_smc_sellside[SMC_IND_MAX_SIDE];
int     g_smc_buyside_n = 0;
int     g_smc_sellside_n = 0;

MqlRates g_smc_rates[];
int      g_smc_rates_n = 0;
int      g_smc_bar_abs = 0;
bool     g_smc_warmed = false;
datetime g_smc_last_bar = 0;

// Time lookup for abs bar → datetime (built during warmup)
datetime g_smc_times[];
int      g_smc_times_n = 0;

datetime SmcTimeAtAbs(const int abs_bar)
{
   if(abs_bar <= 0 || abs_bar > g_smc_times_n)
      return 0;
   return g_smc_times[abs_bar - 1];
}

void SmcConfigDefaults(SmcIndConfig &c)
{
   ZeroMemory(c);
   c.window_limit    = true;
   c.mswindow        = 5000;
   c.show_swing      = true;
   c.swing_limit     = 100;
   c.swing_up        = C'8,153,129';
   c.swing_dn        = C'242,54,69';
   c.show_internal   = false;
   c.intern_up       = clrDodgerBlue;
   c.intern_dn       = clrPurple;
   c.show_mapping    = false;
   c.mapping_css     = clrSilver;
   c.candle_css      = false;
   c.show_pd_zone    = false;
   c.zone_len        = 20;
   c.fib_css         = C'251,192,45';
   c.adjusted_points = true;
   c.pivot_len       = 5;
   c.show_hl         = false;
   c.build_sweep     = true;
   c.show_bubbles    = true;

   c.ob_show         = true;
   c.ob_keep         = 5;
   c.ob_up           = C'8,153,129';
   c.ob_dn           = C'242,54,69';
   c.ob_show_activity = true;
   c.ob_act_up       = C'8,153,129';
   c.ob_act_dn       = C'242,54,69';
   c.ob_show_breakers = false;
   c.bb_up           = C'8,153,129';
   c.bb_dn           = C'242,54,69';
   c.ob_length_mode  = true;
   c.ob_len          = 5;
   c.ob_miti         = SMC_MITI_CLOSE;
   c.show_metric     = true;
   c.show_midline    = true;
   c.hide_overlap    = true;

   c.sfp_show        = true;
   c.sfp_css         = clrWhite;
   c.sfp_show_level  = true;
   c.sfp_fill        = true;

   c.show_side       = false;
   c.side_as_area    = true;
   c.buyside_css     = C'0,153,51';
   c.sellside_css    = C'204,51,0';
   c.show_sweep_zone = false;
   c.zone_thresh     = 10;
   c.sweep_up        = C'8,153,129';
   c.sweep_dn        = C'242,54,69';

   c.lvl_daily = c.lvl_weekly = c.lvl_monthly = c.lvl_quarterly = c.lvl_yearly = false;
   c.css_d = c.css_w = c.css_m = c.css_q = c.css_y = clrDodgerBlue;

   c.show_fvg = true;
   c.fvg_keep = 10;
   c.fvg_up   = C'8,153,129';
   c.fvg_dn   = C'242,54,69';

   c.alert_dir = SMC_ALERT_BOTH;
}

void SmcDrawUnshift(SmcDrawMS &arr[], int &n, const SmcDrawMS &d)
{
   for(int i = MathMin(n, SMC_IND_MAX_DRAW - 1); i > 0; i--)
      arr[i] = arr[i - 1];
   arr[0] = d;
   arr[0].used = true;
   if(n < SMC_IND_MAX_DRAW)
      n++;
}

void SmcPushDraw(const bool bull, const datetime t, const double y,
                 const string txt, const color css, const ENUM_LINE_STYLE st)
{
   SmcDrawMS d;
   ZeroMemory(d);
   d.used = true;
   d.t1 = t;
   d.t2 = t;
   d.y = y;
   d.txt = txt;
   d.css = css;
   d.style = st;
   d.bull = bull;
   if(bull)
      SmcDrawUnshift(g_smc_bldw, g_smc_bldw_n, d);
   else
      SmcDrawUnshift(g_smc_brdw, g_smc_brdw_n, d);
}

void SmcExtendHead(const bool bull, const datetime t2, const string txt,
                   const ENUM_LINE_STYLE st)
{
   if(bull && g_smc_bldw_n > 0)
   {
      g_smc_bldw[0].t2 = t2;
      if(txt != "")
         g_smc_bldw[0].txt = txt;
      g_smc_bldw[0].style = st;
   }
   else if(!bull && g_smc_brdw_n > 0)
   {
      g_smc_brdw[0].t2 = t2;
      if(txt != "")
         g_smc_brdw[0].txt = txt;
      g_smc_brdw[0].style = st;
   }
}

void SmcResetEngine()
{
   ZeroMemory(g_smc_ms);
   g_smc_ms.txt = "";
   g_smc_blob_n = g_smc_brob_n = 0;
   g_smc_bldw_n = g_smc_brdw_n = 0;
   g_smc_php_n = g_smc_plp_n = 0;
   g_smc_up_set = g_smc_dn_set = false;
   g_smc_map_up_set = g_smc_map_dn_set = false;
   g_smc_map_trend = 0;
   g_smc_map_pts_n = 0;
   g_smc_liq_up_allow = g_smc_liq_dn_allow = true;
   g_smc_buyside_n = g_smc_sellside_n = 0;
   g_smc_lc_start = false;
   g_smc_lc_count = 0;
   g_smc_warmed = false;
   g_smc_bar_abs = 0;
   ZeroMemory(g_smc_snap);
   g_smc_snap.txt = "";
   g_smc_snap.last_event = "";
}

double SmcATR(const int shift, const int period)
{
   if(g_smc_rates_n <= shift + period)
      return 0.0;
   double sum = 0.0;
   for(int i = shift; i < shift + period; i++)
   {
      double tr = g_smc_rates[i].high - g_smc_rates[i].low;
      if(i + 1 < g_smc_rates_n)
      {
         double a = MathAbs(g_smc_rates[i].high - g_smc_rates[i + 1].close);
         double b = MathAbs(g_smc_rates[i].low  - g_smc_rates[i + 1].close);
         tr = MathMax(tr, MathMax(a, b));
      }
      sum += tr;
   }
   return sum / (double)period;
}

bool SmcPivotHigh(const int left, const int right, const int center_shift, double &out_px)
{
   if(center_shift - right < 0 || center_shift + left >= g_smc_rates_n)
      return false;
   double c = g_smc_rates[center_shift].high;
   for(int i = 1; i <= left; i++)
      if(g_smc_rates[center_shift + i].high >= c)
         return false;
   for(int i = 1; i <= right; i++)
      if(g_smc_rates[center_shift - i].high > c)
         return false;
   out_px = c;
   return true;
}

bool SmcPivotLow(const int left, const int right, const int center_shift, double &out_px)
{
   if(center_shift - right < 0 || center_shift + left >= g_smc_rates_n)
      return false;
   double c = g_smc_rates[center_shift].low;
   for(int i = 1; i <= left; i++)
      if(g_smc_rates[center_shift + i].low <= c)
         return false;
   for(int i = 1; i <= right; i++)
      if(g_smc_rates[center_shift - i].low < c)
         return false;
   out_px = c;
   return true;
}

void SmcPhpUnshift(const double px, const int abs_bar)
{
   for(int i = MathMin(g_smc_php_n, SMC_IND_MAX_PV - 1); i > 0; i--)
   {
      g_smc_php[i] = g_smc_php[i - 1];
      g_smc_phn[i] = g_smc_phn[i - 1];
   }
   g_smc_php[0] = px;
   g_smc_phn[0] = abs_bar;
   if(g_smc_php_n < SMC_IND_MAX_PV)
      g_smc_php_n++;
}

void SmcPlpUnshift(const double px, const int abs_bar)
{
   for(int i = MathMin(g_smc_plp_n, SMC_IND_MAX_PV - 1); i > 0; i--)
   {
      g_smc_plp[i] = g_smc_plp[i - 1];
      g_smc_pln[i] = g_smc_pln[i - 1];
   }
   g_smc_plp[0] = px;
   g_smc_pln[0] = abs_bar;
   if(g_smc_plp_n < SMC_IND_MAX_PV)
      g_smc_plp_n++;
}

int SmcFind(const bool use_max, const bool sweep, const bool useob, const int cur_abs)
{
   int anchor = sweep ? g_smc_ms.xloc : g_smc_ms.loc;
   int span = cur_abs - anchor;
   if(span < 0)
      span = 0;
   double minv = 1.0e100;
   double maxv = 0.0;
   int idx = 0;
   int lim = span;
   if(!sweep && span - 1 > 0)
      lim = span - 1;
   for(int i = 0; i <= lim && i < g_smc_rates_n; i++)
   {
      if(use_max)
      {
         if(g_smc_rates[i].high >= maxv)
         {
            maxv = g_smc_rates[i].high;
            minv = g_smc_rates[i].low;
            idx = i;
         }
      }
      else
      {
         if(g_smc_rates[i].low <= minv)
         {
            minv = g_smc_rates[i].low;
            maxv = g_smc_rates[i].high;
            idx = i;
         }
      }
   }
   if(useob)
   {
      if(use_max && idx + 1 < g_smc_rates_n &&
         g_smc_rates[idx + 1].high > g_smc_rates[idx].high)
         idx = idx + 1;
      if(!use_max && idx + 1 < g_smc_rates_n &&
         g_smc_rates[idx + 1].low < g_smc_rates[idx].low)
         idx = idx + 1;
   }
   return idx;
}

void SmcObTrim(int &n)
{
   int keep = g_smc_cfg.ob_keep;
   if(keep < 0) keep = 0;
   if(n > keep) n = keep;
}

void SmcObUnshift(SmcOB &arr[], int &n, const SmcOB &ob)
{
   for(int i = MathMin(n, SMC_IND_MAX_OB - 1); i > 0; i--)
      arr[i] = arr[i - 1];
   arr[0] = ob;
   arr[0].used = true;
   if(n < SMC_IND_MAX_OB)
      n++;
   SmcObTrim(n);
}

void SmcFnOB(const bool bull, const double cords, const int idx)
{
   if(idx < 0 || idx >= g_smc_rates_n)
      return;
   SmcOB o;
   ZeroMemory(o);
   o.used = true;
   o.bull = bull;
   o.loc_time = g_smc_rates[idx].time;
   o.vol = (double)g_smc_rates[idx].tick_volume;
   o.dir = (g_smc_rates[idx].close > g_smc_rates[idx].open) ? 1 : -1;
   o.isbb = false;
   o.bl_pos = 1;
   o.br_pos = 1;
   if(bull)
   {
      o.top = cords;
      o.btm = g_smc_rates[idx].low;
      o.avg = 0.5 * (cords + o.btm);
      SmcObUnshift(g_smc_blob, g_smc_blob_n, o);
   }
   else
   {
      o.top = g_smc_rates[idx].high;
      o.btm = cords;
      o.avg = 0.5 * (cords + o.top);
      SmcObUnshift(g_smc_brob, g_smc_brob_n, o);
   }
}

bool SmcMitiHitBull(const SmcOB &o, const double open_, const double close_,
                    const double high_, const double low_)
{
   if(g_smc_cfg.ob_miti == SMC_MITI_WICK) return (low_ < o.btm);
   if(g_smc_cfg.ob_miti == SMC_MITI_AVG)  return (low_ < o.avg);
   return (MathMin(close_, open_) < o.btm);
}

bool SmcMitiHitBear(const SmcOB &o, const double open_, const double close_,
                    const double high_, const double low_)
{
   if(g_smc_cfg.ob_miti == SMC_MITI_WICK) return (high_ > o.top);
   if(g_smc_cfg.ob_miti == SMC_MITI_AVG)  return (high_ > o.avg);
   return (MathMax(close_, open_) > o.top);
}

void SmcSideUnshift(SmcSide &arr[], int &n, const SmcSide &s)
{
   for(int i = MathMin(n, SMC_IND_MAX_SIDE - 1); i > 0; i--)
      arr[i] = arr[i - 1];
   arr[0] = s;
   arr[0].used = true;
   if(n < SMC_IND_MAX_SIDE)
      n++;
}

void SmcMitigated()
{
   double o = g_smc_rates[0].open;
   double c = g_smc_rates[0].close;
   double h = g_smc_rates[0].high;
   double l = g_smc_rates[0].low;
   for(int i = 0; i < g_smc_blob_n; i++)
   {
      if(!g_smc_blob[i].used) continue;
      if(!g_smc_blob[i].isbb)
      {
         if(SmcMitiHitBull(g_smc_blob[i], o, c, h, l))
         {
            g_smc_blob[i].isbb = true;
            g_smc_blob[i].bb_time = g_smc_rates[0].time;
            g_smc_snap.last_event = "OB_MITI_BULL";
            SmcAlertFire(4, true, "OB Mitigated");
            if(!g_smc_cfg.ob_show_breakers)
            {
               for(int j = i; j < g_smc_blob_n - 1; j++)
                  g_smc_blob[j] = g_smc_blob[j + 1];
               g_smc_blob_n--;
               i--;
            }
         }
      }
      else
      {
         bool kill = (g_smc_cfg.ob_miti == SMC_MITI_WICK) ? (h > g_smc_blob[i].top)
                     : (g_smc_cfg.ob_miti == SMC_MITI_AVG) ? (h > g_smc_blob[i].avg)
                     : (MathMax(c, o) > g_smc_blob[i].top);
         if(kill)
         {
            for(int j = i; j < g_smc_blob_n - 1; j++)
               g_smc_blob[j] = g_smc_blob[j + 1];
            g_smc_blob_n--;
            i--;
         }
      }
   }
   for(int i = 0; i < g_smc_brob_n; i++)
   {
      if(!g_smc_brob[i].used) continue;
      if(!g_smc_brob[i].isbb)
      {
         if(SmcMitiHitBear(g_smc_brob[i], o, c, h, l))
         {
            g_smc_brob[i].isbb = true;
            g_smc_brob[i].bb_time = g_smc_rates[0].time;
            g_smc_snap.last_event = "OB_MITI_BEAR";
            SmcAlertFire(4, false, "OB Mitigated");
            if(!g_smc_cfg.ob_show_breakers)
            {
               for(int j = i; j < g_smc_brob_n - 1; j++)
                  g_smc_brob[j] = g_smc_brob[j + 1];
               g_smc_brob_n--;
               i--;
            }
         }
      }
      else
      {
         bool kill = (g_smc_cfg.ob_miti == SMC_MITI_WICK) ? (l < g_smc_brob[i].btm)
                     : (g_smc_cfg.ob_miti == SMC_MITI_AVG) ? (l < g_smc_brob[i].avg)
                     : (MathMin(c, o) < g_smc_brob[i].btm);
         if(kill)
         {
            for(int j = i; j < g_smc_brob_n - 1; j++)
               g_smc_brob[j] = g_smc_brob[j + 1];
            g_smc_brob_n--;
            i--;
         }
      }
   }
}

void SmcOverlapOb()
{
   if(!g_smc_cfg.hide_overlap)
      return;
   if(g_smc_blob_n > 1)
   {
      SmcOB cur = g_smc_blob[0];
      for(int i = g_smc_blob_n - 1; i >= 1; i--)
      {
         SmcOB s = g_smc_blob[i];
         bool hit =
            (s.btm > cur.btm && s.btm < cur.top) ||
            (s.top < cur.top && s.btm > cur.btm) ||
            (s.top > cur.top && s.btm < cur.btm) ||
            (s.top < cur.top && s.top > cur.btm);
         if(hit)
         {
            for(int j = i; j < g_smc_blob_n - 1; j++)
               g_smc_blob[j] = g_smc_blob[j + 1];
            g_smc_blob_n--;
         }
      }
   }
   if(g_smc_brob_n > 1)
   {
      SmcOB cur = g_smc_brob[0];
      for(int i = g_smc_brob_n - 1; i >= 1; i--)
      {
         SmcOB s = g_smc_brob[i];
         bool hit =
            (s.btm > cur.btm && s.btm < cur.top) ||
            (s.top < cur.top && s.btm > cur.btm) ||
            (s.top > cur.top && s.btm < cur.btm) ||
            (s.top < cur.top && s.top > cur.btm);
         if(hit)
         {
            for(int j = i; j < g_smc_brob_n - 1; j++)
               g_smc_brob[j] = g_smc_brob[j + 1];
            g_smc_brob_n--;
         }
      }
   }
}

int SmcIDMIDX(const bool use_max, const int loc_abs, const int cur_abs)
{
   double minv = 1.0e100, maxv = 0.0;
   int idx = 0;
   int span = cur_abs - loc_abs;
   if(span < 0) span = 0;
   for(int i = 0; i <= span && i < g_smc_rates_n; i++)
   {
      if(use_max)
      {
         if(g_smc_rates[i].high >= maxv)
         {
            maxv = g_smc_rates[i].high;
            idx = i;
         }
      }
      else
      {
         if(g_smc_rates[i].low <= minv)
         {
            minv = g_smc_rates[i].low;
            idx = i;
         }
      }
   }
   return idx;
}

void SmcMappingStep(const int cur_abs)
{
   double hi = g_smc_rates[0].high;
   double lo = g_smc_rates[0].low;
   datetime t = g_smc_rates[0].time;
   if(!g_smc_map_up_set)
   {
      g_smc_map_up = hi;
      g_smc_map_up_set = true;
      g_smc_map_idx = cur_abs;
   }
   if(!g_smc_map_dn_set)
   {
      g_smc_map_dn = lo;
      g_smc_map_dn_set = true;
      g_smc_map_idx = cur_abs;
   }
   if(hi > g_smc_map_up)
   {
      if(g_smc_map_trend == -1)
      {
         int id = SmcIDMIDX(false, g_smc_map_idx, cur_abs);
         if(g_smc_map_pts_n < SMC_IND_MAX_MAP && id < g_smc_rates_n)
         {
            for(int i = MathMin(g_smc_map_pts_n, SMC_IND_MAX_MAP - 1); i > 0; i--)
               g_smc_map_pts[i] = g_smc_map_pts[i - 1];
            g_smc_map_pts[0].used = true;
            g_smc_map_pts[0].t = g_smc_rates[id].time;
            g_smc_map_pts[0].y = g_smc_rates[id].low;
            if(g_smc_map_pts_n < SMC_IND_MAX_MAP)
               g_smc_map_pts_n++;
            g_smc_map_sum = g_smc_rates[id].time;
            g_smc_map_point = g_smc_rates[id].low;
         }
         g_smc_map_idx = cur_abs;
      }
      g_smc_map_up = hi;
      g_smc_map_dn = lo;
      g_smc_map_project = t;
      g_smc_map_trend = 1;
   }
   if(lo < g_smc_map_dn)
   {
      if(g_smc_map_trend == 1)
      {
         int id = SmcIDMIDX(true, g_smc_map_idx, cur_abs);
         if(g_smc_map_pts_n < SMC_IND_MAX_MAP && id < g_smc_rates_n)
         {
            for(int i = MathMin(g_smc_map_pts_n, SMC_IND_MAX_MAP - 1); i > 0; i--)
               g_smc_map_pts[i] = g_smc_map_pts[i - 1];
            g_smc_map_pts[0].used = true;
            g_smc_map_pts[0].t = g_smc_rates[id].time;
            g_smc_map_pts[0].y = g_smc_rates[id].high;
            if(g_smc_map_pts_n < SMC_IND_MAX_MAP)
               g_smc_map_pts_n++;
            g_smc_map_sum = g_smc_rates[id].time;
            g_smc_map_point = g_smc_rates[id].high;
         }
         g_smc_map_idx = cur_abs;
      }
      g_smc_map_up = hi;
      g_smc_map_dn = lo;
      g_smc_map_project = t;
      g_smc_map_trend = -1;
   }
}

void SmcPosLiqStep(const int mslen)
{
   double ph = 0.0, pl = 0.0;
   bool has_ph = SmcPivotHigh(mslen, mslen, mslen, ph);
   bool has_pl = SmcPivotLow(mslen, mslen, mslen, pl);
   if(has_ph) g_smc_liq_up = ph;
   if(has_pl) g_smc_liq_dn = pl;

   g_smc_snap.liq_print_up = false;
   g_smc_snap.liq_print_dn = false;
   double hi = g_smc_rates[0].high;
   double lo = g_smc_rates[0].low;
   double cl = g_smc_rates[0].close;
   double hi1 = (g_smc_rates_n > 1) ? g_smc_rates[1].high : hi;
   double lo1 = (g_smc_rates_n > 1) ? g_smc_rates[1].low : lo;

   if(g_smc_liq_up > 0.0 && hi > g_smc_liq_up && cl < g_smc_liq_up &&
      g_smc_liq_up_allow && hi > hi1)
   {
      g_smc_liq_up_allow = false;
      g_smc_snap.liq_print_up = true;
      g_smc_snap.last_event = "LIQ_PRINT_BEAR";
      SmcAlertFire(10, false, "Liquidity Print");
   }
   if(g_smc_liq_dn > 0.0 && lo < g_smc_liq_dn && cl > g_smc_liq_dn &&
      g_smc_liq_dn_allow && lo < lo1)
   {
      g_smc_liq_dn_allow = false;
      g_smc_snap.liq_print_dn = true;
      g_smc_snap.last_event = "LIQ_PRINT_BULL";
      SmcAlertFire(10, true, "Liquidity Print");
   }
   if(has_ph && !g_smc_liq_up_allow) g_smc_liq_up_allow = true;
   if(has_pl && !g_smc_liq_dn_allow) g_smc_liq_dn_allow = true;
}

void SmcEvent(const string ev, const int trend)
{
   g_smc_snap.last_event = ev;
}

void SmcPushSide(const bool buyside, const int id, const double atr)
{
   if(id < 0 || id >= g_smc_rates_n)
      return;
   SmcSide s;
   ZeroMemory(s);
   s.used = true;
   s.loc = g_smc_rates[id].time;
   s.vol = (double)g_smc_rates[id].tick_volume;
   if(buyside)
   {
      s.top = (g_smc_rates[id].low + atr) < g_smc_rates[id].high
              ? (g_smc_rates[id].low + atr) : g_smc_rates[id].high;
      s.btm = g_smc_rates[id].low;
      s.css = g_smc_cfg.buyside_css;
      s.txt = "Buy Side";
      SmcSideUnshift(g_smc_buyside, g_smc_buyside_n, s);
   }
   else
   {
      s.btm = (g_smc_rates[id].high - atr) > g_smc_rates[id].low
              ? (g_smc_rates[id].high - atr) : g_smc_rates[id].low;
      s.top = g_smc_rates[id].high;
      s.css = g_smc_cfg.sellside_css;
      s.txt = "Sell Side";
      SmcSideUnshift(g_smc_sellside, g_smc_sellside_n, s);
   }
}

void SmcStructureStep(const int cur_abs, const bool draw)
{
   const int mslen = g_smc_cfg.pivot_len;
   double hi = g_smc_rates[0].high;
   double lo = g_smc_rates[0].low;
   double cl = g_smc_rates[0].close;
   double op = g_smc_rates[0].open;
   double cl1 = (g_smc_rates_n > 1) ? g_smc_rates[1].close : cl;
   double op1 = (g_smc_rates_n > 1) ? g_smc_rates[1].open : op;
   datetime tnow = g_smc_rates[0].time;

   double atr = SmcATR(0, SMC_IND_ATR_LEN);
   if(atr <= 0.0) atr = hi - lo;
   // Pine: atr / (5/len)
   double atr_ob = atr;
   if(g_smc_cfg.ob_len > 0)
      atr_ob = atr / (5.0 / (double)g_smc_cfg.ob_len);

   int idbull = SmcFind(false, false, true, cur_abs);
   int idbear = SmcFind(true, false, true, cur_abs);
   double btmP, topP;
   if(g_smc_cfg.ob_length_mode && idbear < g_smc_rates_n)
   {
      double atr_b = SmcATR(idbear, SMC_IND_ATR_LEN);
      if(atr_b <= 0.0) atr_b = atr_ob;
      else if(g_smc_cfg.ob_len > 0) atr_b = atr_b / (5.0 / (double)g_smc_cfg.ob_len);
      btmP = (g_smc_rates[idbear].high - atr_b) < g_smc_rates[idbear].low
             ? g_smc_rates[idbear].low
             : (g_smc_rates[idbear].high - atr_b);
   }
   else
      btmP = (idbear < g_smc_rates_n) ? g_smc_rates[idbear].low : lo;

   if(g_smc_cfg.ob_length_mode && idbull < g_smc_rates_n)
   {
      double atr_u = SmcATR(idbull, SMC_IND_ATR_LEN);
      if(atr_u <= 0.0) atr_u = atr_ob;
      else if(g_smc_cfg.ob_len > 0) atr_u = atr_u / (5.0 / (double)g_smc_cfg.ob_len);
      topP = (g_smc_rates[idbull].low + atr_u) > g_smc_rates[idbull].high
             ? g_smc_rates[idbull].high
             : (g_smc_rates[idbull].low + atr_u);
   }
   else
      topP = (idbull < g_smc_rates_n) ? g_smc_rates[idbull].high : hi;

   double ph = 0.0, pl = 0.0;
   if(SmcPivotHigh(mslen, mslen, mslen, ph))
      SmcPhpUnshift(ph, cur_abs - mslen);
   if(SmcPivotLow(mslen, mslen, mslen, pl))
      SmcPlpUnshift(pl, cur_abs - mslen);

   if(g_smc_php_n > 0 && hi > g_smc_php[0]) g_smc_php_n = 0;
   if(g_smc_plp_n > 0 && lo < g_smc_plp[0]) g_smc_plp_n = 0;

   bool crossup = false, crossdn = false;
   if(!g_smc_up_set) { g_smc_up = hi; g_smc_up_set = true; }
   if(!g_smc_dn_set) { g_smc_dn = lo; g_smc_dn_set = true; }
   if(hi > g_smc_up) { g_smc_up = hi; g_smc_dn = lo; crossup = true; }
   if(lo < g_smc_dn) { g_smc_up = hi; g_smc_dn = lo; crossdn = true; }

   g_smc_ms.upsweep = false;
   g_smc_ms.dnsweep = false;

   color cup = g_smc_cfg.swing_up;
   color cdn = g_smc_cfg.swing_dn;

   if(g_smc_ms.start == 0)
   {
      g_smc_ms.start = 1;
      g_smc_ms.bos = hi;
      g_smc_ms.choch = lo;
      g_smc_ms.bos_valid = true;
      g_smc_ms.choch_valid = true;
      g_smc_ms.loc = cur_abs;
      g_smc_ms.temp = cur_abs;
      g_smc_ms.xloc = cur_abs;
      g_smc_ms.trend = 0;
      g_smc_ms.main_px = hi;
      if(draw)
      {
         SmcPushDraw(true,  tnow, hi, "CHoCH", cup, STYLE_DASH);
         SmcPushDraw(false, tnow, lo, "CHoCH", cdn, STYLE_DASH);
      }
      return;
   }

   if(g_smc_ms.start == 1)
   {
      if(g_smc_cfg.build_sweep && g_smc_ms.choch_valid &&
         lo <= g_smc_ms.choch && cl >= g_smc_ms.choch)
      {
         g_smc_ms.dnsweep = true;
         g_smc_ms.choch = lo;
         g_smc_ms.xloc = cur_abs;
         SmcEvent("CHoCH_SWEEP_BEAR", -1);
         SmcAlertFire(2, false, "CHoCH Sweep");
         if(draw)
         {
            SmcExtendHead(false, tnow, "x", STYLE_DOT);
            SmcPushDraw(false, tnow, lo, "CHoCH", cdn, STYLE_DASH);
         }
      }
      else if(g_smc_cfg.build_sweep && g_smc_ms.bos_valid &&
              hi >= g_smc_ms.bos && cl <= g_smc_ms.bos)
      {
         g_smc_ms.upsweep = true;
         g_smc_ms.bos = hi;
         g_smc_ms.xloc = cur_abs;
         SmcEvent("CHoCH_SWEEP_BULL", 1);
         SmcAlertFire(2, true, "CHoCH Sweep");
         if(draw)
         {
            SmcExtendHead(true, tnow, "x", STYLE_DOT);
            SmcPushDraw(true, tnow, hi, "CHoCH", cup, STYLE_DASH);
         }
      }
      else if(g_smc_ms.choch_valid && cl <= g_smc_ms.choch)
      {
         g_smc_ms.txt = "choch";
         SmcFnOB(true, topP, idbull);
         g_smc_ms.trend = -1;
         g_smc_ms.choch = g_smc_ms.bos;
         g_smc_ms.choch_valid = true;
         g_smc_ms.bos_valid = false;
         g_smc_ms.start = 2;
         g_smc_ms.loc = cur_abs;
         g_smc_ms.main_px = lo;
         g_smc_ms.temp = cur_abs;
         g_smc_ms.xloc = cur_abs;
         g_smc_lc_start = true;
         g_smc_lc_count = 0;
         SmcEvent("CHoCH_BEAR", -1);
         SmcAlertFire(0, false, "CHoCH");
         if(draw)
            SmcExtendHead(false, tnow, "CHoCH", STYLE_SOLID);
      }
      else if(g_smc_ms.bos_valid && cl >= g_smc_ms.bos)
      {
         g_smc_ms.txt = "choch";
         SmcFnOB(false, btmP, idbear);
         g_smc_ms.trend = 1;
         g_smc_ms.bos_valid = false;
         g_smc_ms.start = 2;
         g_smc_ms.loc = cur_abs;
         g_smc_ms.main_px = hi;
         g_smc_ms.temp = cur_abs;
         g_smc_ms.xloc = cur_abs;
         g_smc_lc_start = true;
         g_smc_lc_count = 0;
         SmcEvent("CHoCH_BULL", 1);
         SmcAlertFire(0, true, "CHoCH");
         if(draw)
            SmcExtendHead(true, tnow, "CHoCH", STYLE_SOLID);
      }
      return;
   }

   // start == 2
   if(g_smc_ms.trend == -1)
   {
      if(lo <= g_smc_ms.main_px)
      {
         g_smc_ms.main_px = lo;
         g_smc_ms.temp = cur_abs;
      }
      if(g_smc_cfg.adjusted_points && (cur_abs % (mslen * 2) == 0) &&
         g_smc_ms.bos_valid && g_smc_php_n > 0)
      {
         if(g_smc_php[0] < g_smc_ms.choch)
         {
            g_smc_ms.choch = g_smc_php[0];
            g_smc_ms.loc = g_smc_phn[0];
            g_smc_ms.xloc = g_smc_phn[0];
            g_smc_ms.temp = g_smc_phn[0];
         }
      }
      if(!g_smc_ms.bos_valid)
      {
         if(crossup && cl > op && cl1 > op1)
         {
            g_smc_ms.bos = g_smc_ms.main_px;
            g_smc_ms.bos_valid = true;
            g_smc_ms.loc = g_smc_ms.temp;
            g_smc_ms.xloc = g_smc_ms.loc;
            if(draw)
               SmcPushDraw(false, SmcTimeAtAbs(g_smc_ms.loc), g_smc_ms.bos, "BOS", cdn, STYLE_DASH);
         }
      }
      if(g_smc_cfg.build_sweep && g_smc_ms.bos_valid &&
         lo <= g_smc_ms.bos && cl >= g_smc_ms.bos)
      {
         g_smc_ms.dnsweep = true;
         g_smc_ms.bos = lo;
         g_smc_ms.xloc = cur_abs;
         SmcEvent("BOS_SWEEP_BEAR", -1);
         SmcAlertFire(3, false, "BOS Sweep");
         if(draw)
         {
            SmcExtendHead(false, tnow, "x", STYLE_DOT);
            SmcPushDraw(false, tnow, lo, "BOS", cdn, STYLE_DASH);
         }
      }
      else if(g_smc_ms.bos_valid && cl <= g_smc_ms.bos)
      {
         g_smc_ms.txt = "bos";
         g_smc_ms.zz = g_smc_ms.bos;
         g_smc_ms.zn = cur_abs;
         SmcFnOB(false, btmP, idbear);
         int id = SmcFind(true, false, false, cur_abs);
         g_smc_ms.xloc = cur_abs;
         g_smc_ms.bos_valid = false;
         g_smc_ms.choch = g_smc_rates[id].high;
         g_smc_ms.choch_valid = true;
         g_smc_ms.loc = cur_abs - id;
         g_smc_lc_start = true;
         g_smc_lc_count = 0;
         SmcEvent("BOS_BEAR", -1);
         SmcAlertFire(1, false, "BOS");
         if(draw)
         {
            SmcExtendHead(false, tnow, "BOS", STYLE_SOLID);
            SmcPushDraw(true, tnow, g_smc_ms.choch, "CHoCH", cup, STYLE_DASH);
         }
         if(g_smc_cfg.show_side)
            SmcPushSide(false, SmcFind(true, true, true, cur_abs), atr_ob);
      }
      else if(g_smc_cfg.build_sweep && g_smc_ms.choch_valid &&
              hi >= g_smc_ms.choch && cl <= g_smc_ms.choch)
      {
         g_smc_ms.upsweep = true;
         g_smc_ms.choch = hi;
         g_smc_ms.xloc = cur_abs;
         SmcEvent("CHoCH_SWEEP_BULL", 1);
         SmcAlertFire(2, true, "CHoCH Sweep");
         if(draw)
         {
            SmcExtendHead(true, tnow, "x", STYLE_DOT);
            SmcPushDraw(true, tnow, hi, "CHoCH", cup, STYLE_DASH);
         }
      }
      else if(g_smc_ms.choch_valid && cl >= g_smc_ms.choch)
      {
         g_smc_ms.txt = "choch";
         g_smc_ms.zz = g_smc_ms.choch;
         g_smc_ms.zn = cur_abs;
         SmcFnOB(true, topP, idbull);
         int id = SmcFind(false, false, false, cur_abs);
         if(!g_smc_ms.bos_valid)
            g_smc_ms.choch = g_smc_rates[id].low;
         else
            g_smc_ms.choch = g_smc_ms.bos;
         g_smc_ms.choch_valid = true;
         g_smc_ms.bos_valid = false;
         g_smc_ms.main_px = hi;
         g_smc_ms.trend = 1;
         g_smc_ms.loc = cur_abs;
         g_smc_ms.xloc = cur_abs;
         g_smc_ms.temp = cur_abs;
         g_smc_lc_start = true;
         g_smc_lc_count = 0;
         SmcEvent("CHoCH_BULL", 1);
         SmcAlertFire(0, true, "CHoCH");
         if(draw)
         {
            SmcExtendHead(true, tnow, "CHoCH", STYLE_SOLID);
            if(g_smc_bldw_n > 0)
            {
               g_smc_bldw[0].y = g_smc_ms.choch;
               g_smc_bldw[0].t2 = tnow;
            }
         }
         if(g_smc_cfg.show_side)
            SmcPushSide(true, SmcFind(false, true, true, cur_abs), atr_ob);
      }
   }
   else if(g_smc_ms.trend == 1)
   {
      if(hi >= g_smc_ms.main_px)
      {
         g_smc_ms.main_px = hi;
         g_smc_ms.temp = cur_abs;
      }
      if(!g_smc_ms.bos_valid)
      {
         if(crossdn && cl < op && cl1 < op1)
         {
            g_smc_ms.bos = g_smc_ms.main_px;
            g_smc_ms.bos_valid = true;
            g_smc_ms.loc = g_smc_ms.temp;
            g_smc_ms.xloc = g_smc_ms.loc;
            if(draw)
               SmcPushDraw(true, SmcTimeAtAbs(g_smc_ms.loc), g_smc_ms.bos, "BOS", cup, STYLE_DASH);
         }
      }
      if(g_smc_cfg.adjusted_points && (cur_abs % (mslen * 2) == 0) &&
         g_smc_ms.bos_valid && g_smc_plp_n > 0)
      {
         if(g_smc_plp[0] > g_smc_ms.choch)
         {
            g_smc_ms.choch = g_smc_plp[0];
            g_smc_ms.loc = g_smc_pln[0];
            g_smc_ms.xloc = g_smc_pln[0];
            g_smc_ms.temp = g_smc_pln[0];
         }
      }
      if(g_smc_cfg.build_sweep && g_smc_ms.bos_valid &&
         hi >= g_smc_ms.bos && cl <= g_smc_ms.bos)
      {
         g_smc_ms.upsweep = true;
         g_smc_ms.bos = hi;
         g_smc_ms.xloc = cur_abs;
         SmcEvent("BOS_SWEEP_BULL", 1);
         SmcAlertFire(3, true, "BOS Sweep");
         if(draw)
         {
            SmcExtendHead(true, tnow, "x", STYLE_DOT);
            SmcPushDraw(true, tnow, hi, "BOS", cup, STYLE_DASH);
         }
      }
      else if(g_smc_ms.bos_valid && cl >= g_smc_ms.bos)
      {
         g_smc_ms.txt = "bos";
         g_smc_ms.zz = g_smc_ms.bos;
         g_smc_ms.zn = cur_abs;
         SmcFnOB(true, topP, idbull);
         int id = SmcFind(false, false, false, cur_abs);
         g_smc_ms.xloc = cur_abs;
         g_smc_ms.bos_valid = false;
         g_smc_ms.choch = g_smc_rates[id].low;
         g_smc_ms.choch_valid = true;
         g_smc_ms.loc = cur_abs - id;
         g_smc_lc_start = true;
         g_smc_lc_count = 0;
         SmcEvent("BOS_BULL", 1);
         SmcAlertFire(1, true, "BOS");
         if(draw)
         {
            SmcExtendHead(true, tnow, "BOS", STYLE_SOLID);
            SmcPushDraw(false, tnow, g_smc_ms.choch, "CHoCH", cdn, STYLE_DASH);
         }
         if(g_smc_cfg.show_side)
            SmcPushSide(true, SmcFind(false, true, true, cur_abs), atr_ob);
      }
      else if(g_smc_cfg.build_sweep && g_smc_ms.choch_valid &&
              lo <= g_smc_ms.choch && cl >= g_smc_ms.choch)
      {
         g_smc_ms.dnsweep = true;
         g_smc_ms.choch = lo;
         g_smc_ms.xloc = cur_abs;
         SmcEvent("CHoCH_SWEEP_BEAR", -1);
         SmcAlertFire(2, false, "CHoCH Sweep");
         if(draw)
         {
            SmcExtendHead(false, tnow, "x", STYLE_DOT);
            SmcPushDraw(false, tnow, lo, "CHoCH", cdn, STYLE_DASH);
         }
      }
      else if(g_smc_ms.choch_valid && cl <= g_smc_ms.choch)
      {
         g_smc_ms.txt = "choch";
         g_smc_ms.zz = g_smc_ms.choch;
         g_smc_ms.zn = cur_abs;
         SmcFnOB(false, btmP, idbear);
         int id = SmcFind(true, false, false, cur_abs);
         if(!g_smc_ms.bos_valid)
            g_smc_ms.choch = g_smc_rates[id].high;
         else
            g_smc_ms.choch = g_smc_ms.bos;
         g_smc_ms.choch_valid = true;
         g_smc_ms.bos_valid = false;
         g_smc_ms.main_px = lo;
         g_smc_ms.trend = -1;
         g_smc_ms.loc = cur_abs;
         g_smc_ms.xloc = cur_abs;
         g_smc_ms.temp = cur_abs;
         g_smc_lc_start = true;
         g_smc_lc_count = 0;
         SmcEvent("CHoCH_BEAR", -1);
         SmcAlertFire(0, false, "CHoCH");
         if(draw)
         {
            SmcExtendHead(false, tnow, "CHoCH", STYLE_SOLID);
            if(g_smc_brdw_n > 0)
            {
               g_smc_brdw[0].y = g_smc_ms.choch;
               g_smc_brdw[0].t2 = tnow;
            }
         }
         if(g_smc_cfg.show_side)
            SmcPushSide(false, SmcFind(true, true, true, cur_abs), atr_ob);
      }
   }

   // Price inside OB
   if(g_smc_blob_n > 0 && lo < g_smc_blob[0].top)
      SmcAlertFire(5, true, "Price Inside OB");
   if(g_smc_brob_n > 0 && hi > g_smc_brob[0].btm)
      SmcAlertFire(5, false, "Price Inside OB");

   // Side mitigation
   if(g_smc_cfg.show_side)
   {
      if(g_smc_buyside_n > 0 && cl < g_smc_buyside[0].top)
      {
         for(int j = 0; j < g_smc_buyside_n - 1; j++)
            g_smc_buyside[j] = g_smc_buyside[j + 1];
         g_smc_buyside_n--;
      }
      if(g_smc_sellside_n > 0 && cl > g_smc_sellside[0].top)
      {
         for(int j = 0; j < g_smc_sellside_n - 1; j++)
            g_smc_sellside[j] = g_smc_sellside[j + 1];
         g_smc_sellside_n--;
      }
   }

   SmcMitigated();
   SmcOverlapOb();
}

void SmcPublishSnap()
{
   g_smc_snap.ready = (g_smc_ms.start >= 2 && g_smc_ms.trend != 0);
   g_smc_snap.trend = g_smc_ms.trend;
   g_smc_snap.txt = g_smc_ms.txt;
   g_smc_snap.bos = g_smc_ms.bos;
   g_smc_snap.choch = g_smc_ms.choch;
   g_smc_snap.bos_valid = g_smc_ms.bos_valid;
   g_smc_snap.choch_valid = g_smc_ms.choch_valid;
   g_smc_snap.upsweep = g_smc_ms.upsweep;
   g_smc_snap.dnsweep = g_smc_ms.dnsweep;
   g_smc_snap.map_trend = g_smc_map_trend;
   g_smc_snap.has_bull_ob = (g_smc_blob_n > 0);
   g_smc_snap.has_bear_ob = (g_smc_brob_n > 0);
}

bool SmcLoadRates(const int need)
{
   ArraySetAsSeries(g_smc_rates, true);
   int n = CopyRates(_Symbol, PERIOD_CURRENT, 0, need, g_smc_rates);
   g_smc_rates_n = (n > 0) ? n : 0;
   return (g_smc_rates_n >= g_smc_cfg.pivot_len * 2 + 10);
}

void SmcDrawStructure()
{
   if(!g_smc_cfg.show_swing)
      return;
   SmcObjDeleteKind("MS_");
   int lim = g_smc_cfg.swing_limit;
   datetime nowt = iTime(_Symbol, PERIOD_CURRENT, 0);
   int drawn = 0;
   for(int i = 0; i < g_smc_bldw_n && drawn < lim; i++)
   {
      if(!g_smc_bldw[i].used) continue;
      datetime t2 = (g_smc_bldw[i].t2 > 0) ? g_smc_bldw[i].t2 : nowt;
      string n = StringFormat("%sMS_BU_%d", SMC_IND_PREFIX, i);
      SmcObjTrend(n, g_smc_bldw[i].t1, g_smc_bldw[i].y, t2, g_smc_bldw[i].y,
                  g_smc_bldw[i].css, g_smc_bldw[i].style);
      string nl = StringFormat("%sMS_BUL_%d", SMC_IND_PREFIX, i);
      datetime mid = g_smc_bldw[i].t1 + (t2 - g_smc_bldw[i].t1) / 2;
      SmcObjText(nl, mid, g_smc_bldw[i].y, g_smc_bldw[i].txt, g_smc_bldw[i].css, 7, ANCHOR_LOWER);
      if(g_smc_cfg.show_bubbles)
      {
         string nb = StringFormat("%sMS_BUB_%d", SMC_IND_PREFIX, i);
         SmcObjArrow(nb, g_smc_bldw[i].t1, g_smc_bldw[i].y, g_smc_bldw[i].css, 159);
      }
      drawn++;
   }
   drawn = 0;
   for(int i = 0; i < g_smc_brdw_n && drawn < lim; i++)
   {
      if(!g_smc_brdw[i].used) continue;
      datetime t2 = (g_smc_brdw[i].t2 > 0) ? g_smc_brdw[i].t2 : nowt;
      string n = StringFormat("%sMS_BE_%d", SMC_IND_PREFIX, i);
      SmcObjTrend(n, g_smc_brdw[i].t1, g_smc_brdw[i].y, t2, g_smc_brdw[i].y,
                  g_smc_brdw[i].css, g_smc_brdw[i].style);
      string nl = StringFormat("%sMS_BEL_%d", SMC_IND_PREFIX, i);
      datetime mid = g_smc_brdw[i].t1 + (t2 - g_smc_brdw[i].t1) / 2;
      SmcObjText(nl, mid, g_smc_brdw[i].y, g_smc_brdw[i].txt, g_smc_brdw[i].css, 7, ANCHOR_UPPER);
      if(g_smc_cfg.show_bubbles)
      {
         string nb = StringFormat("%sMS_BEB_%d", SMC_IND_PREFIX, i);
         SmcObjArrow(nb, g_smc_brdw[i].t1, g_smc_brdw[i].y, g_smc_brdw[i].css, 159);
      }
      drawn++;
   }
}

void SmcDrawOBs()
{
   SmcObjDeleteKind("OB_");
   if(!g_smc_cfg.ob_show)
      return;
   datetime t_now = iTime(_Symbol, PERIOD_CURRENT, 0);
   datetime t_ext = t_now + PeriodSeconds() * 20;
   for(int i = 0; i < g_smc_blob_n; i++)
   {
      if(!g_smc_blob[i].used) continue;
      color fill = g_smc_blob[i].isbb ? g_smc_cfg.bb_up : g_smc_cfg.ob_up;
      datetime t2 = g_smc_blob[i].isbb && g_smc_blob[i].bb_time > 0
                    ? g_smc_blob[i].bb_time : t_ext;
      if(!g_smc_blob[i].isbb) t2 = t_ext;
      string n = StringFormat("%sOB_BU_%d", SMC_IND_PREFIX, i);
      SmcObjRect(n, g_smc_blob[i].loc_time, g_smc_blob[i].top,
                 t2, g_smc_blob[i].btm, fill, fill, true);
      if(g_smc_cfg.show_midline)
      {
         string m = StringFormat("%sOB_BUM_%d", SMC_IND_PREFIX, i);
         SmcObjTrend(m, g_smc_blob[i].loc_time, g_smc_blob[i].avg,
                     t2, g_smc_blob[i].avg, g_smc_cfg.ob_act_up, STYLE_DOT);
      }
      if(g_smc_cfg.show_metric)
      {
         string l = StringFormat("%sOB_BUT_%d", SMC_IND_PREFIX, i);
         SmcObjText(l, t2, g_smc_blob[i].avg,
                    StringFormat("OB %.0f", g_smc_blob[i].vol), g_smc_cfg.ob_act_up, 7);
      }
      if(g_smc_blob[i].isbb && g_smc_cfg.ob_show_breakers)
      {
         string bb = StringFormat("%sOB_BUBB_%d", SMC_IND_PREFIX, i);
         SmcObjRect(bb, g_smc_blob[i].bb_time, g_smc_blob[i].top,
                    t_ext, g_smc_blob[i].btm, g_smc_cfg.bb_up, g_smc_cfg.ob_up, false);
      }
   }
   for(int i = 0; i < g_smc_brob_n; i++)
   {
      if(!g_smc_brob[i].used) continue;
      color fill = g_smc_brob[i].isbb ? g_smc_cfg.bb_dn : g_smc_cfg.ob_dn;
      datetime t2 = g_smc_brob[i].isbb && g_smc_brob[i].bb_time > 0
                    ? g_smc_brob[i].bb_time : t_ext;
      if(!g_smc_brob[i].isbb) t2 = t_ext;
      string n = StringFormat("%sOB_BE_%d", SMC_IND_PREFIX, i);
      SmcObjRect(n, g_smc_brob[i].loc_time, g_smc_brob[i].top,
                 t2, g_smc_brob[i].btm, fill, fill, true);
      if(g_smc_cfg.show_midline)
      {
         string m = StringFormat("%sOB_BEM_%d", SMC_IND_PREFIX, i);
         SmcObjTrend(m, g_smc_brob[i].loc_time, g_smc_brob[i].avg,
                     t2, g_smc_brob[i].avg, g_smc_cfg.ob_act_dn, STYLE_DOT);
      }
      if(g_smc_cfg.show_metric)
      {
         string l = StringFormat("%sOB_BET_%d", SMC_IND_PREFIX, i);
         SmcObjText(l, t2, g_smc_brob[i].avg,
                    StringFormat("OB %.0f", g_smc_brob[i].vol), g_smc_cfg.ob_act_dn, 7);
      }
   }
}

void SmcDrawMapping()
{
   SmcObjDeleteKind("MAP_");
   if(!g_smc_cfg.show_mapping)
      return;
   datetime t_now = iTime(_Symbol, PERIOD_CURRENT, 0);
   for(int i = 0; i + 1 < g_smc_map_pts_n; i++)
   {
      if(!g_smc_map_pts[i].used || !g_smc_map_pts[i + 1].used) continue;
      string n = StringFormat("%sMAP_P_%d", SMC_IND_PREFIX, i);
      SmcObjTrend(n, g_smc_map_pts[i + 1].t, g_smc_map_pts[i + 1].y,
                  g_smc_map_pts[i].t, g_smc_map_pts[i].y,
                  g_smc_cfg.mapping_css, STYLE_DASH);
   }
   if(g_smc_map_sum > 0 && g_smc_map_project > 0)
   {
      double y2 = (g_smc_map_trend == 1) ? g_smc_map_up : g_smc_map_dn;
      SmcObjTrend(SMC_IND_PREFIX + "MAP_PROJ", g_smc_map_sum, g_smc_map_point,
                  (g_smc_map_project > 0 ? g_smc_map_project : t_now), y2,
                  clrRed, STYLE_SOLID);
   }
}

void SmcDrawSweepZone()
{
   SmcObjDeleteKind("SWZ_");
   if(!g_smc_cfg.show_sweep_zone || !g_smc_lc_start)
      return;
   if(g_smc_lc_count > g_smc_cfg.zone_thresh)
   {
      g_smc_lc_start = false;
      g_smc_lc_count = 0;
      return;
   }
   // zone drawn when sweep-area alert fires in ProcessSweepArea
}

void SmcProcessSweepArea()
{
   if(!g_smc_cfg.show_sweep_zone || !g_smc_lc_start)
      return;
   double hi = g_smc_rates[0].high;
   double lo = g_smc_rates[0].low;
   double cl = g_smc_rates[0].close;
   datetime t = g_smc_rates[0].time;
   if(g_smc_lc_count <= g_smc_cfg.zone_thresh)
   {
      if(g_smc_ms.trend == -1)
      {
         if(hi > g_smc_ms.zz && cl < g_smc_ms.zz)
            g_smc_lc_count = 0;
         if(cl > g_smc_ms.zz)
         {
            SmcAlertFire(11, true, "Sweep Area");
            g_smc_lc_start = false;
            g_smc_lc_count = 0;
            datetime t0 = SmcTimeAtAbs(g_smc_ms.zn);
            if(t0 == 0) t0 = t;
            double btm = lo;
            int span = g_smc_bar_abs - g_smc_ms.zn;
            for(int i = 0; i <= span && i < g_smc_rates_n; i++)
               if(g_smc_rates[i].low < btm) btm = g_smc_rates[i].low;
            SmcObjRect(SMC_IND_PREFIX + "SWZ_DN", t0, g_smc_ms.zz, t, btm,
                       g_smc_cfg.sweep_dn, g_smc_cfg.sweep_dn, true);
            SmcObjTrend(SMC_IND_PREFIX + "SWZ_DNL", t0, g_smc_ms.zz, t, g_smc_ms.zz,
                        g_smc_cfg.swing_dn, STYLE_DOT);
            return;
         }
      }
      else if(g_smc_ms.trend == 1)
      {
         if(lo < g_smc_ms.zz && cl > g_smc_ms.zz)
            g_smc_lc_count = 0;
         if(cl < g_smc_ms.zz)
         {
            SmcAlertFire(11, false, "Sweep Area");
            g_smc_lc_start = false;
            g_smc_lc_count = 0;
            datetime t0 = SmcTimeAtAbs(g_smc_ms.zn);
            if(t0 == 0) t0 = t;
            double top = hi;
            int span = g_smc_bar_abs - g_smc_ms.zn;
            for(int i = 0; i <= span && i < g_smc_rates_n; i++)
               if(g_smc_rates[i].high > top) top = g_smc_rates[i].high;
            SmcObjRect(SMC_IND_PREFIX + "SWZ_UP", t0, top, t, g_smc_ms.zz,
                       g_smc_cfg.sweep_up, g_smc_cfg.sweep_up, true);
            SmcObjTrend(SMC_IND_PREFIX + "SWZ_UPL", t0, g_smc_ms.zz, t, g_smc_ms.zz,
                        g_smc_cfg.swing_up, STYLE_DOT);
            return;
         }
      }
   }
   if(g_smc_lc_count > g_smc_cfg.zone_thresh)
   {
      g_smc_lc_start = false;
      g_smc_lc_count = 0;
   }
   g_smc_lc_count++;
}

void SmcDrawSides()
{
   SmcObjDeleteKind("SIDE_");
   if(!g_smc_cfg.show_side)
      return;
   datetime t_ext = iTime(_Symbol, PERIOD_CURRENT, 0) + PeriodSeconds() * 20;
   if(g_smc_buyside_n > 0)
   {
      SmcSide s = g_smc_buyside[0];
      if(g_smc_cfg.side_as_area)
         SmcObjRect(SMC_IND_PREFIX + "SIDE_BU", s.loc, s.top, t_ext, s.btm,
                    s.css, s.css, true);
      else
         SmcObjTrend(SMC_IND_PREFIX + "SIDE_BU", s.loc, s.btm, t_ext, s.btm,
                     s.css, STYLE_DASH);
      SmcObjText(SMC_IND_PREFIX + "SIDE_BUL", t_ext, s.btm, s.txt, s.css, 7);
   }
   if(g_smc_sellside_n > 0)
   {
      SmcSide s = g_smc_sellside[0];
      if(g_smc_cfg.side_as_area)
         SmcObjRect(SMC_IND_PREFIX + "SIDE_BE", s.loc, s.top, t_ext, s.btm,
                    s.css, s.css, true);
      else
         SmcObjTrend(SMC_IND_PREFIX + "SIDE_BE", s.loc, s.top, t_ext, s.top,
                     s.css, STYLE_DASH);
      SmcObjText(SMC_IND_PREFIX + "SIDE_BEL", t_ext, s.top, s.txt, s.css, 7);
   }
}

void SmcDrawLiqPrints()
{
   if(g_smc_snap.liq_print_up)
   {
      string n = SmcObjName("LIQ_UP");
      SmcObjArrow(n, g_smc_rates[0].time, g_smc_rates[0].high, g_smc_cfg.swing_dn, 234);
   }
   if(g_smc_snap.liq_print_dn)
   {
      string n = SmcObjName("LIQ_DN");
      SmcObjArrow(n, g_smc_rates[0].time, g_smc_rates[0].low, g_smc_cfg.swing_up, 233);
   }
}

void SmcDrawStatus()
{
   string name = SMC_IND_PREFIX + "STATUS";
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, 8);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, 18);
   string tr = (g_smc_snap.trend == 1) ? "BULL" : (g_smc_snap.trend == -1) ? "BEAR" : "FLAT";
   ObjectSetString(0, name, OBJPROP_TEXT,
      StringFormat("SMC-Lana %s %s %s", tr, g_smc_snap.txt, g_smc_snap.last_event));
   ObjectSetInteger(0, name, OBJPROP_COLOR,
      g_smc_snap.trend == 1 ? g_smc_cfg.swing_up :
      (g_smc_snap.trend == -1 ? g_smc_cfg.swing_dn : clrSilver));
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 9);
}

void SmcRedrawAll()
{
   SmcDrawStructure();
   SmcDrawOBs();
   SmcDrawMapping();
   SmcDrawSides();
   SmcFvgDraw(g_smc_cfg);
   SmcSfpDraw(g_smc_cfg);
   SmcLiqHlDraw(g_smc_cfg, g_smc_snap.trend);
   SmcMtfDraw(g_smc_cfg);
   SmcDrawStatus();
}

void SmcWarmup()
{
   int need = MathMax(g_smc_cfg.mswindow, SMC_IND_ATR_LEN + 50);
   if(g_smc_cfg.window_limit)
      need = MathMin(need, g_smc_cfg.mswindow);
   need = MathMax(need, g_smc_cfg.pivot_len * 2 + 20);
   if(!SmcLoadRates(need))
      return;

   SmcIndConfig cfg = g_smc_cfg;
   SmcResetEngine();
   SmcFvgReset();
   SmcSfpReset();
   SmcLiqHlReset();
   g_smc_cfg = cfg;

   MqlRates master[];
   int master_n = g_smc_rates_n;
   ArrayResize(master, master_n);
   ArraySetAsSeries(master, true);
   for(int i = 0; i < master_n; i++)
      master[i] = g_smc_rates[i];

   ArrayResize(g_smc_times, master_n);
   // oldest → newest: times[0]=oldest
   for(int i = 0; i < master_n; i++)
      g_smc_times[i] = master[master_n - 1 - i].time;
   g_smc_times_n = master_n;

   int oldest = master_n - 1;
   int newest_closed = 1;
   for(int sh = oldest; sh >= newest_closed; sh--)
   {
      int cnt = master_n - sh;
      ArrayResize(g_smc_rates, cnt);
      ArraySetAsSeries(g_smc_rates, true);
      for(int i = 0; i < cnt; i++)
         g_smc_rates[i] = master[sh + i];
      g_smc_rates_n = cnt;
      g_smc_bar_abs++;
      bool in_win = !g_smc_cfg.window_limit ||
                    (g_smc_bar_abs > (master_n - 1 - g_smc_cfg.mswindow));
      bool draw = g_smc_cfg.show_swing && in_win;
      SmcStructureStep(g_smc_bar_abs, draw);
      SmcMappingStep(g_smc_bar_abs);
      SmcPosLiqStep(g_smc_cfg.pivot_len);
      SmcProcessSweepArea();
      SmcFvgStep(g_smc_rates, g_smc_rates_n, g_smc_cfg);
      SmcSfpStep(g_smc_rates, g_smc_rates_n, g_smc_cfg);
      SmcLiqHlStep(g_smc_rates, g_smc_rates_n, g_smc_cfg, g_smc_ms.trend);
   }
   SmcPublishSnap();
   g_smc_warmed = true;
   SmcRedrawAll();
}

void SmcUpdateOnNewBar()
{
   datetime t0 = iTime(_Symbol, PERIOD_CURRENT, 0);
   if(t0 == 0)
      return;
   if(!g_smc_warmed)
   {
      SmcWarmup();
      g_smc_last_bar = t0;
      return;
   }
   if(t0 == g_smc_last_bar)
   {
      // forming bar: only refresh extend-right drawings
      SmcDrawOBs();
      SmcDrawSides();
      SmcDrawStatus();
      return;
   }
   g_smc_last_bar = t0;
   int need = MathMax(g_smc_cfg.mswindow, SMC_IND_ATR_LEN + 50);
   ArraySetAsSeries(g_smc_rates, true);
   int n = CopyRates(_Symbol, PERIOD_CURRENT, 1, need, g_smc_rates);
   if(n < g_smc_cfg.pivot_len * 2 + 10)
      return;
   g_smc_rates_n = n;

   int tn = ArraySize(g_smc_times);
   ArrayResize(g_smc_times, tn + 1);
   g_smc_times[tn] = g_smc_rates[0].time;
   g_smc_times_n = tn + 1;

   g_smc_bar_abs++;
   bool draw = g_smc_cfg.show_swing;
   SmcStructureStep(g_smc_bar_abs, draw);
   SmcMappingStep(g_smc_bar_abs);
   SmcPosLiqStep(g_smc_cfg.pivot_len);
   SmcProcessSweepArea();
   SmcFvgStep(g_smc_rates, g_smc_rates_n, g_smc_cfg);
   SmcSfpStep(g_smc_rates, g_smc_rates_n, g_smc_cfg);
   SmcLiqHlStep(g_smc_rates, g_smc_rates_n, g_smc_cfg, g_smc_ms.trend);
   SmcDrawLiqPrints();
   SmcPublishSnap();
   SmcRedrawAll();
}

#endif
