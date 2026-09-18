#!/bin/bash
#
# Copyright 2026 shing1211
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -e

SHUTDOWN_TIMEOUT=30

shutdown() {
    echo "Received signal, initiating graceful shutdown..."
    if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
        kill -TERM "$PID" 2>/dev/null
        for _ in $(seq 1 "$SHUTDOWN_TIMEOUT"); do
            if ! kill -0 "$PID" 2>/dev/null; then
                echo "Process stopped gracefully"
                exit 0
            fi
            sleep 1
        done
        echo "Timeout, forcing stop..."
        kill -9 "$PID" 2>/dev/null
    fi
    exit 0
}

trap shutdown SIGTERM SIGINT SIGHUP

# FutuOpenD does NOT expand ${VAR} itself, so render the config template here.
# Defaults are exported first so ${VAR} placeholders always resolve.
CONFIG=/usr/local/bin/FutuOpenD.xml
: "${FUTU_IP:=0.0.0.0}"
: "${FUTU_API_PORT:=11111}"
: "${FUTU_LANG:=en}"
: "${FUTU_LOG_LEVEL:=info}"
: "${FUTU_PUSH_PROTO:=0}"
: "${FUTU_TELNET_IP:=0.0.0.0}"
: "${FUTU_TELNET_PORT:=22222}"
: "${FUTU_PRICE_REMINDER:=1}"
: "${FUTU_FUTURE_TZ:=UTC+8}"
: "${FUTU_RSA_KEY:=}"
export FUTU_IP FUTU_API_PORT FUTU_LANG FUTU_LOG_LEVEL FUTU_PUSH_PROTO \
       FUTU_TELNET_IP FUTU_TELNET_PORT FUTU_PRICE_REMINDER FUTU_FUTURE_TZ FUTU_RSA_KEY

if [ -f "$CONFIG" ] && grep -q '\${' "$CONFIG" 2>/dev/null; then
    echo "[entrypoint] Rendering config template with envsubst."
    envsubst < "$CONFIG" > /tmp/FutuOpenD.xml
    CONFIG=/tmp/FutuOpenD.xml
fi

args=("-cfg_file=${CONFIG}")
if [ -n "${FUTU_ACCOUNT:-}" ]; then
    echo "[entrypoint] Starting FutuOpenD with remember-login for account: ${FUTU_ACCOUNT}"
    args+=("-login_account=${FUTU_ACCOUNT}" "-login_by_remember=1")
    args+=("-area_code=${FUTU_AREA_CODE:-+852}")
else
    echo "[entrypoint] FUTU_ACCOUNT not set. Starting FutuOpenD for interactive first login."
    echo "[entrypoint] Log in once and choose remember; the credential is cached in the data volume."
fi

if [ -n "${FUTU_WS_PORT:-}" ]; then
    echo "[entrypoint] Enabling WebSocket on ${FUTU_WS_IP:-0.0.0.0}:${FUTU_WS_PORT}"
    args+=("-websocket_ip=${FUTU_WS_IP:-0.0.0.0}" "-websocket_port=${FUTU_WS_PORT}")
    if [ -n "${FUTU_WS_CERT:-}" ] && [ -n "${FUTU_WS_KEY:-}" ]; then
        args+=("-websocket_cert=${FUTU_WS_CERT}" "-websocket_private_key=${FUTU_WS_KEY}")
    fi
fi

args+=("-no_monitor=${FUTU_NO_MONITOR:-1}")

/usr/local/bin/FutuOpenD "${args[@]}" "$@" &
PID=$!

echo "FutuOpenD started with PID $PID"
wait $PID