#!/usr/bin/env bash
# wechat-watch-daemon.sh [间隔s] [最大轮数] — 【常驻】sonnet 解读守护进程(热对话时一直开着,别关)。
#
# 和旧版 wechat-watch.sh 的区别:它【不因为有新消息就退出】,而是把对方新消息持续写进收件箱
#   /tmp/wechat_inbox.txt,自己一直盯下去。主 agent 靠另一个轻量哨兵(inbox-wait.sh)盯收件箱被唤醒。
#   → sonnet 盯截图、主 agent 盯 sonnet,两边并行;主 agent 处理/回复时 daemon 不停,空档不漏消息。
#
#   用法(后台常驻): run_in_background 跑  bash lib/wechat-watch-daemon.sh 15 240
#
# 协作协议:
#   - 对方每条新消息 append 一行到 /tmp/wechat_inbox.txt
#   - 主 agent 每次回复完 `touch /tmp/wechat_reply_marker` → daemon 据此把"基准"前移(我方最后一条更新了),
#     避免把对方旧消息当新消息重复入收件箱。
# 安全:解读用 claude -p --allowedTools Read(只读白名单),绝不加 --dangerously-skip-permissions。
set -uo pipefail
PROC="iPhone Mirroring"
INT="${1:-15}"; MAX="${2:-240}"; COLD_ROUNDS="${3:-12}"   # 连续 COLD_ROUNDS 轮无对方新消息→报 COLD 退出(默认12轮≈3分钟),主 agent 据此退主界面扫全局
INBOX=/tmp/wechat_inbox.txt
MARKER=/tmp/wechat_reply_marker
SHOT=/tmp/wechat_daemon_msgarea.png
FULL=/tmp/wechat_daemon_full.png

geo=$(osascript -e "tell application \"System Events\" to tell process \"$PROC\" to get {position, size} of front window" 2>/dev/null)
read -r x y w h < <(echo "$geo" | tr -d ',')
[ -z "${h:-}" ] && { echo "NOWIN"; exit 1; }
MY=$(( y + 300 )); MH=$(( h - 370 ))

snap_md5(){ cliclick m:6,6 >/dev/null 2>&1; screencapture -x -R "${x},${MY},${w},${MH}" "$SHOT" 2>/dev/null; md5 -q "$SHOT" 2>/dev/null; }
interpret(){
  screencapture -x -R "${x},${y},${w},${h}" "$FULL" 2>/dev/null
  sips -z 760 692 "$FULL" --out "$FULL" >/dev/null 2>&1
  claude -p "Read the image $FULL . iPhone 微信聊天截图。【左侧灰色气泡=对方(联系人)发的;右侧绿色气泡=我方发的】。务必按气泡颜色和左右位置区分:绿色一律是我方,【绝对不要】把任何绿色气泡当成对方消息。先定位对话【最底部】:以【整个对话最下方那一条绿色气泡】为界(不是历史里中间某条绿气泡),只输出【它下方】对方(左侧灰色)新发的消息,每条一行,保留原文;若是群聊(多人),每条前标发言人昵称(气泡上方的名字),格式『昵称: 消息』;灰色居中小字(撤回提示等)不算。若我方最后一条绿色气泡之后对方没有任何新灰色气泡,只输出一个词:NONE。不要解释。" \
    --allowedTools Read --model sonnet --output-format text 2>/dev/null
}

: > "$INBOX"
touch "$MARKER"
last_marker=$(stat -f %m "$MARKER" 2>/dev/null)
prev_reading=""
prev_md5="$(snap_md5)"

cold=0
for i in $(seq 1 "$MAX"); do
  sleep "$INT"
  osascript -e "tell application \"System Events\" to tell process \"$PROC\" to set frontmost to true" >/dev/null 2>&1
  # 主 agent 刚回复? → 基准前移,清空 prev_reading,重设 md5 基线(含我方新气泡),冷计数归0
  m=$(stat -f %m "$MARKER" 2>/dev/null)
  if [ "$m" != "$last_marker" ]; then
    last_marker="$m"; prev_reading=""; prev_md5="$(snap_md5)"; cold=0; continue
  fi
  cur="$(snap_md5)"
  if [ "$cur" = "$prev_md5" ]; then
    cold=$((cold+1)); [ "$cold" -ge "$COLD_ROUNDS" ] && { echo "COLD: 连续 ${cold} 轮无对方新消息,该退主界面扫全局"; exit 0; }
    continue
  fi
  prev_md5="$cur"
  reading="$(interpret)"
  if printf '%s' "$reading" | grep -qix 'none' || [ -z "$reading" ]; then
    prev_reading=""
    cold=$((cold+1)); [ "$cold" -ge "$COLD_ROUNDS" ] && { echo "COLD: 连续 ${cold} 轮无对方新消息,该退主界面扫全局"; exit 0; }
    continue
  fi
  # 有对方新消息:增量(只 append 比上次多出来的尾行),冷计数归0
  pl=$(printf '%s\n' "$prev_reading" | sed '/^[[:space:]]*$/d' | wc -l | tr -d ' ')
  newpart=$(printf '%s\n' "$reading" | sed '/^[[:space:]]*$/d' | tail -n +$((pl+1)))
  [ -n "$newpart" ] && printf '%s\n' "$newpart" >> "$INBOX"
  prev_reading="$reading"; cold=0
done
echo "COLD: 跑满 ${MAX} 轮,退主界面扫全局"
