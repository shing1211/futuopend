#!/bin/bash
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