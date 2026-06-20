#!/usr/bin/env bash
# grab.sh <进程名> [输出路径] — 只截目标 App 主窗口那一块(不全屏),省时省裁剪。
# 前提:窗口已 normalize 到固定矩形(贴左上角)。读它的实际几何当截图区域。
#
#   用法: grab.sh NeteaseMusic /tmp/ncm.png
#
# 输出图是 2x 物理像素:  截图像素(px,py) ÷ 缩放(2) = 窗口相对坐标(逻辑)。
#   绝对逻辑坐标 = 窗口position + 窗口相对坐标。
#
# 注意:防截屏的 App(微信)用这个照样是空白——那种只能靠用户截图配合。

set -uo pipefail
APP="${1:?usage: grab.sh <ProcessName> [out.png]}"
OUT="${2:-/tmp/${APP}_window.png}"

geo=$(osascript -e "tell application \"System Events\" to tell process \"$APP\" to get {position, size} of front window" 2>/dev/null)
read -r x y w h < <(echo "$geo" | tr -d ',')
[ -z "${h:-}" ] && { echo "拿不到 $APP 窗口几何(没窗口?)" >&2; exit 1; }

screencapture -x -R "${x},${y},${w},${h}" "$OUT"
echo "$OUT  rect=${x},${y},${w},${h}  (像素÷2=窗口相对坐标; 绝对=该偏移+${x},${y})"
