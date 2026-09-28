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

DATA_DIR="/home/futuopend/.com.futunn.FutuOpenD"
# FutuOpenD writes one file per account here once a login has been remembered.
# Presence check only: the contents are an encrypted blob, so validity cannot be
# verified without attempting a real login. It reliably catches the common failure
# (remember-login on a fresh or wiped volume) without guessing.
ACCMAP_DIR="${DATA_DIR}/F3CNN/UserAccMap"

# remember-login landed in FutuOpenD 10.10. Older builds silently ignore
# -login_by_remember and fall back to password auth, which under a restart
# policy retries on every crash and burns Futu login attempts.
supports_remember_login() {
    local ver="${FUTU_OPEND_VER:-}"
    [ -n "$ver" ] || return 0
    local major="${ver%%.*}"
    local minor="${ver#*.}"; minor="${minor%%.*}"
    case "${major}${minor}" in
        ''|*[!0-9]*) return 0 ;;
    esac
    [ "$major" -gt 10 ] && return 0
    [ "$major" -lt 10 ] && return 1
    [ "$minor" -ge 10 ] && return 0
    return 1
}

if [ -n "${FUTU_ACCOUNT:-}" ]; then
    # Not overridable: this is the guard against permanently consuming login attempts.
    if ! supports_remember_login; then
        cat >&2 <<EOF
[entrypoint] FATAL: FutuOpenD ${FUTU_OPEND_VER} predates remember-login (10.10+).
[entrypoint] With FUTU_ACCOUNT set, this build ignores -login_by_remember and falls back
[entrypoint] to password auth, retrying on every restart. That consumes Futu login
[entrypoint] attempts and can lock the account. Refusing to start.
[entrypoint] Fix: pull a current image (docker compose pull), or unset FUTU_ACCOUNT and
[entrypoint] complete the interactive first login on a 10.10+ build.
EOF
        exit 78
    fi
    if [ "${FUTU_SKIP_CRED_CHECK:-0}" != "1" ] && [ ! -e "${ACCMAP_DIR}/${FUTU_ACCOUNT}" ]; then
        cat >&2 <<EOF
[entrypoint] FATAL: no remembered credential for account ${FUTU_ACCOUNT} in the data volume.
[entrypoint] Starting anyway would exit immediately and, under a restart policy, retry
[entrypoint] forever. Refusing to start.
[entrypoint] Fix: run the first login once, with FUTU_ACCOUNT unset and the telnet port
[entrypoint] published, then set FUTU_ACCOUNT and start normally.
[entrypoint] To override this check: FUTU_SKIP_CRED_CHECK=1
EOF
        exit 78
    fi
fi

args=("-cfg_file=${CONFIG}")
if [ -n "${FUTU_ACCOUNT:-}" ]; then
    echo "[entrypoint] Starting FutuOpenD with remember-login for account: ${FUTU_ACCOUNT}"
    args+=("-login_account=${FUTU_ACCOUNT}" "-login_by_remember=1")
    args+=("-area_code=${FUTU_AREA_CODE:-+852}")
else
    echo "[entrypoint] FUTU_ACCOUNT not set. Starting FutuOpenD for interactive first login."
    echo "[entrypoint] Log in once and choose remember; the credential is cached in the data volume."
    cat <<EOF
[entrypoint] Note: the login prompts arrive on two different channels.
[entrypoint]   - "Please enter account" is printed here and read from stdin, so a TTY is required.
[entrypoint]   - "Please enter password" (and any SMS/CAPTCHA prompt) is delivered to
[entrypoint]     clients on the telnet port. Publish it to reach it, e.g.
[entrypoint]       docker compose run --rm -it -p 127.0.0.1:22222:22222 -e FUTU_ACCOUNT= futuopend
[entrypoint]     then, in a second terminal:  telnet 127.0.0.1 22222
[entrypoint]   Telnet commands need a carriage return and newline (\\r\\n).
[entrypoint]   Without a reachable telnet port the login appears to hang after the account.
EOF
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