//+------------------------------------------------------------------+
//| GRAI SmcDraw — optional chart objects for SMC snapshot            |
//+------------------------------------------------------------------+
#ifndef GRAI_SMC_DRAW_MQH
#define GRAI_SMC_DRAW_MQH

#include "SmcLana.mqh"

bool g_grai_smc_draw = false;

void GRAI_SmcDrawClear()
{
   ObjectsDeleteAll(0, "GRAI_SMC_");
}

void GRAI_SmcDrawUpdate()
{
   if(!g_grai_smc_draw)
      return;

   // Trend label
   string name = "GRAI_SMC_TREND";
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, 8);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, 20);
   ObjectSetString(0, name, OBJPROP_TEXT,
      StringFormat("SMC %s %s %s", GRAI_SmcTrendStr(), g_grai_smc_snap.txt, g_grai_smc_snap.last_event));
   ObjectSetInteger(0, name, OBJPROP_COLOR,
      g_grai_smc_snap.trend == 1 ? clrLime : (g_grai_smc_snap.trend == -1 ? clrTomato : clrSilver));
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 10);

   // BOS / CHoCH levels as horizontals
   if(g_grai_smc_snap.bos_valid)
   {
      string nb = "GRAI_SMC_BOS";
      if(ObjectFind(0, nb) < 0)
         ObjectCreate(0, nb, OBJ_HLINE, 0, 0, g_grai_smc_snap.bos);
      ObjectSetDouble(0, nb, OBJPROP_PRICE, g_grai_smc_snap.bos);
      ObjectSetInteger(0, nb, OBJPROP_COLOR, g_grai_smc_snap.trend == 1 ? clrLime : clrTomato);
      ObjectSetInteger(0, nb, OBJPROP_STYLE, STYLE_DASH);
   }
   if(g_grai_smc_snap.choch_valid)
   {
      string nc = "GRAI_SMC_CHOCH";
      if(ObjectFind(0, nc) < 0)
         ObjectCreate(0, nc, OBJ_HLINE, 0, 0, g_grai_smc_snap.choch);
      ObjectSetDouble(0, nc, OBJPROP_PRICE, g_grai_smc_snap.choch);
      ObjectSetInteger(0, nc, OBJPROP_COLOR, clrDodgerBlue);
      ObjectSetInteger(0, nc, OBJPROP_STYLE, STYLE_DOT);
   }

   // Active OBs as rectangles on last N bars
   datetime t1 = iTime(_Symbol, PERIOD_CURRENT, 0);
   datetime t0 = iTime(_Symbol, PERIOD_CURRENT, 30);
   if(g_grai_smc_snap.has_bull_ob)
   {
      string obn = "GRAI_SMC_OB_BULL";
      if(ObjectFind(0, obn) < 0)
         ObjectCreate(0, obn, OBJ_RECTANGLE, 0, t0, g_grai_smc_snap.bull_ob_top, t1, g_grai_smc_snap.bull_ob_btm);
      ObjectSetInteger(0, obn, OBJPROP_TIME, 0, t0);
      ObjectSetInteger(0, obn, OBJPROP_TIME, 1, t1);
      ObjectSetDouble(0, obn, OBJPROP_PRICE, 0, g_grai_smc_snap.bull_ob_top);
      ObjectSetDouble(0, obn, OBJPROP_PRICE, 1, g_grai_smc_snap.bull_ob_btm);
      ObjectSetInteger(0, obn, OBJPROP_COLOR, clrLime);
      ObjectSetInteger(0, obn, OBJPROP_FILL, true);
      ObjectSetInteger(0, obn, OBJPROP_BACK, true);
   }
   if(g_grai_smc_snap.has_bear_ob)
   {
      string obn = "GRAI_SMC_OB_BEAR";
      if(ObjectFind(0, obn) < 0)
         ObjectCreate(0, obn, OBJ_RECTANGLE, 0, t0, g_grai_smc_snap.bear_ob_top, t1, g_grai_smc_snap.bear_ob_btm);
      ObjectSetInteger(0, obn, OBJPROP_TIME, 0, t0);
      ObjectSetInteger(0, obn, OBJPROP_TIME, 1, t1);
      ObjectSetDouble(0, obn, OBJPROP_PRICE, 0, g_grai_smc_snap.bear_ob_top);
      ObjectSetDouble(0, obn, OBJPROP_PRICE, 1, g_grai_smc_snap.bear_ob_btm);
      ObjectSetInteger(0, obn, OBJPROP_COLOR, clrTomato);
      ObjectSetInteger(0, obn, OBJPROP_FILL, true);
      ObjectSetInteger(0, obn, OBJPROP_BACK, true);
   }
}

#endif
