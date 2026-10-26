//+------------------------------------------------------------------+
//| GRAI LlmBridge v0.2 — WebRequest (live) / file (Tester); AND-gate  |
//+------------------------------------------------------------------+
#ifndef GRAI_LLM_BRIDGE_MQH
#define GRAI_LLM_BRIDGE_MQH

#include "AuditLog.mqh"
#include "Types.mqh"
#include "Features.mqh"

struct GRAI_GlmAdvice
{
   bool     valid;
   int      decision; // ENUM_GRAI_DECISION
   int      recommended_max_layers;
   double   confidence;
   string   request_id;
   string   failure_code;
   datetime bar_time;
};

string        g_grai_last_request_id = "";
string        g_grai_bridge_url      = "http://127.0.0.1:8765/advise";
string        g_grai_bridge_token    = "";
int           g_grai_timeout_ms      = 1000;
int           g_grai_file_fail_streak = 0;   // Tester file transport: consecutive FILE_TIMEOUTs
uint          g_grai_file_last_try   = 0;    // circuit breaker: last attempt tick (re-probe pacing)
string        g_grai_schema_version  = "grai.glm.v0.3";
string        g_grai_prompt_version  = "grai.prompt.v0.2";
GRAI_GlmAdvice g_grai_advice_bar;
datetime      g_grai_advice_bar_time = 0;

GRAI_GlmAdvice GRAI_GlmWait(const string code, const bool emit_log = true)
{
   GRAI_GlmAdvice a;
   ZeroMemory(a);
   a.valid = false;
   a.decision = GRAI_DEC_WAIT;
   a.recommended_max_layers = 0;
   a.failure_code = code;
   if(emit_log)
      GRAI_Log(code, "WAIT");
   return a;
}

// Layered fail: BOT = WebRequest/MT5, AUTH = bridge token, API = GLM provider
GRAI_GlmAdvice GRAI_FailWait(const string layer, const string code, const string detail)
{
   GRAI_Log("LLM_FAIL", StringFormat("layer=%s code=%s %s", layer, code, detail));
   return GRAI_GlmWait(code, false);
}

void GRAI_AdviceClear()
{
   ZeroMemory(g_grai_advice_bar);
   g_grai_advice_bar.valid = false;
   g_grai_advice_bar.decision = GRAI_DEC_WAIT;
   g_grai_advice_bar_time = 0;
}

void GRAI_AdviceStore(const GRAI_GlmAdvice &a, const datetime bar_time)
{
   g_grai_advice_bar = a;
   g_grai_advice_bar.bar_time = bar_time;
   g_grai_advice_bar_time = bar_time;
}

// AND gate: Fixed cmd (OP_BUY/OP_SELL) must match GLM decision for this bar
bool GRAI_GlmAllowsCmd(const int cmd, const bool llm_enabled, const bool det_fallback)
{
   if(!llm_enabled)
      return true;
   if(g_grai_advice_bar_time == 0 || !g_grai_advice_bar.valid)
   {
      if(det_fallback) return true;
      GRAI_Log("SKIP", "glm_wait no_advice");
      return false;
   }
   if(g_grai_advice_bar.decision == GRAI_DEC_WAIT ||
      g_grai_advice_bar.decision == GRAI_DEC_HALT ||
      g_grai_advice_bar.recommended_max_layers <= 0)
   {
      if(det_fallback) return true;
      GRAI_Log("SKIP", StringFormat("glm_wait code=%s", g_grai_advice_bar.failure_code));
      return false;
   }
   if(cmd == OP_BUY && g_grai_advice_bar.decision != GRAI_DEC_BUY)
   {
      GRAI_Log("SKIP", "glm_mismatch want=BUY");
      return false;
   }
   if(cmd == OP_SELL && g_grai_advice_bar.decision != GRAI_DEC_SELL)
   {
      GRAI_Log("SKIP", "glm_mismatch want=SELL");
      return false;
   }
   return true;
}

bool GRAI_JsonGetString(const string json, const string key, string &out)
{
   string pat = "\"" + key + "\"";
   int p = StringFind(json, pat);
   if(p < 0) return false;
   int colon = StringFind(json, ":", p);
   if(colon < 0) return false;
   int q1 = StringFind(json, "\"", colon + 1);
   if(q1 < 0) return false;
   int q2 = StringFind(json, "\"", q1 + 1);
   if(q2 < 0) return false;
   out = StringSubstr(json, q1 + 1, q2 - q1 - 1);
   return true;
}

bool GRAI_JsonGetInt(const string json, const string key, int &out)
{
   string pat = "\"" + key + "\"";
   int p = StringFind(json, pat);
   if(p < 0) return false;
   int colon = StringFind(json, ":", p);
   if(colon < 0) return false;
   string rest = StringSubstr(json, colon + 1);
   StringTrimLeft(rest);
   out = (int)StringToInteger(rest);
   return true;
}

