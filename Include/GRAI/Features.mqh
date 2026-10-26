//+------------------------------------------------------------------+
//| GRAI Features — FeatureSnapshot builder for GLM v0.2              |
//+------------------------------------------------------------------+
#ifndef GRAI_FEATURES_MQH
#define GRAI_FEATURES_MQH

#include "Types.mqh"

struct GRAI_FeatureSnap
{
   string   opportunity_id;
   string   request_id;
   string   symbol;
   datetime bar_time;
   double   bid;
   double   ask;
   double   spread;
   int      regime;
   bool     session_ok;
   bool     news_blackout;
   bool     spike_bar;
   int      momentum_id; // ENUM_GRAI_MOMENTUM
   int      basket_count;
   double   episode_remaining_risk;
   int      deterministic_max_layers;
   string   data_quality; // VALID | INCOMPLETE | INVALID
};

string GRAI_MomIdStr(const int mom)
{
   if(mom == GRAI_MOM_A) return "MOM_A";
   if(mom == GRAI_MOM_B) return "MOM_B";
   if(mom == GRAI_MOM_C) return "MOM_C";
   if(mom == GRAI_MOM_D) return "MOM_D";
   if(mom == GRAI_MOM_P) return "MOM_P";
   return "NONE";
}

string GRAI_RegimeStr(const int reg)
{
   if(reg == GRAI_REG_TREND_UP) return "TREND_UP";
   if(reg == GRAI_REG_TREND_DOWN) return "TREND_DOWN";
   if(reg == GRAI_REG_RANGE) return "RANGE";
   if(reg == GRAI_REG_HIGH_VOL) return "HIGH_VOLATILITY";
   if(reg == GRAI_REG_LOW_VOL) return "LOW_VOLATILITY";
   if(reg == GRAI_REG_ABNORMAL) return "ABNORMAL";
   return "UNKNOWN";
}

// Heuristic parent momentum from Fixed strategy inputs
int GRAI_GuessParentMomentum(const int set_strategies, const bool set_ema)
{
   if(set_strategies == 2) return GRAI_MOM_C;
   if(set_ema) return GRAI_MOM_B;
   if(set_strategies == 1) return GRAI_MOM_A;
   return GRAI_MOM_NONE;
}

string GRAI_BuildFeatureJson(const GRAI_FeatureSnap &s)
{
   return StringFormat(
      "{\"opportunity_id\":\"%s\",\"request_id\":\"%s\",\"symbol\":\"%s\",\"decision_bar_time\":%s,"
      "\"bid\":%.5f,\"ask\":%.5f,\"spread\":%.1f,\"regime\":%d,\"regime_name\":\"%s\","
      "\"session_ok\":%s,\"news_blackout\":%s,\"spike_bar\":%s,"
      "\"momentum_id\":\"%s\",\"basket_count\":%d,"
      "\"episode_remaining_risk\":%.4f,\"deterministic_max_layers\":%d,"
      "\"data_quality_status\":\"%s\",\"schema_version\":\"grai.glm.v0.3.4\"}",
      s.opportunity_id, s.request_id, s.symbol, IntegerToString((long)s.bar_time),
      s.bid, s.ask, s.spread, s.regime, GRAI_RegimeStr(s.regime),
      (s.session_ok ? "true" : "false"),
      (s.news_blackout ? "true" : "false"),
      (s.spike_bar ? "true" : "false"),
      GRAI_MomIdStr(s.momentum_id), s.basket_count,
      s.episode_remaining_risk, s.deterministic_max_layers,
      s.data_quality);
}

#endif
