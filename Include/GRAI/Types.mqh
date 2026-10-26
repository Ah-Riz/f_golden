//+------------------------------------------------------------------+
//| GRAI core enums / lightweight state (v0.1)                        |
//+------------------------------------------------------------------+
#ifndef GRAI_TYPES_MQH
#define GRAI_TYPES_MQH

enum ENUM_GRAI_MOMENTUM
{
   GRAI_MOM_NONE = 0,
   GRAI_MOM_A    = 1, // GRP_ROTATE_AVG  parent entry
   GRAI_MOM_B    = 2, // GRP_ROTATE_EMA  parent entry
   GRAI_MOM_C    = 3, // GRP_CANDLE_AVG  parent entry
   GRAI_MOM_D    = 4, // GRP_STEP_LAYER  continuation only
   GRAI_MOM_P    = 5  // PANIC short flush
};

enum ENUM_GRAI_EVENT_ROLE
{
   GRAI_ROLE_PARENT_ENTRY      = 0,
   GRAI_ROLE_LAYER_CONTINUATION = 1
};

enum ENUM_GRAI_LAYER_MODE
{
   GRAI_LAYER_NONE     = 0,
   GRAI_LAYER_PYRAMID  = 1,
   GRAI_LAYER_ADVERSE  = 2  // research only; OFF live
};

enum ENUM_GRAI_REGIME
{
   GRAI_REG_UNKNOWN      = 0,
   GRAI_REG_TREND_UP     = 1,
   GRAI_REG_TREND_DOWN   = 2,
   GRAI_REG_RANGE        = 3,
   GRAI_REG_HIGH_VOL     = 4,
   GRAI_REG_LOW_VOL      = 5,
   GRAI_REG_ABNORMAL     = 6
};

enum ENUM_GRAI_CLASS
{
   GRAI_CLASS_UNCONFIRMED = 0,
   GRAI_CLASS_LPM         = 1,
   GRAI_CLASS_MPM         = 2,
   GRAI_CLASS_HPM         = 3
};

enum ENUM_GRAI_DECISION
{
   GRAI_DEC_WAIT         = 0,
   GRAI_DEC_BUY          = 1, // legacy; match cmd at gate
   GRAI_DEC_SELL         = 2,
   GRAI_DEC_REDUCE_LAYER = 3, // legacy → treat as REDUCE_FUTURE
   GRAI_DEC_HALT         = 4, // legacy → treat as HALT_NEW
   GRAI_DEC_CONFIRM      = 5,
   GRAI_DEC_REDUCE_FUTURE = 6,
   GRAI_DEC_HALT_NEW     = 7
};

enum ENUM_GRAI_BIAS
{
   GRAI_BIAS_FLAT  = 0, // D1/H4 disagree or invalid → WAIT
   GRAI_BIAS_LONG  = 1, // D1 SMA200 + H4 EMA200 bullish
   GRAI_BIAS_SHORT = 2  // D1 SMA200 + H4 EMA200 bearish
};

struct GRAI_Episode
{
   ulong    episode_id;
   int      parent_momentum; // ENUM_GRAI_MOMENTUM A/B/C
   int      direction;       // OP_BUY / OP_SELL
   int      regime_at_start;
   int      bias_at_start;   // ENUM_GRAI_BIAS
   double   equity_at_open;
   datetime start_time;
   datetime end_time;
   int      layer_count;
   double   total_risk_budget;
   double   remaining_risk;
   double   max_floating_loss;
   double   realized_profit;
   string   exit_reason;
   bool     active;
};

#endif
