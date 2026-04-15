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
    PID=$(pgrep -x FutuOpenD)
    if [ -n "$PID" ]; then
        kill -TERM "$PID" 2>/dev/null
        for i in $(seq 1 $SHUTDOWN_TIMEOUT); do
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

echo "Starting FutuOpenD..."
/usr/local/bin/FutuOpenD &
PID=$!

echo "FutuOpenD started with PID $PID"
wait $PID