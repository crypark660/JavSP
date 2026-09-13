#!/bin/sh

WATCH_DIR="/download"
CHECK_INTERVAL=10
STABLE_CHECKS=3

child_pid=""

cleanup() {
    echo
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 收到停止信号，正在退出..."

    if [ -n "$child_pid" ] && kill -0 "$child_pid" 2>/dev/null; then
        echo "正在停止 JavSP..."
        kill "$child_pid" 2>/dev/null
        wait "$child_pid" 2>/dev/null
    fi

    exit 0
}

trap cleanup INT TERM

echo "=========================================="
echo "JavSP 自动刮削守护程序"
echo "监控目录: $WATCH_DIR"
echo "检查间隔: ${CHECK_INTERVAL}s"
echo "=========================================="

while true; do

    # 没有文件就继续等待
    if ! find "$WATCH_DIR" -type f -print -quit 2>/dev/null | grep -q .; then
        sleep "$CHECK_INTERVAL"
        continue
    fi

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 检测到文件，等待传输完成..."

    stable=0
    last_size=""

    while [ "$stable" -lt "$STABLE_CHECKS" ]; do
        current_size=$(
            find "$WATCH_DIR" -type f -exec stat -c '%s' {} \; 2>/dev/null |
            awk '{sum += $1} END {print sum+0}'
        )

        if [ "$current_size" = "$last_size" ] && [ -n "$last_size" ]; then
            stable=$((stable + 1))
        else
            stable=0
        fi

        last_size="$current_size"

        echo "[$(date '+%Y-%m-%d %H:%M:%S')] 文件总大小: ${current_size} bytes，稳定检查 ${stable}/${STABLE_CHECKS}"

        sleep 10
    done

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 文件已稳定，开始 JavSP 刮削..."

    javsp &
    child_pid=$!

    wait "$child_pid"
    exit_code=$?
    child_pid=""

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] JavSP 已结束，ExitCode=$exit_code"

    if [ "$exit_code" -eq 0 ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] 本次刮削完成，继续等待新影片。"
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] 本次刮削出现异常，30 秒后继续检查。"
        sleep 30
    fi

done