bool GRAI_JsonGetDouble(const string json, const string key, double &out)
{
   string pat = "\"" + key + "\"";
   int p = StringFind(json, pat);
   if(p < 0) return false;
   int colon = StringFind(json, ":", p);
   if(colon < 0) return false;
   string rest = StringSubstr(json, colon + 1);
   StringTrimLeft(rest);
   out = StringToDouble(rest);
   return true;
}

int GRAI_MapDecision(const string d)
{
   if(d == "BUY") return GRAI_DEC_BUY;
   if(d == "SELL") return GRAI_DEC_SELL;
   if(d == "REDUCE_LAYER") return GRAI_DEC_REDUCE_LAYER;
   if(d == "HALT") return GRAI_DEC_HALT;
   return GRAI_DEC_WAIT;
}

string GRAI_BuildAdviseBody(const GRAI_FeatureSnap &snap)
{
   return GRAI_BuildFeatureJson(snap);
}

// Legacy thin builder kept for compile compatibility
string GRAI_BuildAdviseBody(const string request_id, const string symbol,
                            const datetime bar_time, const double bid,
                            const double ask, const int regime,
                            const int det_max_layers)
{
   GRAI_FeatureSnap s;
   ZeroMemory(s);
   s.request_id = request_id;
   s.symbol = symbol;
   s.bar_time = bar_time;
   s.bid = bid;
   s.ask = ask;
   s.spread = (ask - bid) / _Point;
   s.regime = regime;
   s.session_ok = true;
   s.news_blackout = false;
   s.spike_bar = false;
   s.momentum_id = GRAI_MOM_NONE;
   s.basket_count = 0;
   s.episode_remaining_risk = 0;
   s.deterministic_max_layers = det_max_layers;
   s.data_quality = "VALID";
   return GRAI_BuildFeatureJson(s);
}

// Shared response validation for both transports (WebRequest body / file body).
// http: HTTP code for logs; file transport passes 200.
GRAI_GlmAdvice GRAI_AdviceFromJson(const string json, const string request_id, const int http)
{
   string fail_code = "";
   GRAI_JsonGetString(json, "failure_code", fail_code);
   if(fail_code == "BRIDGE_AUTH")
      return GRAI_FailWait("AUTH", "BRIDGE_401", "http=200 failure=BRIDGE_AUTH");

   string rid = "";
   if(!GRAI_JsonGetString(json, "request_id", rid) || rid != request_id)
      return GRAI_FailWait("BOT", "LLM_STALE",
         StringFormat("http=%d rid_mismatch", http));

   string decision = "";
   if(!GRAI_JsonGetString(json, "decision", decision))
      return GRAI_FailWait("BOT", "LLM_SCHEMA_FAIL",
         StringFormat("http=%d no_decision", http));

   int layers = 0;
   double conf = 0.0;
   GRAI_JsonGetInt(json, "recommended_max_layers", layers);
   GRAI_JsonGetDouble(json, "confidence", conf);

   int dec = GRAI_MapDecision(decision);

   // Provider/bridge WAIT with failure_code → API layer
   if(StringLen(fail_code) > 0 &&
      (dec == GRAI_DEC_WAIT || dec == GRAI_DEC_HALT || layers <= 0))
   {
      return GRAI_FailWait("API", fail_code,
         StringFormat("decision=%s layers=%d http=%d", decision, layers, http));
   }

   GRAI_GlmAdvice a;
   ZeroMemory(a);
   a.valid = true;
   a.request_id = rid;
   a.decision = dec;
   a.recommended_max_layers = layers;
   a.confidence = conf;
   a.failure_code = fail_code;
   GRAI_Log("LLM_RESPONSE", StringFormat(
      "id=%s decision=%s layers=%d conf=%.2f http=%d",
      rid, decision, layers, conf, http));
   return a;
}

#define GRAI_FILE_CIRCUIT 10   // consecutive FILE_TIMEOUTs before fast-fail

