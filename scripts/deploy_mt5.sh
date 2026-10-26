#!/usr/bin/env bash
# Export Gold Rush AI EA(s) → Wine MetaTrader 5 tree + optional compile.
#
# Usage:
#   bash scripts/deploy_mt5.sh [--compile]              # all gold_rush_AI_*.mq5
#   bash scripts/deploy_mt5.sh [--compile] [VER ...]
#   bash scripts/deploy_mt5.sh [--compile] --family v0.3
#   bash scripts/deploy_mt5.sh [--compile] --all         # same as default
#   bash scripts/deploy_mt5.sh [--compile] --indicator   # SMC_Lana + SMC_Lana_OB
#   bash scripts/deploy_mt5.sh --list
#
# VER = stem after gold_rush_AI_ (must match an existing .mq5).
# Default (no VER): every root gold_rush_AI_*.mq5 + matching sets/*.set
# Related siblings are auto-added when a VER is named:
#   VER ↔ VER_smc ,  VER ↔ VER_short
# Env: MT5_ROOT, WINEPREFIX
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MT5="${MT5_ROOT:-/home/lana/.mt5/drive_c/Program Files/MetaTrader 5}"
EXPERTS="$MT5/MQL5/Experts/gold_rush_AI"
PRESETS="$MT5/MQL5/Presets/gold_rush_AI"
INDICATORS="$MT5/MQL5/Indicators"
INCLUDE_DST="$MT5/MQL5/Include"
COMPAT_DST="$MT5/MQL5/Experts/Include"
FILES_DST="$MT5/MQL5/Files"
COMPAT_SRC="${MT4COMPAT:-/home/lana/Documents/work/forex/Include/MT4Compat.mqh}"

usage() {
  cat <<'EOF'
Export Gold Rush AI → Wine MT5 (+ optional MetaEditor compile).

  bash scripts/deploy_mt5.sh [--compile]              # all gold_rush_AI_*.mq5
  bash scripts/deploy_mt5.sh [--compile] [VER ...]
  bash scripts/deploy_mt5.sh [--compile] --family PREFIX
  bash scripts/deploy_mt5.sh [--compile] --ea FILE.mq5 [...]
  bash scripts/deploy_mt5.sh [--compile] --all         # same as bare default
  bash scripts/deploy_mt5.sh [--compile] --indicator   # SMC_Lana + SMC_Lana_OB
  bash scripts/deploy_mt5.sh --list

VER examples: v0.4  v0.3  v0.2  v0.1
--family v0.3  → gold_rush_AI_v0.3.mq5 (+ any gold_rush_AI_v0.3_*.mq5 if present)
--ea FILE.mq5  → deploy a root-level EA outside the gold_rush_AI_ naming
--indicator    → SMC_Lana + SMC_Lana_OB (+ Include/SMC_Lana*, Include/SMC_Lana_OB*)
Default (no VER): all root gold_rush_AI_*.mq5 (+ gold_rush_pro_Fixed.mq5 if present)
EOF
}

_compile_indicator() {
  local stem="$1"
  local log="$INDICATORS/${stem}.log"
  rm -f "$log" "$INDICATORS/${stem}.ex5"
  export WINEPREFIX="${WINEPREFIX:-/home/lana/.mt5}"
  ( cd "$MT5" && wine start /wait MetaEditor64.exe \
      "/compile:MQL5\\Indicators\\${stem}.mq5" \
      "/log:MQL5\\Indicators\\${stem}.log" ) || true
  if [[ -f "$INDICATORS/${stem}.ex5" ]]; then
    echo "COMPILE OK → $INDICATORS/${stem}.ex5 ($(wc -c < "$INDICATORS/${stem}.ex5") bytes)"
    iconv -f UTF-16 -t UTF-8 "$log" 2>/dev/null | grep -E "Result:" || true
    return 0
  fi
  echo "COMPILE FAIL — ${stem}.mq5 log:"
  [[ -f "$log" ]] && iconv -f UTF-16 -t UTF-8 "$log" 2>/dev/null | grep -E "error |Result:" | tail -40 || true
  return 1
}

