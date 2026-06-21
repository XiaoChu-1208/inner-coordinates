#!/usr/bin/env python3
# record.py — 示范式学习(learn by demonstration)。
# 归一化目标窗口 → 录【你的每次点击(窗口相对坐标 + 当时截图 + 当时剪贴板) + 回车 + 拉丁输入】。
# 结束:按 ESC，或 `touch /tmp/ic-stop`(双保险,防键盘"输入监控"权限没开时 ESC 失灵)。
# 每次点击【即时存盘】,即使被杀也不丢。录下的点击坐标 = 你真点的位置(零目测误差)。
#
#   python3 record.py "iPhone Mirroring" /tmp/ic-recording.json
# 权限:辅助功能(Accessibility)=鼠标;输入监控(Input Monitoring)=键盘/ESC;屏幕录制=截图。
import json, subprocess, time, sys, os, threading
from pynput import mouse, keyboard

PROC = sys.argv[1] if len(sys.argv) > 1 else "iPhone Mirroring"
OUT  = sys.argv[2] if len(sys.argv) > 2 else "/tmp/ic-recording.json"
STOP = "/tmp/ic-stop"

def osa(s): return subprocess.run(["osascript","-e",s], capture_output=True, text=True).stdout.strip()
def pbpaste(): return subprocess.run(["pbpaste"], capture_output=True, text=True).stdout

osa(f'tell application "System Events" to tell process "{PROC}"\n set frontmost to true\n set position of front window to {{0,25}}\nend tell')
time.sleep(0.5)
geo = osa(f'tell application "System Events" to tell process "{PROC}" to get {{position, size}} of front window')
nums = [int(x) for x in geo.replace(",", " ").split() if x.strip().lstrip("-").isdigit()]
wx, wy, ww, wh = (nums + [0, 30, 346, 760])[:4]

events, t0, done = [], time.time(), threading.Event()
def now(): return round(time.time() - t0, 2)
def shot(tag):
    p = f"/tmp/ic-rec-{tag}.png"
    subprocess.run(["screencapture", "-x", "-R", f"{wx},{wy},{ww},{wh}", p])
    return p
def save():
    json.dump({"proc": PROC, "window": [wx, wy, ww, wh], "events": events},
              open(OUT, "w"), ensure_ascii=False, indent=1)
shot("start"); save()

def on_click(x, y, button, pressed):
    if not pressed: return
    rx, ry = round(x - wx), round(y - wy)
    i = sum(1 for e in events if e["type"] == "click")
    events.append({"t": now(), "type": "click", "rel": [rx, ry],
                   "screen": [round(x), round(y)], "clip": pbpaste()[:120], "shot": shot(i)})
    save()                                            # 即时存盘
    print(f"  #{i} click rel({rx},{ry})  clip='{pbpaste()[:20]}'", flush=True)

buf = []
def flush():
    if buf:
        events.append({"t": now(), "type": "text", "text": "".join(buf)}); buf.clear(); save()
def on_press(key):
    if key == keyboard.Key.esc:
        flush(); done.set(); return False
    if key == keyboard.Key.enter:
        flush(); events.append({"t": now(), "type": "key", "key": "enter"}); save(); print("  [enter]", flush=True)
    elif getattr(key, "char", None):
        buf.append(key.char)

try: os.remove(STOP)
except OSError: pass
print(f"REC {PROC} window=({wx},{wy},{ww}x{wh})。点你的流程、粘贴/输入照常。结束:按 ESC 或 `touch {STOP}`。", flush=True)
ml = mouse.Listener(on_click=on_click); ml.start()
kl = keyboard.Listener(on_press=on_press); kl.start()
while not done.is_set():
    if os.path.exists(STOP):
        flush(); break
    time.sleep(0.3)
ml.stop(); kl.stop(); save()
nclick = sum(1 for e in events if e["type"] == "click")
print(f"\n保存 {nclick} 次点击 + 输入 → {OUT}", flush=True)
