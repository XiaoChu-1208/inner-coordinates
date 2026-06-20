#!/usr/bin/env bash
# Inner Coordinates — one-shot dependency setup & check.
# 装齐/自检本项目需要的 peekaboo + cliclick + Pillow,并提示权限与 iPhone 镜像前提。
set -uo pipefail
have(){ command -v "$1" >/dev/null 2>&1; }
ok(){ printf "  \033[32mok\033[0m   %s\n" "$1"; }
miss(){ printf "  \033[31mMISS\033[0m %s\n" "$1"; }

echo "Inner Coordinates · setup"
echo "── checking dependencies ──"

# cliclick — real CGEvents: modified-key paste (Cmd+V into mirror) + clicks. Essential.
if have cliclick; then ok "cliclick"; else
  if have brew; then echo "  installing cliclick…"; brew install cliclick && ok "cliclick" || miss "cliclick (brew install cliclick failed)";
  else miss "cliclick — install Homebrew (https://brew.sh) then: brew install cliclick"; fi
fi

# peekaboo — click / move / swipe / scroll. (Clicks can also be done with cliclick c:x,y if you prefer.)
if have peekaboo; then ok "peekaboo"; else
  miss "peekaboo — see https://github.com/steipete/peekaboo (brew install peekaboo, or the app)."
  echo "       fallback: clicks work with cliclick (c:x,y); swipe/scroll need peekaboo."
fi

# python3 + Pillow — for grab-grid.sh (coordinate-grid screenshots).
if have python3; then
  if python3 -c "import PIL" 2>/dev/null; then ok "Pillow (python3 -c 'import PIL')"; else
    echo "  installing Pillow…"; python3 -m pip install --user Pillow >/dev/null 2>&1 && ok "Pillow" || miss "Pillow (python3 -m pip install --user Pillow) — grab-grid.sh needs it";
  fi
else miss "python3 — needed for lib/grab-grid.sh"; fi

# built-ins
have screencapture && ok "screencapture (built-in)"
have osascript     && ok "osascript / AppleScript (built-in)"

echo
echo "── permissions (System Settings → Privacy & Security) ──"
echo "  grant your terminal / agent:  Screen Recording  +  Accessibility"
echo
echo "── iPhone Mirroring channel (only if you'll drive iOS apps) ──"
echo "  1) set up iPhone Mirroring (macOS Sequoia+)"
echo "  2) turn ON Handoff / Universal Clipboard  (General → AirDrop & Handoff)"
echo "     — Chinese text is pasted via the clipboard, which Handoff syncs to iOS."
echo
echo "Done. Drop this folder into ~/.claude/skills/ to use as a Claude Code skill:"
echo "  ln -s \"\$PWD\" ~/.claude/skills/inner-coordinates"
