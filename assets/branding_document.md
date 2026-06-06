# Lifeline Medical Technologies — Canonical Branding Reference

This document is the **single source of truth** for all design tokens used across the Precision Analgesia website, iOS app, and marketing assets. All values are drawn directly from the production iOS application.

---

## 1. Color System (Light & Dark Mode)

The system uses standard Tailwind CSS color palettes to map semantic roles, ensuring perfect consistency between the marketing website and the iOS app.

### Action / Interactive (Teal)
- **Use:** Primary buttons, active states, interactive UI elements.
- **Light Mode:** Teal 600 (`#0D9488` / `RGB: 13, 148, 136`)
- **Dark Mode:** Teal 400 (`#2DD4BF` / `RGB: 45, 212, 191`)
- **CSS variable:** `--color-action`
- **Marketing class:** `clinical-teal`

### Brand / Primary Text (Slate)
- **Use:** Corporate identity, primary web navigation, primary text.
- **Light Mode:** Slate 900 (`#0F172A` / `RGB: 15, 23, 42`)
- **Dark Mode:** Slate 100 (`#F1F5F9` / `RGB: 241, 245, 249`)
- **CSS variable:** `--color-text-primary`
- **Marketing class:** `clinical-slate`

### Danger / Critical Warning (Rose)
- **Use:** Medical risk alerts, safety thresholds, high-priority contraindications.
- **Light Mode:** Rose 600 (`#E11D48` / `RGB: 225, 29, 72`)
- **Dark Mode:** Rose 400 (`#FB7185` / `RGB: 251, 113, 133`)
- **CSS variable:** `--color-danger`
- **Marketing class:** `clinical-rose`

### Warning / Cautionary State (Amber)
- **Use:** Non-blocking clinical warnings, calculation modifications.
- **Light Mode:** Amber 600 (`#D97706` / `RGB: 217, 119, 6`)
- **Dark Mode:** Amber 400 (`#FBBF24` / `RGB: 251, 191, 36`)
- **CSS variable:** `--color-warning`
- **Marketing class:** `clinical-amber`

### Surface Base
- **Use:** Page backgrounds, app backgrounds.
- **Light Mode:** Slate 50 (`#F8FAFC` / `RGB: 248, 250, 252`)
- **Dark Mode:** Slate 900 (`#0F172A` / `RGB: 15, 23, 42`)
- **CSS variable:** `--color-surface-base`

---

## 2. Accessibility Guidelines

> **Accessibility Rule:** Never use color as the sole signifier for any alert state.
> Every use of Rose (Danger) or Amber (Warning) MUST be paired with:
> - A distinct icon (e.g., `alert-triangle`, `check-circle`)
> - OR an explicit text prefix (e.g., "⚠ CRITICAL:")

**WCAG Contrast Matrix (Light Mode Context):**
- `#FFFFFF` on `#0F172A` (Slate 900) → ~14.1:1 ✅ AAA
- `#FFFFFF` on `#0D9488` (Teal 600) → ~3.3:1 ❌ FAILS AA (Note: Large text >18pt passes, but use with caution. Ensure bold weights for buttons).
- `#0F172A` on `#F8FAFC` (Slate 50) → ~13.5:1 ✅ AAA

*Note: In dark backgrounds (`bg-slate-900`), do not place Teal 600 or Rose 600 text. Use lighter variants (e.g. Teal 400, or `text-white`) to maintain legibility.*

---

## 3. Typography Scale

**Primary Typeface:** Inter (geometric sans-serif)
- Loaded via: Google Fonts CDN (`Inter:wght@300;400;500;600;700;800;900`)

---

## 4. SVG Icon Standards

- `viewBox="0 0 24 24"` required on all icons
- `stroke-width: 2px` on all line icons
- Icon library: Lucide v0.460.0 (pinned)

---

## 5. Spacing System (4px Baseline)

All padding, margins, and gaps must conform to a strict 4px baseline grid. Arbitrary pixel values (e.g., 17px, 23px) are strictly forbidden. Use Tailwind's default spacing scale which perfectly maps to this system:

- **Micro (4px / 0.25rem):** Internal component padding, tight icon-to-text gaps. (Tailwind: `p-1`, `gap-1`)
- **Small (8px / 0.5rem):** Standard component gaps, list item spacing. (Tailwind: `p-2`, `gap-2`)
- **Base (16px / 1rem):** Standard container padding, form field spacing. (Tailwind: `p-4`, `gap-4`)
- **Medium (24px / 1.5rem):** Section internal spacing, card padding. (Tailwind: `p-6`, `gap-6`)
- **Large (32px / 2rem):** Sub-section spacing, major component gaps. (Tailwind: `p-8`, `gap-8`)
- **X-Large (48px / 3rem):** Page section breaks (mobile). (Tailwind: `py-12`, `gap-12`)
- **2X-Large (64px / 4rem):** Page section breaks (desktop). (Tailwind: `py-16`, `gap-16`)

---

## 6. Responsive Layout Matrix

The grid system targets specific clinical hardware bounds by overriding default breakpoints:

- **Mobile (Base, `< 768px`):** Optimizes for `375px–430px` bounds (native iOS portrait).
- **Tablet (`md: 768px`):** Targeted for clinical mounting systems (iPad mini/standard portrait).
- **Desktop/Landscape (`lg: 1024px`):** Targeted for landscape tablet and standard clinical workstations.
- **Max Container (`xl: 1280px`):** We enforce a hard `1280px` maximum width container (even on `1440px+` viewports) to protect reading line-length comfort (optimal characters per line).

---

## 7. Regulatory Vocabulary Boundaries

As a clinical software platform governed by regulatory bodies (e.g., FDA, EMA), all content generation and copywriting must strictly adhere to cleared compliance parameters.

**Mandatory Guardrails:**
- **No Diagnostic Assertions:** The system must never claim to "diagnose," "treat," "cure," or "prevent" any condition. Use phrasing such as "assists in monitoring," "provides clinical decision support," or "highlights risk factors."
- **No Unapproved Device Operations:** Never instruct or imply that the software directly alters patient physiology or hardware infusion pumps without clinician intervention. The software is a *decision support* tool.
- **Absolute Terminology Ban:** Avoid words like "guarantees," "safe," "failsafe," or "eliminates risk." Use "mitigates," "reduces the likelihood of," or "supports safety protocols."

---

*Last updated: June 2026 — Lifeline Medical Technologies, LLC*
