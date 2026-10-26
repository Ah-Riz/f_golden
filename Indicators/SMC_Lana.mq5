//+------------------------------------------------------------------+
//| SMC_Lana.mq5 — full visual MT5 port of pine/SMC_Lana.pine         |
//| Chart overlay. Independent of GRAI EA SmcLana.mqh.                |
//| Visual port — not a dual-promote / Mode S gate. No profit claim.  |
//+------------------------------------------------------------------+
#property copyright "gold_rush_AI"
#property version   "1.00"
#property description "SMC-Lana visual indicator (structure, OB, FVG, SFP, MTF, liquidity)"
#property indicator_chart_window
#property indicator_buffers 1
#property indicator_plots   1
#property indicator_label1  "TrendColor"
#property indicator_type1   DRAW_NONE

#include <SMC_Lana/SmcEngine.mqh>

//--- MARKET STRUCTURE
input group "MARKET STRUCTURE"
input bool   InpWindowLimit   = true;           // Limit calc window
input int    InpMsWindow      = 5000;           // Window bars
input bool   InpShowSwing     = true;           // Show swing structure
input int    InpSwingLimit    = 100;            // Swing draw limit
input color  InpSwingUp       = C'8,153,129';   // Swing bull color
input color  InpSwingDn       = C'242,54,69';   // Swing bear color
input bool   InpShowInternal  = false;          // Internal structure (reserved)
input color  InpInternUp      = clrDodgerBlue;  // Internal bull
input color  InpInternDn      = clrPurple;      // Internal bear
input bool   InpShowMapping   = false;          // Mapping structure
input color  InpMappingCss    = clrSilver;      // Mapping color
input bool   InpCandleCss     = false;          // Color candles by trend
input bool   InpShowPdZone    = false;          // Premium / Discount
input int    InpZoneLen       = 20;             // PD / HL length
input color  InpFibCss        = C'251,192,45';  // 0.5 fib color
input bool   InpAdjustedPts   = true;           // Adjusted Points (else Extreme)
input int    InpPivotLen      = 5;              // Pivot / mslen
input bool   InpShowHL        = false;          // Strong / Weak HL
input bool   InpBuildSweep    = true;           // Build sweep (x)
input bool   InpShowBubbles   = true;           // Bubbles

//--- VOLUMETRIC ORDER BLOCKS
input group "VOLUMETRIC ORDER BLOCKS"
input bool   InpObShow        = true;           // Show OBs
input int    InpObKeep        = 5;              // Show last N
input color  InpObUp          = C'8,153,129';   // Bull OB
input color  InpObDn          = C'242,54,69';   // Bear OB
input bool   InpObActivity    = true;           // Show activity colors
input color  InpObActUp       = C'8,153,129';
input color  InpObActDn       = C'242,54,69';
input bool   InpObBreakers    = false;          // Show breakers
input color  InpBbUp          = C'8,153,129';
input color  InpBbDn          = C'242,54,69';
input bool   InpObLengthMode  = true;           // Length construction (else Full)
input int    InpObLen         = 5;              // OB length factor
input int    InpObMiti        = 0;              // Mitigation 0=Close 1=Wick 2=Avg
input bool   InpShowMetric    = true;           // Show metrics
input bool   InpShowMidline   = true;           // Show mid-line
input bool   InpHideOverlap   = true;           // Hide overlap

//--- Swing Failure Pattern
input group "Swing Failure Pattern"
input bool   InpSfpShow       = true;           // Show SFP
input color  InpSfpCss        = clrWhite;       // SFP color
input bool   InpSfpLevel      = true;           // Show level
input bool   InpSfpFill       = true;           // Fill area

//--- LIQUIDITY CONCEPTS
input group "LIQUIDITY CONCEPTS"
input bool   InpShowSide      = false;          // Buyside & Sellside
input bool   InpSideArea      = true;           // Area (else Line)
input color  InpBuysideCss    = C'0,153,51';
input color  InpSellsideCss   = C'204,51,0';
input bool   InpShowSweepZone = false;          // Sweep area
input int    InpZoneThresh    = 10;             // Sweep zone threshold
input color  InpSweepUp       = C'8,153,129';
input color  InpSweepDn       = C'242,54,69';

