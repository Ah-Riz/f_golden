//+------------------------------------------------------------------+
//| ManageClose — slim manage-mode + tighten-only for Fixed close port|
//| No SMC / Lifecycle dependency. Mode C/D behave as Mode B trail. |
//| Educational risk framing only — no profit guarantee.              |
//+------------------------------------------------------------------+
#ifndef GRAI_MANAGE_CLOSE_MQH
#define GRAI_MANAGE_CLOSE_MQH

enum ENUM_GRAI_MANAGE_MODE
{
   GRAI_MANAGE_A_STRUCT_FIXED = 0, // Mode A: fixed initial SL, no SL+ trail
   GRAI_MANAGE_B_DELAYED_SLP  = 1, // Mode B: delayed SL+ (default)
   GRAI_MANAGE_C_STRUCT_TRAIL = 2, // Mode C: reserved; Fixed has no swings → B trail
   GRAI_MANAGE_D_HYBRID       = 3  // Mode D: reserved; behaves as Mode B trail
};

string GRAI_ManageModeStr(const int mode)
{
   if(mode == GRAI_MANAGE_A_STRUCT_FIXED) return "A_STRUCT";
   if(mode == GRAI_MANAGE_B_DELAYED_SLP)  return "B_DELAYED";
   if(mode == GRAI_MANAGE_C_STRUCT_TRAIL) return "C_TRAIL";
   if(mode == GRAI_MANAGE_D_HYBRID)       return "D_HYBRID";
   return "UNKNOWN";
}

// Tighten-only protective stop (BUY new > cur; SELL new < cur). cur_sl==0 allows first set.
bool Fixed_TightenOnlyOk(const int cmd, const double cur_sl, const double new_sl)
{
   if(cur_sl == 0.0)
      return true;
   if(cmd == OP_BUY)
      return (new_sl > cur_sl + _Point * 0.5);
   if(cmd == OP_SELL)
      return (new_sl < cur_sl - _Point * 0.5);
   return false;
}

#endif
//+------------------------------------------------------------------+
