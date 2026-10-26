//+------------------------------------------------------------------+
//| SMC_Lana_OB.mq5 — Order Blocks only (SNR)                         |
//| Lean fork of SMC_Lana. No BOS/CHoCH/FVG/SFP/MTF drawings.          |
//| Default mitigation = Touch (hit zone → remove). No profit claim.   |
//+------------------------------------------------------------------+
#property copyright "gold_rush_AI"
#property version   "1.00"
#property description "SMC-Lana OB-only SNR zones"
#property indicator_chart_window
#property indicator_buffers 0
#property indicator_plots   0

#include <SMC_Lana_OB/SmcObEngine.mqh>

input group "Structure (OB birth only)"
input int    InpPivotLen      = 5;              // Pivot length
input bool   InpAdjustedPts   = true;           // Adjusted Points
input bool   InpBuildSweep    = true;           // Build sweep (affects birth)
input int    InpLookback      = 1500;           // Warmup bars

input group "Order Blocks (SNR)"
input int    InpObKeep        = 3;              // Show last N per side
input bool   InpObLengthMode  = true;           // Length construction
input int    InpObLen         = 5;              // Length factor
input int    InpObMiti        = 0;              // 0=Touch 1=Close 2=Wick 3=Avg
input bool   InpHideOverlap   = true;           // Hide overlap
input bool   InpShowMidline   = false;          // Mid-line
input color  InpObUp          = C'8,153,129';   // Bull OB
input color  InpObDn          = C'242,54,69';   // Bear OB

void SmcObApplyInputs()
{
   SmcObCfgDefaults(g_ob_cfg);
   g_ob_cfg.timeframe       = PERIOD_CURRENT; // chart TF (EA may override via InpObTimeframe)
   g_ob_cfg.pivot_len       = MathMax(2, InpPivotLen);
   g_ob_cfg.adjusted_points = InpAdjustedPts;
   g_ob_cfg.build_sweep     = InpBuildSweep;
   g_ob_cfg.lookback        = MathMax(100, InpLookback);
   g_ob_cfg.ob_keep         = MathMax(0, InpObKeep);
   g_ob_cfg.ob_length_mode  = InpObLengthMode;
   g_ob_cfg.ob_len          = MathMax(1, InpObLen);
   g_ob_cfg.ob_miti         = MathMax(0, MathMin(3, InpObMiti));
   g_ob_cfg.hide_overlap    = InpHideOverlap;
   g_ob_cfg.show_midline    = InpShowMidline;
   g_ob_cfg.ob_up           = InpObUp;
   g_ob_cfg.ob_dn           = InpObDn;
}

int OnInit()
{
   IndicatorSetString(INDICATOR_SHORTNAME, "SMC-Lana-OB");
   SmcObApplyInputs();
   SmcObObjClear();
   g_ob_warmed = false;
   g_ob_last_bar = 0;
   Print("[SMC-Lana-OB] INIT pivot=", InpPivotLen,
         " keep=", InpObKeep,
         " miti=", InpObMiti,
         " (0=Touch)");
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   SmcObObjClear();
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
   if(rates_total < g_ob_cfg.pivot_len * 2 + 20)
      return 0;
   SmcObUpdate();
   return rates_total;
}
