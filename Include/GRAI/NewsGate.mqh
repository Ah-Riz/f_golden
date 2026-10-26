//+------------------------------------------------------------------+
//| GRAI NewsGate — GRP hours ∪ ±30m CPI/NFP/FOMC CSV                 |
//+------------------------------------------------------------------+
#ifndef GRAI_NEWS_GATE_MQH
#define GRAI_NEWS_GATE_MQH

#include "AuditLog.mqh"

#define GRAI_NEWS_MAX 512

datetime g_grai_news_times[];
int      g_grai_news_count = 0;
bool     g_grai_news_loaded = false;
string   g_grai_news_file = "grai_high_impact_us.csv";
int      g_grai_news_pad_sec = 30 * 60; // ±30 minutes

void GRAI_NewsReset()
{
   ArrayResize(g_grai_news_times, 0);
   g_grai_news_count = 0;
   g_grai_news_loaded = false;
}

bool GRAI_NewsLoadCsv(const string filename)
{
   GRAI_NewsReset();
   g_grai_news_file = filename;
   int h = FileOpen(filename, FILE_READ | FILE_TXT | FILE_ANSI | FILE_SHARE_READ);
   if(h == INVALID_HANDLE)
   {
      GRAI_Log("NEWS", StringFormat("csv_missing file=%s err=%d", filename, GetLastError()));
      g_grai_news_loaded = true; // don't retry every tick
      return false;
   }
   datetime times[];
   ArrayResize(times, 0);
   while(!FileIsEnding(h) && ArraySize(times) < GRAI_NEWS_MAX)
   {
      string line = FileReadString(h);
      StringTrimLeft(line);
      StringTrimRight(line);
      if(StringLen(line) < 8 || StringGetCharacter(line, 0) == ';')
         continue;
      // formats: YYYY.MM.DD HH:MM | YYYY-MM-DD HH:MM | unix
      datetime t = 0;
      if(StringFind(line, ".") > 0 || StringFind(line, "-") > 0)
      {
         string s = line;
         StringReplace(s, "-", ".");
         // take first 16 chars "YYYY.MM.DD HH:MM"
         if(StringLen(s) >= 16)
            t = StringToTime(StringSubstr(s, 0, 16));
         else
            t = StringToTime(s);
      }
      else
         t = (datetime)StringToInteger(line);
      if(t > 0)
      {
         int n = ArraySize(times);
         ArrayResize(times, n + 1);
         times[n] = t;
      }
   }
   FileClose(h);
   ArrayCopy(g_grai_news_times, times);
   g_grai_news_count = ArraySize(g_grai_news_times);
   g_grai_news_loaded = true;
   GRAI_Log("NEWS", StringFormat("loaded=%d file=%s", g_grai_news_count, filename));
   return (g_grai_news_count > 0);
}

bool GRAI_NewsParentBlackout(const datetime now)
{
   if(!g_grai_news_loaded)
      GRAI_NewsLoadCsv(g_grai_news_file);
   for(int i = 0; i < g_grai_news_count; i++)
   {
      datetime ev = g_grai_news_times[i];
      if(now >= ev - g_grai_news_pad_sec && now <= ev + g_grai_news_pad_sec)
         return true;
   }
   return false;
}

// grp_clear: true when GRP hours gate allows trading (Ib_046F0 style)
bool GRAI_NewsUnionBlackout(const bool use_parent30, const bool grp_clear,
                            const bool spike_bar, const datetime now)
{
   if(spike_bar)
      return true;
   if(!grp_clear)
      return true;
   if(use_parent30 && GRAI_NewsParentBlackout(now))
      return true;
   return false;
}

#endif
