#!/usr/bin/env bash
# meituan-search.sh <商品或店名> [输出图]
# 从【美团外卖首页】一口气完成:normalize窗口 → 点顶部搜索栏 → 粘query → 点搜索 → 截结果页。
# 目的:把"走一步截一步"的稳定链路压成【一条命令】,中间没有可截的图 → agent 自然盲跑,
#       只在脚本跑完后对着结果页截一张选店。前提:已在美团外卖首页(锚点)、iPhone镜像已连、Handoff开、cliclick装。
#
#   用法: meituan-search.sh 皮爷咖啡 /tmp/r.png
#
set -uo pipefail
Q="${1:?usage: meituan-search.sh <query> [out.png]}"
OUT="${2:-/tmp/meituan_results.png}"
DIR="$(cd "$(dirname "$0")" && pwd)"
PROC="iPhone Mirroring"

act(){ osascript -e "tell application \"System Events\" to tell process \"$PROC\" to set frontmost to true" >/dev/null 2>&1; }
front(){ osascript -e 'tell application "System Events" to get name of first application process whose frontmost is true' 2>/dev/null; }

# 0) 归一化窗口(坐标可复现)
osascript -e "tell application \"System Events\" to tell process \"$PROC\" to set position of front window to {0,25}" >/dev/null 2>&1
sleep 0.5

# 1) 顶部搜索栏 → 搜索页
act; sleep 0.3
peekaboo click --coords "140,141" >/dev/null; sleep 1.8

# 2) 聚焦输入框
act; sleep 0.2
peekaboo click --coords "130,120" >/dev/null; sleep 0.6

# 3) 剪贴板 + 接力同步 + 真实 Cmd+V(中文必须 cliclick,peekaboo/osascript 的 Cmd 会被镜像吃掉)
printf "%s" "$Q" | pbcopy
sleep 2.8
f="$(front)"
if [ "$f" != "$PROC" ]; then echo "FOCUS_LOST: 最前台是 $f,不是镜像,中止" >&2; exit 2; fi
cliclick kd:cmd t:v ku:cmd
sleep 1.0

# 4) 搜索黄按钮 → 结果页
act; sleep 0.2
peekaboo click --coords "307,117" >/dev/null; sleep 2.2

# 5) 截结果页(鼠标先移开避免遮挡)
peekaboo move --coords "330,90" >/dev/null 2>&1; sleep 0.3
"$DIR/grab.sh" "$PROC" "$OUT"
echo "DONE: 已搜『$Q』并停在结果页 -> $OUT"
echo "下一步(唯一需看一眼): 认出筛选行(综合排序…)下第一张店卡,点它进店。促销banner会推移其Y,务必截图定位别盲点。"
