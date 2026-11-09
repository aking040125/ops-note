#!/bin/bash
# ==========================================================
# Keepalived 状态切换时记一笔日志
# 位置：两台 web 的 /etc/keepalived/notify.sh
#
# 用法（由 keepalived.conf 里的 notify_* 调用）：
#   notify.sh master|backup|fault
#
# 重要：这个脚本永远 exit 0。
# 如果它返回非 0，Keepalived 会以为出错了，可能误判状态。
# 日志写不进去也不能让 Keepalived 挂掉，见 03-踩坑笔记 里的说明。
# ==========================================================

set -uo pipefail

STATE="${1:-unknown}"
HOST="$(hostname)"
NOW="$(date '+%F %T')"

# 当前 VIP 在本机吗
if ip addr show 2>/dev/null | grep -q "192.168.86.100"; then
    VIP="本机持有"
else
    VIP="不在本机"
fi

LINE="$NOW [$HOST] 状态切换为 $STATE，VIP $VIP"

# 写日志（写不进去也不影响退出码）
echo "$LINE" >> /var/log/keepalived-notify.log 2>/dev/null || true

# 同时打到 stdout，systemd 的 journalctl 里也能看到
echo "$LINE"

exit 0
