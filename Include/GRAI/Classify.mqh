//+------------------------------------------------------------------+
//| LPM/MPM/HPM — episode floors; layers ≠ independent samples        |
//+------------------------------------------------------------------+
#ifndef GRAI_CLASSIFY_MQH
#define GRAI_CLASSIFY_MQH

#include "Types.mqh"
#include "AuditLog.mqh"

int g_grai_min_episodes = 30;

// win_rate on [0,1]; episode_n = independent closed episodes only
int GRAI_Classify(const int episode_n, const double win_rate,
                  const double expectancy_after_costs, const double profit_factor)
{
   if(episode_n < g_grai_min_episodes)
   {
      GRAI_Log("CLASSIFY", StringFormat("UNCONFIRMED n=%d floor=%d", episode_n, g_grai_min_episodes));
      return GRAI_CLASS_UNCONFIRMED;
   }
   if(expectancy_after_costs < 0.0 || profit_factor < 1.0)
   {
      GRAI_Log("CLASSIFY", "LPM expectancy/PF gate");
      return GRAI_CLASS_LPM;
   }
   int cls = GRAI_CLASS_LPM;
   if(win_rate >= 0.50 && win_rate <= 0.75)
      cls = GRAI_CLASS_MPM;
   else if(win_rate > 0.75)
      cls = GRAI_CLASS_HPM;
   GRAI_Log("CLASSIFY", StringFormat("cls=%d wr=%.2f n=%d", cls, win_rate, episode_n));
   return cls;
}

#endif
