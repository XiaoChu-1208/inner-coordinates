# Learning new apps — a guide

The core philosophy: **learn well once, then carry it through.** A learning pass is slow and eyes-open; everything after is the *inner chain* — run from memory, look only at choke points. Don't pay the learning cost twice.

## When to learn (and when not to)

- **No profile yet for this app** → offer a ~30s learning pass: *"Want me to learn this once? After that it's instant."* If yes, do an eyes-open pass and save a profile. If no, operate ad-hoc without saving.
- **Profile exists, fingerprint matches** → don't re-learn. Run the inner chain; `rescale` if the window size differs.
- **Profile exists but something changed** (app update, different screen) → re-learn *only the spot that broke*, update the profile. Never re-learn the whole app for one moved button.

## Channel first (step 0)

Decide **native macOS window** vs **iPhone Mirroring** before touching anything:

- Native if the app has a working Mac version whose content screenshots fine and that doesn't fight automation.
- iPhone Mirroring if the Mac version is anti-screenshot / anti-automation (WeChat), the app is iOS-only or a mini-program (Meituan), or your account/data lives on the phone.
- If both are viable, recommend one and let the user pick.

## Best way to learn: record a demonstration (zero eyeballing)

The most reliable way to learn an app is **not** for the agent to eyeball coordinates off a screenshot — that drifts (a label's text center is *not* its tappable box; we lost hours to a temperature button whose hit-box sat 35px left of its text). Instead, **you demonstrate the flow once and we record your real clicks.**

```bash
python3 lib/record.py "iPhone Mirroring" /tmp/ic-recording.json
# do the flow yourself: click the real buttons, paste/type as normal
# press ESC (or `touch /tmp/ic-stop`) to finish
```

`record.py` normalizes the window, then records every click as **window-relative coordinates** (exactly where you clicked — no estimation), plus a per-click screenshot and the clipboard contents at that moment (so pasted Chinese text is captured even though IME keystrokes aren't). It saves incrementally, so nothing is lost if interrupted. The agent then turns the recording into a replay script — and because the coordinates are *your* clicks, replay lands dead-on.

Permissions: Accessibility (mouse), Input Monitoring (keyboard/ESC), Screen Recording (screenshots). If ESC doesn't stop it, grant Input Monitoring or use the `touch /tmp/ic-stop` fallback.

Use the eyes-open pass below when you can't demonstrate (no human handy); use recording whenever you can — it's far more accurate.

## The eyes-open pass

1. **Normalize** the window — pin it top-left, read back the actual geometry, store it as the `fingerprint`. This is what makes coordinates reproducible.
2. **Screenshot with a grid** — `lib/grab-grid.sh "<proc>"` overlays a labelled coordinate grid so you read a control's click point straight off the intersection. This is faster and more accurate than eyeballing thumbnails (eyeballing drifts 30–60px).
3. **Record the whole screen (inner figma)** — you already see the full screen for one button, so record *every* visible control's position, including the ones you didn't click: titles, tabs, list/category structure, other buttons. Mark each as **stable skeleton** (fixed position → blind-runnable) or **content-dependent** (moves with scroll/content → must look). The library compounds: profiles grow screen by screen.
4. **Prefer the most robust trigger** per control: keyboard shortcut > menu-by-name > accessibility element > cached coordinate. Cache coordinates only for the immovable skeleton, never for changing content (a specific song, a specific message).

## Emit a script — the real output of learning

Notes in a profile are not enough to run a flow in one pass. A coordinate list leaves the *re-assembly* to the model, and a model re-assembling a chain falls back into "act, screenshot, act" — one tap and one screenshot per turn. That's why an agent keeps going step-by-step no matter how firmly the prose says "run it in one go": you can't reliably suppress that reflex with instructions.

**So the durable output of a learning pass is a script, not just notes.** Package the stable chain into one `lib/<app>-<flow>.sh` — every click and wait inside it, Chinese text set via `pbcopy` then pasted with a real `cliclick` Cmd+V, and parameters for the variable bits (store, item, options). The agent runs that **one command** and the whole chain executes; there is physically no "between" to screenshot.

- **When it drifts, fix the script, don't re-learn.** A coordinate moved? Change that one number in the script. Script-level self-heal is far faster than re-running a learning pass.
- The profile still matters — it's the map, the pitfalls, and the source of the coordinates — but it's the *spec sheet*; the script is what runs.
- See `lib/meituan-order.sh` (a parameterized full-chain order script) and `lib/meituan-search.sh` for examples.

## The inner chain (execution)

Once learned:

- **Localize once:** the app may sit wherever you left it — screenshot one frame to see which screen you're on, then reset to a known anchor (e.g. a Home tab) or continue from there.
- **Run the stable skeleton from memory** — batch the predictable taps, no screenshot between them.
- **Screenshot only on surprises:** (1) an action seems to have misfired (nothing changed, focus may be lost, a number doesn't match expectation), or (2) something genuinely new appears (a screen/dialog/field the profile never recorded). Content-dependent steps count as "can't predict" → look. The one extra look worth taking even when confident: a **money / irreversible final tap** (look, don't ask).
- **Turn uncertain into certain when you can** — e.g. use an in-app search box to find an item by name instead of scrolling a list whose positions float.

## If the user asked for autonomy

They want the *result*, not to be re-asked. Align once up front ("here's what I'll do and where I'll stop"), then run; stop only at real choke points. Don't pause to confirm things you can compute from the map. Stop for a privacy/safety consequence **only if the user might have overlooked it** — if they clearly asked for the outcome, they know; proceed. The single exception is a secret only they can provide (a payment password): ask at that step, never store or guess it.

## Pitfalls worth a note in the profile

Whenever you hit a sharp edge, write it into the profile so the next run (and the next person) skips it. Examples seen in the wild: a product page that previews a big image and dead-ends; changing a spec generating a *new* cart variant (so the old one must be deleted); a coupon that isn't auto-applied; a "save" button that triggers an unwanted overlay; a checkout defaulting to a payment method you didn't want. Also log *when* a transient confirmation (like a paste-focus prompt) appears, as a logic point — so next time it's predictable, not a surprise.
