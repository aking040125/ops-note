# conf 目录说明

实际在跑的东西，密码全改成了 `CHANGE_ME`，其他都保持原样。

| 文件 | 放在哪 | 说明 |
|---|---|---|
| `docker-compose.yml` | web1 和 web2 的 `/opt/lnmp/` | 三个容器的编排 |
| `.env.example` | 同上，复制成 `.env` 再改 | 所有可调参数 |
| `nginx-default.conf` | `nginx/conf.d/default.conf` | 站点配置，含 `/healthz` |
| `keepalived-web1.conf` | web1 的 `/etc/keepalived/keepalived.conf` | 主，priority 150 |
| `keepalived-web2.conf` | web2 的 `/etc/keepalived/keepalived.conf` | 备，priority 140 |
| `check_nginx.sh` | 两台都是 `/etc/keepalived/check_nginx.sh` | 探活 |
| `notify.sh` | 两台都是 `/etc/keepalived/notify.sh` | 状态变化记日志 |

## 用之前必须改的

打开 `.env`，这几个 `CHANGE_ME` 一个都不能留：

- `DB_PASS` / `DB_ROOT_PASS` —— 数据库密码
- `VRRP_PASS` —— Keepalived 两台之间的认证密码，最长 8 位

还有这两个看你自己的环境：

- `NIC=ens33` —— 用 `ip a` 看你的网卡叫什么。CentOS 7 一般是 `ens33`，
  Ubuntu 可能是 `enp0s3`，写错了 Keepalived 起不来
- `VIP=192.168.86.100` —— 挑一个同网段里没人用的 IP。先 `ping` 一下确认没人占

## 两台机器的区别只有三处

| | web1 | web2 |
|---|---|---|
| `keepalived.conf` 的 `state` | MASTER | BACKUP |
| `priority` | 150 | 140 |
| `unicast_src_ip` | 192.168.86.7 | 192.168.86.8 |

`docker-compose.yml` 和 `.env` 两台完全一样——这正是换 Docker 的收益，配置只维护一份。

## 如果 VIP 被占用了

改三个地方，要一致：

1. `.env` 里的 `VIP=`
2. `keepalived-web1.conf` 里的 `virtual_ipaddress` 段
3. `keepalived-web2.conf` 里的 `virtual_ipaddress` 段

然后 `systemctl restart keepalived` 两台都重启。
