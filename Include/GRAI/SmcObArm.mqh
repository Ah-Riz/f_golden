//+------------------------------------------------------------------+
//| GRAI OB arm — SMC_Lana_OB bull zones arm BUY for N hours (v0.3.1) |
//| Zones may be HTF (InpObTimeframe); touch uses live Ask + M5 bar 0. |
//| Bias stays in Bias.mqh / SmcLana.mqh. SELL ignores this gate.     |
//+------------------------------------------------------------------+
#ifndef GRAI_SMC_OB_ARM_MQH
#define GRAI_SMC_OB_ARM_MQH

#include "AuditLog.mqh"
#include "../SMC_Lana_OB/SmcObEngine.mqh"

bool     g_grai_ob_entry_gate = false;
int      g_grai_ob_arm_sec = 7200; // InpObArmHours → seconds
datetime g_grai_ob_arm_until = 0;

bool GRAI_ObArmed()
{
   return (g_grai_ob_arm_until > 0 && TimeCurrent() < g_grai_ob_arm_until);
}

bool GRAI_ObZoneOverlap(const double hi, const double lo, const double top, const double btm)
{
   return (lo <= top && hi >= btm);
}

bool GRAI_ObPriceInZone(const double px, const double top, const double btm)
{
   return (px >= btm && px <= top);
}

string GRAI_ObTfStr()
{
   const ENUM_TIMEFRAMES tf = SmcObTf();
   if(tf == PERIOD_CURRENT) return "Current";
   if(tf == PERIOD_M5)      return "M5";
   if(tf == PERIOD_M15)     return "M15";
   if(tf == PERIOD_H1)      return "H1";
   if(tf == PERIOD_H4)      return "H4";
   if(tf == PERIOD_D1)      return "D1";
   return EnumToString(tf);
}

// Bull OB touch → refresh BUY permission window.
// Zones from SmcObTf() (e.g. H1); Ask + bar range from chart M5 (PERIOD_CURRENT).
void GRAI_ObArmUpdate()
{
   if(!g_grai_ob_entry_gate)
      return;
   if(g_ob_blob_n <= 0)
      return;

   const double ask = Ask;
   const double hi  = iHigh_MT4(_Symbol, PERIOD_CURRENT, 0);
   const double lo  = iLow_MT4(_Symbol, PERIOD_CURRENT, 0);
   if(ask <= 0.0)
      return;

   bool touched = false;
   for(int i = 0; i < g_ob_blob_n; i++)
   {
      if(!g_ob_blob[i].used)
         continue;
      if(GRAI_ObPriceInZone(ask, g_ob_blob[i].top, g_ob_blob[i].btm))
      {
         touched = true;
         break;
      }
      if(hi > 0.0 && lo > 0.0 &&
         GRAI_ObZoneOverlap(hi, lo, g_ob_blob[i].top, g_ob_blob[i].btm))
      {
         touched = true;
         break;
      }
   }
   if(!touched)
      return;

   const datetime prev = g_grai_ob_arm_until;
   const int sec = MathMax(60, g_grai_ob_arm_sec);
   g_grai_ob_arm_until = TimeCurrent() + sec;
   if(prev != g_grai_ob_arm_until)
   {
      static datetime s_arm_log = 0;
      if(TimeCurrent() - s_arm_log >= 30)
      {
         GRAI_Log("OB_ARM", StringFormat("until=%s sec=%d blob=%d tf=%s",
            TimeToString(g_grai_ob_arm_until, TIME_DATE|TIME_MINUTES),
            sec, g_ob_blob_n, GRAI_ObTfStr()));
         s_arm_log = TimeCurrent();
      }
   }
}

// Advance OB engine + refresh BUY arm on bull OB touch.
void GRAI_ObArmTick()
{
   if(!g_grai_ob_entry_gate)
      return;
   SmcObUpdate();
   GRAI_ObArmUpdate();
}

// Gate: SELL always OK; BUY only while armed (location free inside window).
bool GRAI_ObEntryAllowsCmd(const int cmd)
{
   if(!g_grai_ob_entry_gate)
      return true;
   if(cmd == OP_SELL)
      return true;
   if(cmd == OP_BUY)
      return GRAI_ObArmed();
   return false;
}

#endif