deploy_smc_indicator() {
  local do_compile="${1:-0}"
  local fail=0
  mkdir -p "$INDICATORS" "$INCLUDE_DST/SMC_Lana" "$INCLUDE_DST/SMC_Lana_OB"

  if [[ ! -f "$ROOT/Indicators/SMC_Lana.mq5" ]]; then
    echo "ERROR: Indicators/SMC_Lana.mq5 missing" >&2
    return 1
  fi
  cp -f "$ROOT/Indicators/SMC_Lana.mq5" "$INDICATORS/"
  cp -f "$ROOT/Include/SMC_Lana/"*.mqh "$INCLUDE_DST/SMC_Lana/"
  echo "Indicator → $INDICATORS/SMC_Lana.mq5"
  echo "Include   → $INCLUDE_DST/SMC_Lana/ ($(ls "$ROOT/Include/SMC_Lana/"*.mqh | wc -l) files)"

  if [[ -f "$ROOT/Indicators/SMC_Lana_OB.mq5" ]]; then
    cp -f "$ROOT/Indicators/SMC_Lana_OB.mq5" "$INDICATORS/"
    cp -f "$ROOT/Include/SMC_Lana_OB/"*.mqh "$INCLUDE_DST/SMC_Lana_OB/"
    echo "Indicator → $INDICATORS/SMC_Lana_OB.mq5"
    echo "Include   → $INCLUDE_DST/SMC_Lana_OB/ ($(ls "$ROOT/Include/SMC_Lana_OB/"*.mqh | wc -l) files)"
  fi

  if [[ "$do_compile" -eq 1 ]]; then
    _compile_indicator "SMC_Lana" || fail=1
    if [[ -f "$INDICATORS/SMC_Lana_OB.mq5" ]]; then
      _compile_indicator "SMC_Lana_OB" || fail=1
    fi
    return "$fail"
  fi
  return 0
}

ea_path() { echo "$ROOT/gold_rush_AI_${1}.mq5"; }

list_versions() {
  local f stem
  shopt -s nullglob
  for f in "$ROOT"/gold_rush_AI_*.mq5; do
    stem="$(basename "$f" .mq5)"
    stem="${stem#gold_rush_AI_}"
    printf '%s\n' "$stem"
  done | sort -u
}

version_exists() {
  [[ -f "$(ea_path "$1")" ]]
}

# Collect unique versions (nameref-style via global array DEPLOY_VERS)
DEPLOY_VERS=()
_add_ver() {
  local v="$1" x
  [[ -z "$v" ]] && return 0
  if ! version_exists "$v"; then
    echo "WARN: skip unknown VER=$v (no $(ea_path "$v"))" >&2
    return 0
  fi
  for x in "${DEPLOY_VERS[@]+"${DEPLOY_VERS[@]}"}"; do
    [[ "$x" == "$v" ]] && return 0
  done
  DEPLOY_VERS+=("$v")
}

# Auto-pair smc / short siblings when the .mq5 exists
_add_related() {
  local v="$1" base
  _add_ver "$v"
  if version_exists "${v}_smc"; then _add_ver "${v}_smc"; fi
  if version_exists "${v}_short"; then _add_ver "${v}_short"; fi
  if [[ "$v" == *_smc ]]; then
    base="${v%_smc}"
    version_exists "$base" && _add_ver "$base"
  fi
  if [[ "$v" == *_short ]]; then
    base="${v%_short}"
    version_exists "$base" && _add_ver "$base"
  fi
}

_add_family() {
  local prefix="$1" f stem
  shopt -s nullglob
  # Exact PREFIX.mq5
  if version_exists "$prefix"; then _add_ver "$prefix"; fi
  # PREFIX_*.mq5 (legacy forks if any remain)
  for f in "$ROOT"/gold_rush_AI_"${prefix}"_*.mq5; do
    stem="$(basename "$f" .mq5)"
    stem="${stem#gold_rush_AI_}"
    _add_ver "$stem"
  done
  if ((${#DEPLOY_VERS[@]} == 0)); then
    echo "ERROR: --family $prefix matched no gold_rush_AI_${prefix}*.mq5" >&2
    exit 1
  fi
}

# --- args ---
COMPILE=0
DO_ALL=0
DO_LIST=0
DO_INDICATOR=0
FAMILY=""
RAW_VERS=()
EXTRA_EAS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --list) DO_LIST=1; shift ;;
    --compile) COMPILE=1; shift ;;
    --indicator) DO_INDICATOR=1; shift ;;
    --all) DO_ALL=1; shift ;;
    --family)
      shift
      [[ $# -ge 1 ]] || { echo "ERROR: --family needs PREFIX" >&2; exit 1; }
      FAMILY="$1"; shift
      ;;
    --family=*)
      FAMILY="${1#--family=}"; shift
      ;;
    --ea)
      shift
      [[ $# -ge 1 ]] || { echo "ERROR: --ea needs FILE.mq5" >&2; exit 1; }
      EXTRA_EAS+=("$1"); shift
      ;;
    --ea=*)
      EXTRA_EAS+=("${1#--ea=}"); shift
      ;;
    -*)
      echo "ERROR: unknown flag $1" >&2
      usage >&2
      exit 1
      ;;
    *)
      RAW_VERS+=("$1"); shift
      ;;
  esac
