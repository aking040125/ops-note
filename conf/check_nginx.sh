#!/bin/bash
# ==========================================================
# Keepalived 探活脚本
# 位置：两台 web 机器的 /etc/keepalived/check_nginx.sh
# 权限：chmod +x
#
# 退出码约定（Keepalived 靠这个判断）：
#   0 = 健康，本机可以持有 VIP
#   1 = 不健康
# ==========================================================

set -uo pipefail

# 探宿主机 80 端口的 /healthz（容器映射出来的）
# --max-time 1 给 1 秒，短了容易因为偶发慢就报错
if curl -fsS --max-time 1 http://127.0.0.1/healthz > /dev/null 2>&1; then
    exit 0
fi

# 第一层没通过，再看看容器到底是什么状态
if ! command -v docker > /dev/null 2>&1; then
    exit 1
fi

HEALTH="$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' lnmp-nginx 2>/dev/null || echo "missing")"

# 只有 healthy 才算通
# 注意：starting 不能算健康。启动中的节点不该接管 VIP
# 这一点踩过坑，见 03-踩坑笔记 第 8 条
if [ "$HEALTH" = "healthy" ]; then
    exit 0
fi

# 走到这里说明确实有问题，打一行日志方便查（只在失败时打，不刷屏）
echo "$(date '+%F %T') check_nginx: FAIL (curl 不通，容器状态=${HEALTH})" >> /var/log/keepalived-check.log 2>/dev/null || true

exit 1
