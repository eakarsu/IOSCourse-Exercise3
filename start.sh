#!/usr/bin/env bash
set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="$PROJECT_DIR/.env"
load_env_file(){ local line key value;while IFS= read -r line||[ -n "$line" ];do [[ "$line" =~ ^[[:space:]]*# || "$line" =~ ^[[:space:]]*$ ]]&&continue;line="${line#export }";key="${line%%=*}";value="${line#*=}";key="${key//[[:space:]]/}";[[ "$key" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]||continue;[ -n "${!key+x}" ]&&continue;if [[ "$value" == \"*\" && "$value" == *\" ]];then value="${value:1:${#value}-2}";elif [[ "$value" == \'*\' && "$value" == *\' ]];then value="${value:1:${#value}-2}";fi;export "$key=$value";done < "$ENV_FILE"; }
[ -f "$ENV_FILE" ]||{ echo "Missing required file: $ENV_FILE" >&2;exit 1; };load_env_file
: "${BACKEND_PORT:?BACKEND_PORT is required}";: "${FRONTEND_PORT:?FRONTEND_PORT is required}";: "${DATABASE_URL:?DATABASE_URL is required}"
: "${OPENROUTER_API_KEY:?OPENROUTER_API_KEY is required}";: "${OPENROUTER_MODEL:?OPENROUTER_MODEL is required}";: "${OPENROUTER_BASE_URL:?OPENROUTER_BASE_URL is required}"
for assigned_port in "$BACKEND_PORT" "$FRONTEND_PORT";do lsof -nP -iTCP:"$assigned_port" -sTCP:LISTEN >/dev/null 2>&1&&{ echo "Assigned port $assigned_port is occupied" >&2;exit 1; };done
node "$PROJECT_DIR/runtime/setup.mjs"
node "$PROJECT_DIR/runtime/api.mjs" & API_PID=$!
node "$PROJECT_DIR/runtime/ui.mjs" & UI_PID=$!
cleanup(){ trap - EXIT INT TERM;kill "$API_PID" "$UI_PID" 2>/dev/null||true;wait "$API_PID" "$UI_PID" 2>/dev/null||true; }
trap cleanup EXIT INT TERM
wait "$API_PID" "$UI_PID"
