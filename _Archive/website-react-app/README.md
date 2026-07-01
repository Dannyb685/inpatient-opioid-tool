# Archived: standalone React calculator app

Moved here 2026-07-01. Not wired into any build entry and not reachable in production — confirmed dead, not mid-migration. Kept (not deleted) per the venture's standing "never delete without instruction" rule.

## Timeline
- Dec 2025: this app (`web.tsx` → `OpioidPrecisionApp` → `AssessmentView`/`CalculatorView`) *was* the site's homepage, mounted into `index.html` via `<div id="root">` + `<script src="/src/web.tsx">`.
- 2026-01-06 (`48f1f25`): `index.html` was rewritten into static marketing HTML; the mount point was deliberately removed.
- 2026-01-06 to 2026-01-20: this tree kept getting speculative work anyway — Supabase auth (`LoginView.tsx`, `contexts/AuthContext.tsx`, `lib/supabase.ts`), Zustand stores — looks like an attempted pivot toward a gated logged-in app.
- 2026-01-20 (`d3a30c4`): last commit to touch any of these files.
- 2026-06-11/12 (`610b67f`, `f050309`): a completely independent "Live Demo" was built from scratch — `public/demo.html`, a self-contained vanilla-JS hand-port of the iOS taper/conversion logic — and wired into site nav as the site's actual interactive calculator. This app was never revived.

## Why archived instead of wired back in
`vite.config.ts`'s `rollupOptions.input` only ever declared `main`/`privacy`/`support` — no entry ever mounted this app in the current tree, and neither Vercel nor GitHub Pages build paths could reach it. No `capacitor.config.*` exists anywhere in the repo either, so the `cap:open`/`cap:sync` scripts (which depend on `build:web`) would not have surfaced this app on iOS. Wiring it back in now would resurrect unfinished auth scaffolding and stand up a third independent implementation of calculator/assessment clinical logic on the website (alongside `public/demo.html`'s hand-port and the SSOT), which is the exact "one fact, many homes" drift problem the venture's Clinical Governance layer exists to prevent. See `Analgesia Precision/CLAUDE.md` §3.2.

## `src/data.ts` was deliberately left in `src/`, not archived
`main.ts` (the Obsidian-plugin entry, built by `esbuild.config.mjs` into `main.js`) imports `DRUG_DATA` from `./src/data`. `ReferenceView.tsx` in this archive also imports it, so if this app is ever revived, restore `src/data.ts`'s original path or copy it back in.

## If reviving this
- `tsconfig.json` excludes `_Archive` — moving files back to `src/` will bring them back into `tsc -noEmit` type-checking (part of `npm run build`).
- You'll need to add a real Vite entry (e.g. `app.html` with `<div id="root">` + `<script type="module" src="/src/web.tsx">`) and add it to `vite.config.ts`'s `rollupOptions.input`.
- Decide first whether this should still exist alongside `public/demo.html`, or replace it — don't let both stay live without reconciling which one is the SSOT-tracked surface (see parity follow-up below).
