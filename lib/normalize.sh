#!/usr/bin/env bash
# normalize.sh — 把目标 App 主窗口摆到固定矩形，打印指纹(几何 + 版本)。
# 复用缓存坐标前先跑这个：几何对齐 + 核对版本有没有变(变了→该重学)。
#
#   用法: normalize.sh <进程名> [宽 高]      例: normalize.sh NeteaseMusic 1440 900
#
# 输出形如:  pos=0,30  size=1440,900  version=3.0.11  bundle=com.netease.163music
# 调用方据此：① 用 pos 把缓存的相对偏移换成绝对坐标 ② 比对 version/size 决定要不要重学。

set -uo pipefail
APP="${1:?usage: normalize.sh <ProcessName> [W H]}"
W="${2:-1440}"; H="${3:-900}"

osascript -e "tell application \"$APP\" to activate" 2>/dev/null
# 等窗口出现(冷启动)
for i in $(seq 1 40); do
  n=$(osascript -e "tell application \"System Events\" to count windows of process \"$APP\"" 2>/dev/null || echo 0)
  [ "${n:-0}" -ge 1 ] && break; sleep 0.2
done
# 摆到固定矩形(分两句；别用 set {position,size} 合写)
osascript -e "tell application \"System Events\" to tell process \"$APP\"
  set frontmost to true
  set position of front window to {0, 25}
  set size of front window to {$W, $H}
end tell" 2>/dev/null
sleep 0.3
# 回读实际几何(有些 App 有最小尺寸,以实际为准)
geo=$(osascript -e "tell application \"System Events\" to tell process \"$APP\" to get {position, size} of front window" 2>/dev/null)
pos=$(echo "$geo" | awk -F', ' '{print $1","$2}')
size=$(echo "$geo" | awk -F', ' '{print $3","$4}')
# 版本 + bundle(认布局漂移)
appPath=$(osascript -e "tell application \"$APP\" to POSIX path of (path to it)" 2>/dev/null)
ver=$(defaults read "$appPath/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null || echo "?")
bid=$(defaults read "$appPath/Contents/Info.plist" CFBundleIdentifier 2>/dev/null || echo "?")

echo "pos=$pos  size=$size  version=$ver  bundle=$bid"
