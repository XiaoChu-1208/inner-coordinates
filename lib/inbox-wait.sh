#!/usr/bin/env bash
# inbox-wait.sh — 轻量哨兵:盯 /tmp/wechat_inbox.txt,一有新行就打印新行并退出(唤醒主 agent)。
# 配合 wechat-watch-daemon.sh:daemon 常驻写收件箱,本哨兵负责"有货就叫醒主 agent"。
# 主 agent 被唤醒→读这里打印的新对方消息→回复→touch marker→重新跑一个本哨兵(daemon 不动)。
#   用法(后台): run_in_background 跑  bash lib/inbox-wait.sh
set -uo pipefail
INBOX=/tmp/wechat_inbox.txt
touch "$INBOX"
n0=$(wc -l < "$INBOX" 2>/dev/null | tr -d ' '); n0=${n0:-0}
for i in $(seq 1 600); do          # 最多盯 ~20 分钟(600×2s)
  sleep 2
  n=$(wc -l < "$INBOX" 2>/dev/null | tr -d ' '); n=${n:-0}
  if [ "$n" -gt "$n0" ]; then
    echo "NEW_FROM_THEM:"
    tail -n +$((n0+1)) "$INBOX"
    exit 0
  fi
done
echo "SENTINEL_IDLE: 20 分钟无新消息"