done

if [[ "$DO_LIST" -eq 1 ]]; then
  echo "Available VER stems in $ROOT:"
  list_versions | sed 's/^/  /'
  echo "Indicators: SMC_Lana + SMC_Lana_OB (--indicator)"
  exit 0
fi

# Indicator-only path
if [[ "$DO_INDICATOR" -eq 1 && "$DO_ALL" -eq 0 && -z "$FAMILY" && ${#RAW_VERS[@]} -eq 0 && ${#EXTRA_EAS[@]} -eq 0 ]]; then
  echo "ROOT=$ROOT"
  echo "MT5=$MT5"
  echo "MODE=indicator"
  deploy_smc_indicator "$COMPILE"
  exit $?
fi

if [[ "$DO_ALL" -eq 1 ]]; then
  # --all: every gold_rush_AI_*.mq5 in repo root
  while IFS= read -r v; do _add_ver "$v"; done < <(list_versions)
elif [[ -n "$FAMILY" ]]; then
  _add_family "$FAMILY"
elif ((${#RAW_VERS[@]} > 0)); then
  for v in "${RAW_VERS[@]}"; do _add_related "$v"; done
elif ((${#EXTRA_EAS[@]} > 0)); then
  : # --ea only: skip gold_rush_AI_* VER deploy; EXTRA_EAS handled below
else
  # Bare default (no args): every gold_rush_AI_*.mq5
  while IFS= read -r v; do _add_ver "$v"; done < <(list_versions)
fi

if ((${#DEPLOY_VERS[@]} == 0 && ${#EXTRA_EAS[@]} == 0)); then
  echo "ERROR: nothing to deploy. Try: bash scripts/deploy_mt5.sh --list" >&2
  exit 1
fi
for ea in "${EXTRA_EAS[@]}"; do
  [[ -f "$ROOT/$ea" ]] || { echo "ERROR: --ea $ea not found in $ROOT" >&2; exit 1; }
done

echo "ROOT=$ROOT"
echo "MT5=$MT5"
echo "DEPLOY=${DEPLOY_VERS[*]}"
echo "COMPILE=$COMPILE"

mkdir -p "$EXPERTS/Include/GRAI" "$EXPERTS/Include/SMC_Lana_OB" "$PRESETS" "$COMPAT_DST" "$FILES_DST"

# Always refresh SMC indicator trees when present (EA deploy does not require them)
if [[ -d "$ROOT/Include/SMC_Lana" && -f "$ROOT/Indicators/SMC_Lana.mq5" ]]; then
  deploy_smc_indicator 0 || true
fi

# Shared includes + frozen baseline + news
cp -f "$ROOT/Include/GRAI/"*.mqh "$EXPERTS/Include/GRAI/"
# SMC_Lana_OB engine (v0.3.1 bias) — relative include from Experts/.../Include/GRAI/
if [[ -d "$ROOT/Include/SMC_Lana_OB" ]]; then
  cp -f "$ROOT/Include/SMC_Lana_OB/"*.mqh "$EXPERTS/Include/SMC_Lana_OB/"
  echo "Include   → $EXPERTS/Include/SMC_Lana_OB/ ($(ls -1 "$EXPERTS/Include/SMC_Lana_OB" | wc -l) files)"
fi
if [[ -f "$ROOT/gold_rush_pro_Fixed.mq5" ]]; then
  cp -f "$ROOT/gold_rush_pro_Fixed.mq5" "$EXPERTS/"
fi
if [[ -f "$COMPAT_SRC" ]]; then
  cp -f "$COMPAT_SRC" "$COMPAT_DST/"
fi
if [[ -f "$ROOT/Files/grai_high_impact_us.csv" ]]; then
  cp -f "$ROOT/Files/grai_high_impact_us.csv" "$FILES_DST/"
  # tester agents sandbox FileIsExist() to their own MQL5/Files
  # (agents create MQL5/ lazily, so create + copy for every agent)
  for AGENT in "$MT5"/Tester/Agent-*; do
    [[ -d "$AGENT" ]] || continue
    mkdir -p "$AGENT/MQL5/Files"
    cp -f "$ROOT/Files/grai_high_impact_us.csv" "$AGENT/MQL5/Files/"
  done
fi

# Copy each EA
for VER in "${DEPLOY_VERS[@]}"; do
  EA="gold_rush_AI_${VER}.mq5"
  cp -f "$ROOT/$EA" "$EXPERTS/"
  echo "EA → $EXPERTS/$EA"
done

# Extra root-level EAs (--ea FILE.mq5)
for ea in "${EXTRA_EAS[@]}"; do
  cp -f "$ROOT/$ea" "$EXPERTS/"
  echo "EA → $EXPERTS/$ea"
done

# Presets: sets/<VER>_*.set for each deployed VER (+ common smc_full pins if any VER is v0.3*)
shopt -s nullglob
ALL_SETS=()
for VER in "${DEPLOY_VERS[@]}"; do
  for s in "$ROOT/sets/${VER}"_*.set; do
    ALL_SETS+=("$s")
  done
  # export mirror per VER
  mkdir -p "$ROOT/sets/export_${VER}"
  local_sets=("$ROOT/sets/${VER}"_*.set)
  if ((${#local_sets[@]})); then
    cp -f "${local_sets[@]}" "$ROOT/sets/export_${VER}/" 2>/dev/null || true
  fi
done
# Presets for --ea gold_rush_pro_Fixed_001.mq5 → sets/Fixed_001_*.set
for ea in "${EXTRA_EAS[@]+"${EXTRA_EAS[@]}"}"; do
  if [[ "$ea" == "gold_rush_pro_Fixed_001.mq5" ]]; then
    for s in "$ROOT"/sets/Fixed_001_*.set; do
      ALL_SETS+=("$s")
    done
    mkdir -p "$ROOT/sets/export_Fixed_001"
    local_fixed=("$ROOT"/sets/Fixed_001_*.set)
    if ((${#local_fixed[@]})); then
      cp -f "${local_fixed[@]}" "$ROOT/sets/export_Fixed_001/" 2>/dev/null || true
    fi
  fi
done
# Deduplicate set paths
if ((${#ALL_SETS[@]})); then
  mapfile -t ALL_SETS < <(printf '%s\n' "${ALL_SETS[@]}" | sort -u)
  cp -f "${ALL_SETS[@]}" "$PRESETS/" 2>/dev/null || true
  echo "Presets → $PRESETS ($(printf '%s\n' "${ALL_SETS[@]}" | wc -l) files)"
  printf '  %s\n' "${ALL_SETS[@]##*/}"
fi

compile_one() {
  local ea_file="$1"
  local base="${ea_file%.mq5}"
  local log="$EXPERTS/${base}.log"
  rm -f "$log" "$EXPERTS/${base}.ex5"
  export WINEPREFIX="${WINEPREFIX:-/home/lana/.mt5}"
  ( cd "$MT5" && wine start /wait MetaEditor64.exe \
      "/compile:MQL5\\Experts\\gold_rush_AI\\${ea_file}" \
      "/log:MQL5\\Experts\\gold_rush_AI\\${base}.log" ) || true
  if [[ -f "$EXPERTS/${base}.ex5" ]]; then
    echo "COMPILE OK → $EXPERTS/${base}.ex5 ($(wc -c < "$EXPERTS/${base}.ex5") bytes)"
    iconv -f UTF-16 -t UTF-8 "$log" 2>/dev/null | grep -E "Result:" || true
    return 0
  fi
  echo "COMPILE FAIL — $ea_file log:"
  [[ -f "$log" ]] && iconv -f UTF-16 -t UTF-8 "$log" 2>/dev/null | grep -E "error |Result:" | tail -40 || true
  return 1
}

if [[ "$COMPILE" -eq 1 ]]; then
  fail=0
  for VER in "${DEPLOY_VERS[@]}"; do
    compile_one "gold_rush_AI_${VER}.mq5" || fail=1
  done
  for ea in "${EXTRA_EAS[@]}"; do
    compile_one "$ea" || fail=1
  done
  [[ "$fail" -eq 0 ]] || exit 1
fi

echo "Done. Experts: $EXPERTS"
echo "Presets: $PRESETS"
echo "Tip: bash scripts/deploy_mt5.sh --compile | --list | v0.4 --compile"
