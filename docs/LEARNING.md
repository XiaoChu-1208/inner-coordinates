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

## The eyes-open pass

1. **Normalize** the window — pin it top-left, read back the actual geometry, store it as the `fingerprint`. This is what makes coordinates reproducible.
2. **Screenshot with a grid** — `lib/grab-grid.sh "<proc>"` overlays a labelled coordinate grid so you read a control's click point straight off the intersection. This is faster and more accurate than eyeballing thumbnails (eyeballing drifts 30–60px).
3. **Record the whole screen (inner figma)** — you already see the full screen for one button, so record *every* visible control's position, including the ones you didn't click: titles, tabs, list/category structure, other buttons. Mark each as **stable skeleton** (fixed position → blind-runnable) or **content-dependent** (moves with scroll/content → must look). The library compounds: profiles grow screen by screen.
4. **Prefer the most robust trigger** per control: keyboard shortcut > menu-by-name > accessibility element > cached coordinate. Cache coordinates only for the immovable skeleton, never for changing content (a specific song, a specific message).

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