//--- HIGHS & LOWS MTF
input group "HIGHS & LOWS MTF"
input bool   InpLvlDaily      = false;          // Day
input bool   InpLvlWeekly     = false;          // Week
input bool   InpLvlMonthly    = false;          // Month
input bool   InpLvlQuarterly  = false;          // Quarterly
input bool   InpLvlYearly     = false;          // Year
input color  InpCssD          = clrDodgerBlue;
input color  InpCssW          = clrDodgerBlue;
input color  InpCssM          = clrDodgerBlue;
input color  InpCssQ          = clrDodgerBlue;
input color  InpCssY          = clrDodgerBlue;

//--- FVG
input group "FAIR VALUE GAPS"
input bool   InpShowFvg       = true;           // Show FVG
input int    InpFvgKeep       = 10;             // Keep last N
input color  InpFvgUp         = C'8,153,129';
input color  InpFvgDn         = C'242,54,69';

//--- ANY ALERT
input group "ANY ALERT"
input int    InpAlertDir      = 2;              // Direction 0=Bull 1=Bear 2=Both
input bool   InpAlertCHoCH    = false;
input bool   InpAlertBOS      = false;
input bool   InpAlertCHoCHSw  = false;
input bool   InpAlertBOSSw    = false;
input bool   InpAlertObMiti   = false;
input bool   InpAlertObInside = false;
input bool   InpAlertFvgMiti  = false;
input bool   InpAlertRaid     = false;
input bool   InpAlertFvgInside= false;
input bool   InpAlertSfp      = false;
input bool   InpAlertLiq      = false;
input bool   InpAlertSweepArea= false;

double g_trend_buf[];

