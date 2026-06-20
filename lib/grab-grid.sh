#!/usr/bin/env bash
# grab-grid.sh <进程名> [out.png] [step]
# 截窗口 + 叠加【绝对逻辑坐标网格】(每 step 逻辑像素一条线并标注坐标)。
# 直接读格子交点 = 点击坐标,不用裁图目测(目测缩略图易偏 30-60px,见复盘)。
#   用法: grab-grid.sh "iPhone Mirroring" /tmp/g.png 50
set -uo pipefail
APP="${1:?usage: grab-grid.sh <ProcessName> [out.png] [step]}"
OUT="${2:-/tmp/${APP}_grid.png}"
STEP="${3:-50}"
RAW="/tmp/_gridraw_$$.png"
geo=$(osascript -e "tell application \"System Events\" to tell process \"$APP\" to get {position, size} of front window" 2>/dev/null)
read -r x y w h < <(echo "$geo" | tr -d ',')
[ -z "${h:-}" ] && { echo "拿不到 $APP 窗口几何(没窗口?)" >&2; exit 1; }
screencapture -x -R "${x},${y},${w},${h}" "$RAW"
python3 - "$RAW" "$OUT" "$x" "$y" "$w" "$h" "$STEP" <<'PY'
import sys
from PIL import Image, ImageDraw, ImageFont
raw, out = sys.argv[1], sys.argv[2]
x, y, w, h, step = map(int, sys.argv[3:8])
im = Image.open(raw).convert("RGB"); PW, PH = im.size
sx, sy = PW / w, PH / h
d = ImageDraw.Draw(im)
try: font = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial.ttf", 13)
except Exception: font = ImageFont.load_default()
lx = (x // step) * step
while lx <= x + w:
    px = (lx - x) * sx
    if 0 <= px <= PW:
        d.line([(px, 0), (px, PH)], fill=(255, 40, 40), width=1)
        d.text((px + 2, 2), str(lx), fill=(255, 40, 40), font=font)
        d.text((px + 2, PH - 16), str(lx), fill=(255, 40, 40), font=font)
    lx += step
ly = (y // step) * step
while ly <= y + h:
    py = (ly - y) * sy
    if 0 <= py <= PH:
        d.line([(0, py), (PW, py)], fill=(0, 130, 255), width=1)
        d.text((2, py + 1), str(ly), fill=(0, 130, 255), font=font)
        d.text((PW - 34, py + 1), str(ly), fill=(0, 130, 255), font=font)
    ly += step
im.save(out)
print(f"{out}  rect={x},{y},{w},{h}  step={step}逻辑px  红竖线=绝对x / 蓝横线=绝对y,读目标所在交点即点击坐标")
PY
rm -f "$RAW"