// Tester-only transport: WebRequest() is forbidden in the Strategy Tester
// (err=4014 regardless of allowlist), so exchange JSON files with
// python/bridge/watcher.py inside the agent sandbox:
//   grai_bridge/req/<rid>-<nonce>.json  (EA writes, watcher deletes)
//   grai_bridge/resp/<rid>-<nonce>.json (watcher writes, EA deletes)
GRAI_GlmAdvice GRAI_AdviceViaFile(const string request_id, const string body)
{
   // Circuit open → fast-fail, but re-probe every 60s real time so a
   // transient provider/watcher outage doesn't disable GLM for the whole run
   uint now_tick = GetTickCount();
   if(g_grai_file_fail_streak >= GRAI_FILE_CIRCUIT &&
      (uint)(now_tick - g_grai_file_last_try) < 60000)
      return GRAI_FailWait("BOT", "FILE_TIMEOUT", "circuit_open");
   g_grai_file_last_try = now_tick;

   // Per-run nonce, filename only: body request_id stays identical to live runs
   static string s_nonce = "";
   if(s_nonce == "")
   {
      MathSrand((int)GetTickCount());
      s_nonce = StringFormat("%08x", ((uint)MathRand() << 16) | (uint)MathRand());
   }

   string req_name  = "grai_bridge\\req\\"  + request_id + "-" + s_nonce + ".json";
   string resp_name = "grai_bridge\\resp\\" + request_id + "-" + s_nonce + ".json";
   string tmp_name  = req_name + ".tmp";

   FolderCreate("grai_bridge");        // false when exists — fine
   FolderCreate("grai_bridge\\req");
   FolderCreate("grai_bridge\\resp");

   // {"token":..,"payload":..} — token must be quote/backslash-free (hex)
   string envelope = "{\"token\":\"" + g_grai_bridge_token + "\",\"payload\":" + body + "}";

   char data[];
   StringToCharArray(envelope, data, 0, WHOLE_ARRAY, CP_UTF8);
   int n = ArraySize(data);
   if(n > 0 && data[n - 1] == 0)
      ArrayResize(data, n - 1);

   int fh = FileOpen(tmp_name, FILE_WRITE | FILE_BIN);
   if(fh == INVALID_HANDLE)
      return GRAI_FailWait("BOT", "FILE_WRITE_FAIL",
         StringFormat("open tmp err=%d", GetLastError()));
   int written = (int)FileWriteArray(fh, data, 0, ArraySize(data));
   FileClose(fh);
   if(written < ArraySize(data))
      return GRAI_FailWait("BOT", "FILE_WRITE_FAIL",
         StringFormat("write=%d err=%d", written, GetLastError()));
   if(!FileMove(tmp_name, 0, req_name, FILE_REWRITE))
      return GRAI_FailWait("BOT", "FILE_WRITE_FAIL",
         StringFormat("move err=%d", GetLastError()));

   // Real-time poll (Sleep() is emulated in the tester); ~1 stat / 20 ms
   uint timeout = (uint)MathMax(g_grai_timeout_ms, 100);
   uint start = GetTickCount();
   while((uint)(GetTickCount() - start) < timeout)
   {
      if(FileIsExist(resp_name))
      {
         fh = FileOpen(resp_name, FILE_READ | FILE_BIN);
         if(fh == INVALID_HANDLE)
            continue;
         char out[];
         int read = (int)FileReadArray(fh, out, 0, WHOLE_ARRAY);
         FileClose(fh);
         FileDelete(resp_name);
         g_grai_file_fail_streak = 0;
         string json = CharArrayToString(out, 0, read, CP_UTF8);
         return GRAI_AdviceFromJson(json, request_id, 200);
      }
      long t0 = (long)GetMicrosecondCount();
      while(GetMicrosecondCount() - t0 < 20000)
      {
      }
   }

   // No answer in time: cancel the request, count toward circuit breaker
   FileDelete(req_name);
   g_grai_file_fail_streak++;
   return GRAI_FailWait("BOT", "FILE_TIMEOUT",
      StringFormat("id=%s waited=%ums nonce=%s", request_id, timeout, s_nonce));
}

GRAI_GlmAdvice GRAI_RequestAdvice(const string request_id, const string body)
{
   if(g_grai_timeout_ms <= 0)
      return GRAI_FailWait("BOT", "LLM_TIMEOUT", "timeout_ms<=0");

   g_grai_last_request_id = request_id;
   GRAI_Log("LLM_REQUEST", StringFormat(
      "id=%s timeout=%d schema=%s prompt=%s",
      request_id, g_grai_timeout_ms, g_grai_schema_version, g_grai_prompt_version));

   // Tester: WebRequest() banned by the platform (err=4014 regardless of
   // allowlist) — use the file transport instead. Live charts keep WebRequest.
   if(MQLInfoInteger(MQL_TESTER))
   {
      if(MQLInfoInteger(MQL_OPTIMIZATION))
         return GRAI_FailWait("BOT", "OPT_NO_LLM", "file transport disabled in optimization");
      return GRAI_AdviceViaFile(request_id, body);
   }

   char data[];
   char result[];
   string result_headers;
   string headers = "Content-Type: application/json\r\n";
   if(StringLen(g_grai_bridge_token) > 0)
      headers += "X-GRAI-Token: " + g_grai_bridge_token + "\r\n";

   StringToCharArray(body, data, 0, WHOLE_ARRAY, CP_UTF8);
   int n = ArraySize(data);
   if(n > 0 && data[n - 1] == 0)
      ArrayResize(data, n - 1);

   ResetLastError();
   int http = WebRequest("POST", g_grai_bridge_url, headers, g_grai_timeout_ms,
                         data, result, result_headers);
   if(http == -1)
   {
      int err = GetLastError();
      if(err == 4014)
         return GRAI_FailWait("BOT", "WR_DENY",
            StringFormat("err=4014 allowlist %s", g_grai_bridge_url));
      return GRAI_FailWait("BOT", "WR_FAIL", StringFormat("err=%d", err));
   }

   string json = CharArrayToString(result, 0, WHOLE_ARRAY, CP_UTF8);

   // Legacy bare 401 body (pre-BRIDGE_AUTH JSON) or explicit HTTP 401
   if(http == 401)
      return GRAI_FailWait("AUTH", "BRIDGE_401", "http=401");

   return GRAI_AdviceFromJson(json, request_id, http);
}

#endif
