#!/usr/bin/env bash
# grab-badges.sh <进程名> [输出路径] — 专门核【微信列表未读红角标】用。
#
# 为什么单独一个脚本:微信未读角标 = 联系人【头像右上角的小红点】(不是行右侧!那里是时间戳)。
# 这红点只有几个像素,grab.sh 截全窗口后整图传给模型会被降采样压糊、红点直接糊没 → 误判"没新消息"。
# (2026-06-24 实测连漏好几次,小刍发高清图才发现。)
# 解法:只截【左侧头像那一窄列】+ 放大,小区域保留原始像素密度,红点一眼可辨。
#
#   用法: grab-badges.sh "iPhone Mirroring" /tmp/badges.png   → Read 它,看哪行头像右上角有红点
#
# 注意:有新消息的会话会被顶到列表顶部,所以红点基本出现在最上面几行。
set -uo pipefail
APP="${1:?usage: grab-badges.sh <ProcessName> [out.png]}"
OUT="${2:-/tmp/wechat_badges.png}"

geo=$(osascript -e "tell application \"System Events\" to tell process \"$APP\" to get {position, size} of front window" 2>/dev/null)
read -r x y w h < <(echo "$geo" | tr -d ',')
[ -z "${h:-}" ] && { echo "拿不到 $APP 窗口几何(没窗口?)" >&2; exit 1; }

# 头像列:窗口左侧约 80 逻辑宽;列表区从顶部下方 ~95 起到接近底部(留出底栏)
COLW=80
CY=$(( y + 95 ))
CH=$(( h - 140 ))
screencapture -x -R "${x},${CY},${COLW},${CH}" "$OUT"
# 放大 2x:小区域细节保留,红点更醒目(Read 不会再把它压糊)
sips -z "$(( CH * 2 ))" "$(( COLW * 2 ))" "$OUT" --out "$OUT" >/dev/null 2>&1
echo "$OUT  (左侧头像列 x=${x},y=${CY},w=${COLW},h=${CH},已放大2x; Read 它看哪行头像右上角有红点=未读)"
