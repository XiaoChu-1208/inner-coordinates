#!/usr/bin/env bash
# wechat-watch.sh [间隔s] [最大轮数] — 【守在当前会话页】的快速监视器 + 内置解读(对话热时用)。
#
# 升级版(2026-06-24 小刍想法):监视器自己把"解读"做掉,主 agent 只在【真有新消息】时被唤醒、且拿到现成解读文字。
#   每隔 INT 秒截【会话消息区】比 md5:
#     画面没变 → 继续盯(不解读、不烧 claude 调用)。
#     画面变了 → 截全会话图,调【headless claude -p (sonnet, 只白名单 Read,不禁权限门)】解读:
#       解读出对方新消息 → echo "NEW_MSG: <原文>" 并 exit 0 → harness 当场唤醒主 agent,主 agent 直接 here 回(不读图)。
#       解读=NONE(撤回/正在输入/自己消息渲染等空触发) → 自己消化,更新基线继续盯,【不唤醒主 agent】。
#     连续 MAX 轮没变 → echo IDLE 并 exit 0 → 主 agent 退首页转 60s 冷轮询。
#
#   用法(后台): run_in_background 跑  bash lib/wechat-watch.sh 15 20
#
# 前提:已停在【目标联系人会话页】;镜像已连;claude CLI 在 PATH。
# 安全:headless 解读用 --allowedTools Read(只读白名单)+不带 --dangerously-skip-permissions —— 不创建无门禁自主 agent。
# 基线:启动第一帧作基线,所以【发完自己回复后再启动】,基线含自己消息。
set -uo pipefail
PROC="iPhone Mirroring"
INT="${1:-15}"; MAX="${2:-20}"
SHOT=/tmp/wechat_watch_msgarea.png    # 消息区(测变化用)
FULL=/tmp/wechat_watch_full.png       # 全会话图(解读用)

geo=$(osascript -e "tell application \"System Events\" to tell process \"$PROC\" to get {position, size} of front window" 2>/dev/null)
read -r x y w h < <(echo "$geo" | tr -d ',')
[ -z "${h:-}" ] && { echo "NOWIN: 拿不到镜像窗口几何"; exit 1; }
MY=$(( y + 300 )); MH=$(( h - 370 ))   # 下半屏气泡区,避开顶部"正在输入"提示

snap_md5(){ cliclick m:6,6 >/dev/null 2>&1; screencapture -x -R "${x},${MY},${w},${MH}" "$SHOT" 2>/dev/null; md5 -q "$SHOT" 2>/dev/null; }
interpret(){   # 截全图放大→headless sonnet 解读→打印对方新消息原文 或 NONE
  screencapture -x -R "${x},${y},${w},${h}" "$FULL" 2>/dev/null
  sips -z 760 692 "$FULL" --out "$FULL" >/dev/null 2>&1
  claude -p "Read the image $FULL . 这是 iPhone 微信聊天截图,左侧灰色气泡=对方发的,右侧绿色气泡=我方发的,灰色居中小字(如撤回提示)不算消息。只输出【我方最后一条绿色气泡之后】对方发的新消息原文,每条一行;若对方没有更新的消息,只输出一个词 NONE。不要任何解释或客套。" \
    --allowedTools Read --model sonnet --output-format text 2>/dev/null
}

prev="$(snap_md5)"
for i in $(seq 1 "$MAX"); do
  sleep "$INT"
  osascript -e "tell application \"System Events\" to tell process \"$PROC\" to set frontmost to true" >/dev/null 2>&1
  cur="$(snap_md5)"
  [ "$cur" = "$prev" ] && continue           # 没变,不解读
  reading="$(interpret)"
  if [ -n "$reading" ] && ! printf '%s' "$reading" | grep -qix 'none'; then
    echo "NEW_MSG: $reading"
    exit 0                                    # 真有新消息,唤醒主 agent 并透传解读
  fi
  prev="$cur"                                 # NONE 空触发,自己消化,更新基线继续盯
done
echo "IDLE: 连续 ${MAX} 轮(每 ${INT}s)无对方新消息——退首页转 60s 冷轮询"
