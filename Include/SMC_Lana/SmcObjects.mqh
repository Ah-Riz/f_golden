//+------------------------------------------------------------------+
//| SMC_Lana chart object helpers                                     |
//+------------------------------------------------------------------+
#ifndef SMC_LANA_OBJECTS_MQH
#define SMC_LANA_OBJECTS_MQH

#include "SmcTypes.mqh"

int g_smc_obj_seq = 0;

void SmcObjClearAll()
{
   ObjectsDeleteAll(0, SMC_IND_PREFIX);
   g_smc_obj_seq = 0;
}

string SmcObjName(const string kind)
{
   g_smc_obj_seq++;
   return StringFormat("%s%s_%d", SMC_IND_PREFIX, kind, g_smc_obj_seq);
}

void SmcObjTrimPrefix(const string kind_prefix, const int keep)
{
   // keep newest by name seq — simple: if too many of kind, wipe kind and redraw next pass
   int count = 0;
   const int total = ObjectsTotal(0, 0, -1);
   for(int i = total - 1; i >= 0; i--)
   {
      string n = ObjectName(0, i, 0, -1);
      if(StringFind(n, SMC_IND_PREFIX + kind_prefix) == 0)
         count++;
   }
   if(count <= keep)
      return;
   for(int i = ObjectsTotal(0, 0, -1) - 1; i >= 0; i--)
   {
      string n = ObjectName(0, i, 0, -1);
      if(StringFind(n, SMC_IND_PREFIX + kind_prefix) == 0)
      {
         ObjectDelete(0, n);
         count--;
         if(count <= keep)
            break;
      }
   }
}

bool SmcObjTrend(const string name, const datetime t1, const double y1,
                 const datetime t2, const double y2,
                 const color css, const ENUM_LINE_STYLE style, const int width = 1)
{
   if(ObjectFind(0, name) < 0)
   {
      if(!ObjectCreate(0, name, OBJ_TREND, 0, t1, y1, t2, y2))
         return false;
   }
   ObjectSetInteger(0, name, OBJPROP_TIME, 0, t1);
   ObjectSetDouble(0, name, OBJPROP_PRICE, 0, y1);
   ObjectSetInteger(0, name, OBJPROP_TIME, 1, t2);
   ObjectSetDouble(0, name, OBJPROP_PRICE, 1, y2);
   ObjectSetInteger(0, name, OBJPROP_COLOR, css);
   ObjectSetInteger(0, name, OBJPROP_STYLE, style);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, width);
   ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
   return true;
}

bool SmcObjHLine(const string name, const double price, const color css,
                 const ENUM_LINE_STYLE style, const int width = 1)
{
   if(ObjectFind(0, name) < 0)
   {
      if(!ObjectCreate(0, name, OBJ_HLINE, 0, 0, price))
         return false;
   }
   ObjectSetDouble(0, name, OBJPROP_PRICE, price);
   ObjectSetInteger(0, name, OBJPROP_COLOR, css);
   ObjectSetInteger(0, name, OBJPROP_STYLE, style);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, width);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   return true;
}

bool SmcObjRect(const string name, const datetime t1, const double p1,
                const datetime t2, const double p2,
                const color fill, const color border, const bool filled)
{
   if(ObjectFind(0, name) < 0)
   {
      if(!ObjectCreate(0, name, OBJ_RECTANGLE, 0, t1, p1, t2, p2))
         return false;
   }
   ObjectSetInteger(0, name, OBJPROP_TIME, 0, t1);
   ObjectSetDouble(0, name, OBJPROP_PRICE, 0, p1);
   ObjectSetInteger(0, name, OBJPROP_TIME, 1, t2);
   ObjectSetDouble(0, name, OBJPROP_PRICE, 1, p2);
   ObjectSetInteger(0, name, OBJPROP_COLOR, border);
   ObjectSetInteger(0, name, OBJPROP_FILL, filled);
   ObjectSetInteger(0, name, OBJPROP_BACK, true);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, fill);
   return true;
}

bool SmcObjText(const string name, const datetime t, const double price,
                const string text, const color css, const int fontsize = 8,
                const ENUM_ANCHOR_POINT anchor = ANCHOR_LEFT)
{
   if(ObjectFind(0, name) < 0)
   {
      if(!ObjectCreate(0, name, OBJ_TEXT, 0, t, price))
         return false;
   }
   ObjectSetInteger(0, name, OBJPROP_TIME, t);
   ObjectSetDouble(0, name, OBJPROP_PRICE, price);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_COLOR, css);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontsize);
   ObjectSetInteger(0, name, OBJPROP_ANCHOR, anchor);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   return true;
}

bool SmcObjArrow(const string name, const datetime t, const double price,
                 const color css, const int code = 159)
{
   if(ObjectFind(0, name) < 0)
   {
      if(!ObjectCreate(0, name, OBJ_ARROW, 0, t, price))
         return false;
   }
   ObjectSetInteger(0, name, OBJPROP_TIME, t);
   ObjectSetDouble(0, name, OBJPROP_PRICE, price);
   ObjectSetInteger(0, name, OBJPROP_COLOR, css);
   ObjectSetInteger(0, name, OBJPROP_ARROWCODE, code);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   return true;
}

void SmcObjDeleteKind(const string kind_prefix)
{
   for(int i = ObjectsTotal(0, 0, -1) - 1; i >= 0; i--)
   {
      string n = ObjectName(0, i, 0, -1);
      if(StringFind(n, SMC_IND_PREFIX + kind_prefix) == 0)
         ObjectDelete(0, n);
   }
}

#endif
