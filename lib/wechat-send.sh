#!/usr/bin/env bash
# wechat-send.sh <联系人全名> <消息文本> [from]
# 经 iPhone 镜像给微信某联系人发一条消息,【代码级一次性通过】(零截图、不走大模型逐步)。
#
# ★第三参 from = 当前所处 state(内心坐标),决定走哪条最短边,别无脑复位:
#   from=here  → 【我已经在该联系人的会话页里】(刚搜进来/刚读完消息)。跳过搜索导航,直接点输入框发,
#                发完【留在会话页】(继续盯这个会话)。—— 就地接链路,最短路径。
#   from=list  → (默认) 我在微信列表页锚点。搜全名 → 点第一个联系人结果 → 进会话 → 发 → 退回列表。
#
#   就地回(已在会话页): wechat-send.sh 张三 "好的我转告他" here
#   从列表发:           wechat-send.sh 张三 "在吗"            (或显式 ... list)
#
# 前提: iPhone 镜像已连、接力/Handoff 开、cliclick 装。from=here 要求确实已在该会话页(自己心里有数)。
# 脱敏: 联系人名/消息从参数传入,不写死(白名单不入库)。
# 注意: 消息保持短(≤2行);长文进多行模式连刷 return 只换行 → 拆成多次调用。
set -uo pipefail
NAME="${1:?usage: wechat-send.sh <联系人全名> <消息文本> [from=list|here]}"
MSG="${2:?usage: wechat-send.sh <联系人全名> <消息文本> [from=list|here]}"
FROM="${3:-list}"
DIR="$(cd "$(dirname "$0")" && pwd)"
PROC="iPhone Mirroring"

act(){ osascript -e "tell application \"System Events\" to tell process \"$PROC\" to set frontmost to true" >/dev/null 2>&1; }
front(){ osascript -e 'tell application "System Events" to get name of first application process whose frontmost is true' 2>/dev/null; }
guard(){ f="$(front)"; if [ "$f" != "$PROC" ]; then echo "FOCUS_LOST: 最前台是 $f,不是镜像,中止(防输入漏进终端)" >&2; exit 2; fi; }
paste_cn(){ printf "%s" "$1" | pbcopy; sleep 2.8; guard; cliclick kd:cmd t:v ku:cmd; }   # 中文必须 cliclick 真 Cmd+V

# 0) 归一化窗口(只钉左上角,镜像尺寸固定) —— 两种模式都做,坐标可复现
osascript -e "tell application \"System Events\" to tell process \"$PROC\" to set position of front window to {0,25}" >/dev/null 2>&1
sleep 0.5

# === 导航段:仅 from=list 时跑(from=here 已在会话页,跳过) ===
if [ "$FROM" != "here" ]; then
  # 1) 列表页 → 点搜索框 → 搜索页
  act; sleep 0.3
  peekaboo click --coords "173,158" >/dev/null; sleep 1.5
  # 2) 聚焦搜索输入框 + 清空(防残留旧词)
  act; sleep 0.2
  guard; cliclick kd:cmd t:a ku:cmd >/dev/null 2>&1; sleep 0.2; cliclick kp:delete >/dev/null 2>&1; sleep 0.2
  # 3) 粘联系人全名(固定锚点:微信极少重名,第一个联系人结果必命中)
  act; paste_cn "$NAME"; sleep 1.2
  # 4) 点第一个联系人结果 → 会话页
  act; sleep 0.2
  peekaboo click --coords "110,211" >/dev/null; sleep 2.0
fi

# === 发送段:两种模式都跑(此刻必在会话页) ===
# 5) 点输入框聚焦 + 清空
act; sleep 0.2
peekaboo click --coords "150,732" >/dev/null; sleep 0.6
act; sleep 0.2
guard; cliclick kd:cmd t:a ku:cmd >/dev/null 2>&1; sleep 0.2; cliclick kp:delete >/dev/null 2>&1; sleep 0.2
# 6) 粘消息
act; paste_cn "$MSG"; sleep 0.9
# 7) 发送:连刷 5 次 Return(合成 Return 经镜像偶尔才登记一次,连刷才稳;绝不用 Cmd+Return)
act; guard
cliclick kp:return w:100 kp:return w:100 kp:return w:100 kp:return w:100 kp:return
sleep 1.0

# === 收尾:from=list 退回列表锚点;from=here 留在会话页继续盯 ===
if [ "$FROM" != "here" ]; then
  act; sleep 0.2
  peekaboo click --coords "25,129" >/dev/null; sleep 1.0     # 会话页 → 搜索页
  act; sleep 0.2
  peekaboo click --coords "26,120" >/dev/null; sleep 1.0     # 搜索页 → 列表页
  echo "DONE: 已给 ${NAME} 发出消息(from=list),并退回微信列表页锚点。"
else
  echo "DONE: 已给 ${NAME} 就地发出消息(from=here),留在会话页。"
fi
