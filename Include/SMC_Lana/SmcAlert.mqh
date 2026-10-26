//+------------------------------------------------------------------+
//| SMC_Lana alerts — mirrors Pine alertinputs matrix                 |
//+------------------------------------------------------------------+
#ifndef SMC_LANA_ALERT_MQH
#define SMC_LANA_ALERT_MQH

#include "SmcTypes.mqh"

// Indices match Pine ANY ALERT order:
// 0 CHoCH, 1 BOS, 2 CHoCH Sweep, 3 BOS Sweep, 4 OB Mitigated,
// 5 Price Inside OB, 6 FVG Mitigated, 7 Raid Found, 8 Price Inside FVG,
// 9 SFP Created, 10 Liquidity Print, 11 Sweep Area

bool g_smc_alert_flags[12];
int  g_smc_alert_dir = SMC_ALERT_BOTH;
datetime g_smc_alert_last[12];

void SmcAlertInitFromConfig(const SmcIndConfig &c)
{
   g_smc_alert_dir = c.alert_dir;
   g_smc_alert_flags[0]  = c.alert_choch;
   g_smc_alert_flags[1]  = c.alert_bos;
   g_smc_alert_flags[2]  = c.alert_choch_sweep;
   g_smc_alert_flags[3]  = c.alert_bos_sweep;
   g_smc_alert_flags[4]  = c.alert_ob_miti;
   g_smc_alert_flags[5]  = c.alert_ob_inside;
   g_smc_alert_flags[6]  = c.alert_fvg_miti;
   g_smc_alert_flags[7]  = c.alert_raid;
   g_smc_alert_flags[8]  = c.alert_fvg_inside;
   g_smc_alert_flags[9]  = c.alert_sfp;
   g_smc_alert_flags[10] = c.alert_liq;
   g_smc_alert_flags[11] = c.alert_sweep_area;
   for(int i = 0; i < 12; i++)
      g_smc_alert_last[i] = 0;
}

void SmcAlertFire(const int idx, const bool bullish, const string name)
{
   if(idx < 0 || idx >= 12)
      return;
   if(!g_smc_alert_flags[idx])
      return;
   if(g_smc_alert_dir == SMC_ALERT_BULL && !bullish)
      return;
   if(g_smc_alert_dir == SMC_ALERT_BEAR && bullish)
      return;
   datetime now = TimeCurrent();
   // debounce same alert within same bar second
   if(g_smc_alert_last[idx] == now)
      return;
   g_smc_alert_last[idx] = now;
   string dir = bullish ? "Bullish" : "Bearish";
   string msg = StringFormat("SMC-Lana %s %s %s", _Symbol, dir, name);
   Alert(msg);
}

#endif
