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

SIGNAL_HANDLED=0

cleanup() {
    if [ "$SIGNAL_HANDLED" -eq 1 ]; then
        return
    fi
    SIGNAL_HANDLED=1
    echo "Received shutdown signal, stopping FutuOpenD gracefully..."
    if [ -n "$FUTU_PID" ] && kill -0 "$FUTU_PID" 2>/dev/null; then
        kill -TERM "$FUTU_PID" 2>/dev/null || true
        for i in {1..30}; do
            if ! kill -0 "$FUTU_PID" 2>/dev/null; then
                echo "FutuOpenD stopped gracefully"
                exit 0
            fi
            sleep 0.5
        done
        echo "FutuOpenD did not stop gracefully, forcing..."
        kill -KILL "$FUTU_PID" 2>/dev/null || true
    fi
    exit 0
}

trap cleanup SIGTERM SIGINT SIGHUP

echo "Starting FutuOpenD..."
/usr/local/bin/FutuOpenD &
FUTU_PID=$!

echo "FutuOpenD started with PID $FUTU_PID"

wait "$FUTU_PID"
EXIT_CODE=$?

echo "FutuOpenD exited with code $EXIT_CODE"
exit $EXIT_CODE
