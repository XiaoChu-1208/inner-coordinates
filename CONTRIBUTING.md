# Contributing your inner coordinates

This library gets better the more apps it covers. If you've taught an app to your agent, **share the map** so everyone can reuse it.

## What a contribution is

One `profiles/<app>.json` — a coordinate map of an app (or a new flow for an existing one), following the shape of the profiles already in [`profiles/`](profiles/). Look at `profiles/meituan-waimai-ios-mirror.json` for a fully worked example, and add an entry to `profiles/_index.json`.

A good profile records:

- **`fingerprint`** — the normalized window geometry the coordinates were learned at (position, size, displayScale) + device/app context (e.g. iPhone model, app version). This is the reference frame `lib/rescale.sh` scales from.
- **Per-screen maps** — for every screen you passed through, the position of *all* visible controls (the "inner figma" principle), not just the ones you clicked. Mark which coordinates are **stable skeleton** (blind-runnable) vs **content-dependent** (must look).
- **The flow** — the ordered chain, with notes on waits, choke points, and pitfalls you hit.

## The golden rule: de-identify

**Never commit personal data.** Before you submit, scrub:

- passwords / PINs / payment passwords (these are never stored anyway)
- phone numbers, addresses, names, account IDs, emails
- anything that identifies *you* specifically

Use placeholders like `<地址,脱敏>` / `<phone, redacted>`. Coordinates and flows are fine to share; the values behind them are not. Keep store/app names only if they're public businesses, not your private info.

**This applies the moment your profile leaves your machine — fork *or* PR.** If you fork this repo and push your own profiles, scrub them before they go public, exactly as you would for a PR here. A quick grep for your name / phone / address / any password before you push saves you later.

## How to learn + submit

1. Read [docs/LEARNING.md](docs/LEARNING.md) and learn the app with your agent.
2. Save the map to `profiles/<app>.json`; add a row to `profiles/_index.json`.
3. Run the de-identify check (grep for phone numbers, your name, your address, any password).
4. Test it once end-to-end on a clean start.
5. Open a PR. In the description, say: device/OS, app version, channel (native or iPhone Mirroring), and what operations are covered + verified.

## Coordinate portability

Coordinates are window-geometry-relative, not resolution-relative. Always learn at the **top-left-pinned normalized window**, record the reference geometry in `fingerprint`, and others will `rescale` to their own window. For iPhone Mirroring profiles, note the **iPhone model** — same-resolution models are drop-in, others need a quick verify (see the compatibility table in the README).

Thanks for growing the library. 🙏 (text only — no emoji in profiles, please.)
