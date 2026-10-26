"""GRAI GLM advisory schema v0.3.4 — AND-gate actions + legacy BUY/SELL compat."""
from __future__ import annotations

ALLOWED_DECISIONS_V034 = {
    "CONFIRM",
    "WAIT",
    "REDUCE_FUTURE_LAYERS",
    "HALT_NEW_ENTRIES",
}
ALLOWED_DECISIONS_LEGACY = {"BUY", "SELL", "REDUCE_LAYER", "HALT"}
ALLOWED_DECISIONS = ALLOWED_DECISIONS_V034 | ALLOWED_DECISIONS_LEGACY
ALLOWED_DIRECTIONS = {"BUY", "SELL", "NONE"}
ALLOWED_MOMENTUM = {"MOM_A", "MOM_B", "MOM_C", "MOM_D", "NONE"}
ALLOWED_REGIME = {
    "TREND_UP", "TREND_DOWN", "RANGE",
    "HIGH_VOLATILITY", "LOW_VOLATILITY", "ABNORMAL", "UNKNOWN",
}
ALLOWED_DQ = {"VALID", "INCOMPLETE", "CONFLICTING", "INVALID"}
SCHEMA_VERSION = "grai.glm.v0.3.4"


def normalize_advice(obj: dict, *, deterministic_direction: str | None = None) -> dict:
    # Mutates obj in place (validate_advice relies on this).
    for field in (
        "decision", "direction", "selected_momentum_id",
        "regime_assessment", "data_quality_status",
    ):
        val = obj.get(field)
        if isinstance(val, str):
            obj[field] = val.upper()
    dec = obj.get("decision")
    if dec == "REDUCE_LAYER":
        obj["decision"] = "REDUCE_FUTURE_LAYERS"
        dec = "REDUCE_FUTURE_LAYERS"
    elif dec == "HALT":
        obj["decision"] = "HALT_NEW_ENTRIES"
        dec = "HALT_NEW_ENTRIES"
    det = (deterministic_direction or "").upper()
    if dec in ("BUY", "SELL") and det in ("BUY", "SELL"):
        if dec == det:
            obj["decision"] = "CONFIRM"
            obj["direction"] = det
        else:
            obj["decision"] = "WAIT"
            obj["direction"] = "NONE"
            obj["recommended_max_layers"] = 0
    return obj


def validate_advice(
    obj: dict,
    request_id: str,
    det_max_layers: int,
    *,
    deterministic_direction: str | None = None,
) -> tuple[bool, str]:
    if not isinstance(obj, dict):
        return False, "not_object"
    if obj.get("request_id") != request_id:
        return False, "request_id_mismatch"
    normalize_advice(obj, deterministic_direction=deterministic_direction)
    decision = obj.get("decision")
    if decision not in ALLOWED_DECISIONS:
        return False, "bad_decision"
    direction = obj.get("direction", "NONE")
    if direction not in ALLOWED_DIRECTIONS:
        return False, "bad_direction"
    if decision in ("BUY", "SELL") and direction not in (decision,):
        return False, "direction_conflict"
    mid = obj.get("selected_momentum_id", "NONE")
    if mid not in ALLOWED_MOMENTUM:
        return False, "bad_momentum"
    regime = obj.get("regime_assessment", "UNKNOWN")
    if regime not in ALLOWED_REGIME:
        return False, "bad_regime"
    layers = obj.get("recommended_max_layers")
    if not isinstance(layers, int) or layers < 0 or layers > det_max_layers:
        return False, "bad_layers"
    conf = obj.get("confidence")
    if not isinstance(conf, (int, float)) or conf < 0.0 or conf > 1.0:
        return False, "bad_confidence"
    dq = obj.get("data_quality_status", "VALID")
    if dq not in ALLOWED_DQ:
        return False, "bad_dq"
    if dq == "INVALID":
        return False, "dq_invalid"
    return True, "ok"


if __name__ == "__main__":
    ok, reason = validate_advice(
        {
            "request_id": "r1", "decision": "WAIT", "direction": "NONE",
            "selected_momentum_id": "NONE", "regime_assessment": "UNKNOWN",
            "recommended_max_layers": 0, "confidence": 0.0,
            "data_quality_status": "VALID",
        },
        "r1", 5,
    )
    assert ok and reason == "ok", reason
    o = {
        "request_id": "r2", "decision": "BUY", "direction": "BUY",
        "selected_momentum_id": "MOM_C", "regime_assessment": "TREND_UP",
        "recommended_max_layers": 2, "confidence": 0.7,
        "data_quality_status": "VALID",
    }
    ok, reason = validate_advice(o, "r2", 5, deterministic_direction="BUY")
    assert ok and o["decision"] == "CONFIRM", (reason, o)
    o2 = {
        "request_id": "r3", "decision": "SELL", "direction": "SELL",
        "selected_momentum_id": "MOM_C", "regime_assessment": "TREND_DOWN",
        "recommended_max_layers": 2, "confidence": 0.7,
        "data_quality_status": "VALID",
    }
    ok, reason = validate_advice(o2, "r3", 5, deterministic_direction="BUY")
    assert ok and o2["decision"] == "WAIT", (reason, o2)
    bad, _ = validate_advice({"request_id": "x", "decision": "BUY"}, "r1", 5)
    assert not bad
    print("schema self-check OK", SCHEMA_VERSION)