void SmcApplyInputs()
{
   SmcConfigDefaults(g_smc_cfg);
   g_smc_cfg.window_limit     = InpWindowLimit;
   g_smc_cfg.mswindow         = MathMax(100, InpMsWindow);
   g_smc_cfg.show_swing       = InpShowSwing;
   g_smc_cfg.swing_limit      = MathMax(10, InpSwingLimit);
   g_smc_cfg.swing_up         = InpSwingUp;
   g_smc_cfg.swing_dn         = InpSwingDn;
   g_smc_cfg.show_internal    = InpShowInternal;
   g_smc_cfg.intern_up        = InpInternUp;
   g_smc_cfg.intern_dn        = InpInternDn;
   g_smc_cfg.show_mapping     = InpShowMapping;
   g_smc_cfg.mapping_css      = InpMappingCss;
   g_smc_cfg.candle_css       = InpCandleCss;
   g_smc_cfg.show_pd_zone     = InpShowPdZone;
   g_smc_cfg.zone_len         = MathMax(5, InpZoneLen);
   g_smc_cfg.fib_css          = InpFibCss;
   g_smc_cfg.adjusted_points  = InpAdjustedPts;
   g_smc_cfg.pivot_len        = MathMax(2, InpPivotLen);
   g_smc_cfg.show_hl          = InpShowHL;
   g_smc_cfg.build_sweep      = InpBuildSweep;
   g_smc_cfg.show_bubbles     = InpShowBubbles;

   g_smc_cfg.ob_show          = InpObShow;
   g_smc_cfg.ob_keep          = MathMax(0, InpObKeep);
   g_smc_cfg.ob_up            = InpObUp;
   g_smc_cfg.ob_dn            = InpObDn;
   g_smc_cfg.ob_show_activity = InpObActivity;
   g_smc_cfg.ob_act_up        = InpObActUp;
   g_smc_cfg.ob_act_dn        = InpObActDn;
   g_smc_cfg.ob_show_breakers = InpObBreakers;
   g_smc_cfg.bb_up            = InpBbUp;
   g_smc_cfg.bb_dn            = InpBbDn;
   g_smc_cfg.ob_length_mode   = InpObLengthMode;
   g_smc_cfg.ob_len           = MathMax(1, InpObLen);
   g_smc_cfg.ob_miti          = MathMax(0, MathMin(2, InpObMiti));
   g_smc_cfg.show_metric      = InpShowMetric;
   g_smc_cfg.show_midline     = InpShowMidline;
   g_smc_cfg.hide_overlap     = InpHideOverlap;

   g_smc_cfg.sfp_show         = InpSfpShow;
   g_smc_cfg.sfp_css          = InpSfpCss;
   g_smc_cfg.sfp_show_level   = InpSfpLevel;
   g_smc_cfg.sfp_fill         = InpSfpFill;

   g_smc_cfg.show_side        = InpShowSide;
   g_smc_cfg.side_as_area     = InpSideArea;
   g_smc_cfg.buyside_css      = InpBuysideCss;
   g_smc_cfg.sellside_css     = InpSellsideCss;
   g_smc_cfg.show_sweep_zone  = InpShowSweepZone;
   g_smc_cfg.zone_thresh      = MathMax(2, InpZoneThresh);
   g_smc_cfg.sweep_up         = InpSweepUp;
   g_smc_cfg.sweep_dn         = InpSweepDn;

   g_smc_cfg.lvl_daily        = InpLvlDaily;
   g_smc_cfg.lvl_weekly       = InpLvlWeekly;
   g_smc_cfg.lvl_monthly      = InpLvlMonthly;
   g_smc_cfg.lvl_quarterly    = InpLvlQuarterly;
   g_smc_cfg.lvl_yearly       = InpLvlYearly;
   g_smc_cfg.css_d = InpCssD;
   g_smc_cfg.css_w = InpCssW;
   g_smc_cfg.css_m = InpCssM;
   g_smc_cfg.css_q = InpCssQ;
   g_smc_cfg.css_y = InpCssY;

   g_smc_cfg.show_fvg         = InpShowFvg;
   g_smc_cfg.fvg_keep         = MathMax(1, InpFvgKeep);
   g_smc_cfg.fvg_up           = InpFvgUp;
   g_smc_cfg.fvg_dn           = InpFvgDn;

   g_smc_cfg.alert_dir        = MathMax(0, MathMin(2, InpAlertDir));
   g_smc_cfg.alert_choch      = InpAlertCHoCH;
   g_smc_cfg.alert_bos        = InpAlertBOS;
   g_smc_cfg.alert_choch_sweep= InpAlertCHoCHSw;
   g_smc_cfg.alert_bos_sweep  = InpAlertBOSSw;
   g_smc_cfg.alert_ob_miti    = InpAlertObMiti;
   g_smc_cfg.alert_ob_inside  = InpAlertObInside;
   g_smc_cfg.alert_fvg_miti   = InpAlertFvgMiti;
   g_smc_cfg.alert_raid       = InpAlertRaid;
   g_smc_cfg.alert_fvg_inside = InpAlertFvgInside;
   g_smc_cfg.alert_sfp        = InpAlertSfp;
   g_smc_cfg.alert_liq        = InpAlertLiq;
   g_smc_cfg.alert_sweep_area = InpAlertSweepArea;

   SmcAlertInitFromConfig(g_smc_cfg);
}

int OnInit()
{
   SetIndexBuffer(0, g_trend_buf, INDICATOR_CALCULATIONS);
   ArraySetAsSeries(g_trend_buf, true);
   IndicatorSetString(INDICATOR_SHORTNAME, "SMC-Lana");

   SmcApplyInputs();
   SmcObjClearAll();
   g_smc_warmed = false;
   g_smc_last_bar = 0;

   Print("[SMC-Lana] INIT swing=", InpShowSwing,
         " pivot=", InpPivotLen,
         " ob=", InpObKeep,
         " fvg=", InpShowFvg,
         " sfp=", InpSfpShow);
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   SmcObjClearAll();
}

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   if(rates_total < g_smc_cfg.pivot_len * 2 + 20)
      return 0;

   SmcUpdateOnNewBar();

   // Optional trend color buffer (DRAW_NONE — for EA/scripts; candle paint is MT5-limited)
   if(InpCandleCss && rates_total > 0)
   {
      ArraySetAsSeries(g_trend_buf, true);
      g_trend_buf[0] = (double)g_smc_snap.trend;
   }

   return rates_total;
}

//+------------------------------------------------------------------+
