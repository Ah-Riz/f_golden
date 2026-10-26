//+------------------------------------------------------------------+
//| SMC_Lana indicator types / config (independent of GRAI EA)        |
//+------------------------------------------------------------------+
#ifndef SMC_LANA_TYPES_MQH
#define SMC_LANA_TYPES_MQH

#define SMC_IND_PREFIX     "SMCLana_"
#define SMC_IND_MAX_OB     64
#define SMC_IND_MAX_PV     64
#define SMC_IND_MAX_DRAW   200
#define SMC_IND_MAX_FVG    64
#define SMC_IND_MAX_SFP    32
#define SMC_IND_MAX_SIDE   16
#define SMC_IND_MAX_MAP    128
#define SMC_IND_ATR_LEN    200

enum ENUM_SMC_OB_MITI
{
   SMC_MITI_CLOSE = 0,
   SMC_MITI_WICK  = 1,
   SMC_MITI_AVG   = 2
};

enum ENUM_SMC_ALERT_DIR
{
   SMC_ALERT_BULL = 0,
   SMC_ALERT_BEAR = 1,
   SMC_ALERT_BOTH = 2
};

struct SmcIndConfig
{
   // Market structure
   bool     window_limit;
   int      mswindow;
   bool     show_swing;
   int      swing_limit;
   color    swing_up;
   color    swing_dn;
   bool     show_internal;
   color    intern_up;
   color    intern_dn;
   bool     show_mapping;
   color    mapping_css;
   bool     candle_css;
   bool     show_pd_zone;
   int      zone_len;
   color    fib_css;
   bool     adjusted_points;
   int      pivot_len;
   bool     show_hl;
   bool     build_sweep;
   bool     show_bubbles;

   // Order blocks
   bool     ob_show;
   int      ob_keep;
   color    ob_up;
   color    ob_dn;
   bool     ob_show_activity;
   color    ob_act_up;
   color    ob_act_dn;
   bool     ob_show_breakers;
   color    bb_up;
   color    bb_dn;
   bool     ob_length_mode;
   int      ob_len;
   int      ob_miti;
   bool     show_metric;
   bool     show_midline;
   bool     hide_overlap;

   // SFP
   bool     sfp_show;
   color    sfp_css;
   bool     sfp_show_level;
   bool     sfp_fill;

   // Liquidity
   bool     show_side;
   bool     side_as_area;
   color    buyside_css;
   color    sellside_css;
   bool     show_sweep_zone;
   int      zone_thresh;
   color    sweep_up;
   color    sweep_dn;

   // MTF
   bool     lvl_daily;
   bool     lvl_weekly;
   bool     lvl_monthly;
   bool     lvl_quarterly;
   bool     lvl_yearly;
   color    css_d;
   color    css_w;
   color    css_m;
   color    css_q;
   color    css_y;

   // FVG
   bool     show_fvg;
   int      fvg_keep;
   color    fvg_up;
   color    fvg_dn;

   // Alerts
   int      alert_dir;   // ENUM_SMC_ALERT_DIR
   bool     alert_choch;
   bool     alert_bos;
   bool     alert_choch_sweep;
   bool     alert_bos_sweep;
   bool     alert_ob_miti;
   bool     alert_ob_inside;
   bool     alert_fvg_miti;
   bool     alert_raid;
   bool     alert_fvg_inside;
   bool     alert_sfp;
   bool     alert_liq;
   bool     alert_sweep_area;
};

struct SmcDrawMS
{
   bool     used;
   datetime t1;
   datetime t2;
   double   y;
   string   txt;
   color    css;
   ENUM_LINE_STYLE style;
   bool     bull;
};

struct SmcOB
{
   bool     used;
   bool     bull;
   double   top;
   double   btm;
   double   avg;
   datetime loc_time;
   datetime bb_time;
   double   vol;
   int      dir;
   bool     isbb;
   int      bl_pos;
   int      br_pos;
};

struct SmcFVG
{
   bool     used;
   bool     bull;
   double   top;
   double   btm;
   datetime loc_time;
   bool     isbb;
   datetime bb_time;
   bool     israid;
   double   raid_y;
   datetime raid_time;
};

struct SmcSFP
{
   bool     used;
   bool     bull;
   double   y;
   datetime loc;
   double   ancor;
};

struct SmcSide
{
   bool     used;
   double   top;
   double   btm;
   datetime loc;
   color    css;
   string   txt;
   double   vol;
};

struct SmcMapPt
{
   bool     used;
   datetime t;
   double   y;
};

struct SmcMS
{
   int      zn;
   double   zz;
   double   bos;
   double   choch;
   int      loc;
   int      temp;
   int      trend;
   int      start;
   double   main_px;
   int      xloc;
   bool     upsweep;
   bool     dnsweep;
   string   txt;
   bool     bos_valid;
   bool     choch_valid;
};

struct SmcSnap
{
   bool     ready;
   int      trend;
   string   txt;
   string   last_event;
   double   bos;
   double   choch;
   bool     bos_valid;
   bool     choch_valid;
   bool     upsweep;
   bool     dnsweep;
   int      map_trend;
   bool     liq_print_up;
   bool     liq_print_dn;
   bool     has_bull_ob;
   bool     has_bear_ob;
};

#endif
