#!/usr/bin/env bash
# rescale.sh <进程名> <学习时的x> <学习时的y> [refX refY refW refH] [--click] [--double]
#
# 把【在参考窗口几何下学到的坐标】换算到【当前实际窗口几何】下的点击坐标。
# 实现"换屏幕/换窗口大小/换用户都不用重学、纯计算"(Inner Coordinates 核心)。
#
# 原理:坐标只跟窗口几何绑定,不跟 Mac 分辨率绑定。
#   fx=(x-refX)/refW, fy=(y-refY)/refH        # 学习坐标 → 窗口内分数(0~1)
#   click=(curX+fx*curW, curY+fy*curH)        # 分数 → 当前窗口绝对坐标
# 因为镜像/多数 App 窗口保持宽高比,fx/fy 在任何尺寸下都成立。
#
# 默认参考几何 = iPhone 镜像归一化后 (0,30,346,760) @iPhone 14 Plus。其它 profile 见各自 fingerprint。
#   用法: rescale.sh "iPhone Mirroring" 145 356            # 打印当前该点的绝对坐标
#         rescale.sh "iPhone Mirroring" 145 356 --click    # 顺便点它
set -uo pipefail
APP="${1:?usage: rescale.sh <Proc> <lx> <ly> [refX refY refW refH] [--click] [--double]}"
LX="${2:?need lx}"; LY="${3:?need ly}"
REFX=0; REFY=30; REFW=346; REFH=760
DOCLICK=0; DOUBLE=""
shift 3
# 可选 4 个数字 = 参考几何
if [[ "${1:-}" =~ ^-?[0-9]+$ && "${2:-}" =~ ^-?[0-9]+$ && "${3:-}" =~ ^-?[0-9]+$ && "${4:-}" =~ ^-?[0-9]+$ ]]; then
  REFX="$1"; REFY="$2"; REFW="$3"; REFH="$4"; shift 4
fi
for a in "$@"; do [ "$a" = "--click" ] && DOCLICK=1; [ "$a" = "--double" ] && DOUBLE="--double"; done

geo=$(osascript -e "tell application \"System Events\" to tell process \"$APP\" to get {position, size} of front window" 2>/dev/null)
read -r CX CY CW CH < <(echo "$geo" | tr -d ',')
[ -z "${CH:-}" ] && { echo "拿不到 $APP 窗口几何" >&2; exit 1; }

read -r NX NY < <(python3 -c "
fx=($LX-$REFX)/$REFW; fy=($LY-$REFY)/$REFH
print(round($CX+fx*$CW), round($CY+fy*$CH))
")
echo "$NX $NY   (学习@${REFX},${REFY},${REFW}x${REFH} → 当前@${CX},${CY},${CW}x${CH})"
if [ "$DOCLICK" = 1 ]; then
  osascript -e "tell application \"System Events\" to tell process \"$APP\" to set frontmost to true" >/dev/null 2>&1; sleep 0.3
  peekaboo click --coords "$NX,$NY" $DOUBLE
fi
