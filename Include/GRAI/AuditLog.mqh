//+------------------------------------------------------------------+
//| GRAI AuditLog — single Print prefix (§9 XAU Experts log rule)     |
//+------------------------------------------------------------------+
#ifndef GRAI_AUDIT_LOG_MQH
#define GRAI_AUDIT_LOG_MQH

string GRAI_LogTag = "GRAI_v01";

void GRAI_Log(const string code, const string msg)
{
   Print("[", GRAI_LogTag, "] ", code, " ", msg);
}

#endif
