//+------------------------------------------------------------------+
//| SMC_Lana_OB chart objects — OB rectangles only                    |
//+------------------------------------------------------------------+
#ifndef SMC_LANA_OB_OBJECTS_MQH
#define SMC_LANA_OB_OBJECTS_MQH

#define SMC_OB_PREFIX "SMCLanaOB_"

void SmcObObjClear()
{
   ObjectsDeleteAll(0, SMC_OB_PREFIX);
}

bool SmcObObjRect(const string name, const datetime t1, const double p1,
                  const datetime t2, const double p2,
                  const color fill, const color border)
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
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, fill);
   ObjectSetInteger(0, name, OBJPROP_FILL, true);
   ObjectSetInteger(0, name, OBJPROP_BACK, true);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   return true;
}

bool SmcObObjMid(const string name, const datetime t1, const double y,
                 const datetime t2, const color css)
{
   if(ObjectFind(0, name) < 0)
   {
      if(!ObjectCreate(0, name, OBJ_TREND, 0, t1, y, t2, y))
         return false;
   }
   ObjectSetInteger(0, name, OBJPROP_TIME, 0, t1);
   ObjectSetDouble(0, name, OBJPROP_PRICE, 0, y);
   ObjectSetInteger(0, name, OBJPROP_TIME, 1, t2);
   ObjectSetDouble(0, name, OBJPROP_PRICE, 1, y);
   ObjectSetInteger(0, name, OBJPROP_COLOR, css);
   ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_DOT);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   return true;
}

#endif
