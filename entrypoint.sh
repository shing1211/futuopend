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

args=()
if [ -n "${FUTU_ACCOUNT:-}" ]; then
    echo "[entrypoint] Starting FutuOpenD with remember-login for account: ${FUTU_ACCOUNT}"
    args+=("-login_account=${FUTU_ACCOUNT}" "-login_by_remember=1")
    if [ -n "${FUTU_AREA_CODE:-}" ]; then
        args+=("-area_code=${FUTU_AREA_CODE}")
    fi
else
    echo "[entrypoint] FUTU_ACCOUNT not set. Starting FutuOpenD for interactive first login."
    echo "[entrypoint] Log in once and choose remember; the credential is cached in the data volume."
fi

/usr/local/bin/FutuOpenD "${args[@]}" "$@" &
PID=$!

echo "FutuOpenD started with PID $PID"
wait $PID