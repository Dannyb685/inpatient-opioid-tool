# Lifeline Medical Technologies — Canonical Branding Reference

This document is the **single source of truth** for all design tokens used across
the Precision Analgesia website, marketing assets, and social media collateral.
All values are drawn directly from the approved brand specification.

---

## 1. Color Tokens

### Primary Brand Dominant — Deep Slate Blue
```
HEX: #1A2B4C   RGB: 26, 43, 76
```
- **Use:** Corporate identity, primary web navigation elements, hero section anchors.
- **Tailwind class:** `bg-clinical-slate`, `text-clinical-slate`
- **CSS variable:** `var(--color-brand-primary)`

### Secondary Interactive — Clinical Cyan
```
HEX: #007A87   RGB: 0, 122, 135
```
- **Use:** Primary buttons, active states, interactive UI elements **exclusively**.
- **Tailwind class:** `bg-clinical-cyan`, `text-clinical-cyan`, `border-clinical-cyan`
- **CSS variable:** `var(--color-interactive)`
- **⚠ Forbidden pairing:** Do NOT place Clinical Cyan text on Deep Slate Blue background (contrast ratio ~2.1:1 — fails WCAG AA).

---

## 2. Functional Alert Spectrum

> **Accessibility Rule:** Never use color as the sole signifier for any alert state.
> Every use of Crimson, Amber, or Emerald MUST be paired with:
> - A distinct icon (e.g., `alert-triangle`, `check-circle`)
> - OR an explicit text prefix (e.g., "⚠ CRITICAL:", "✓ VALIDATED:")

### Critical Warning — Crimson
```
HEX: #D32F2F   RGB: 211, 47, 47
```
- **Use:** Medical risk alerts, safety thresholds, high-priority contraindications.
- **Tailwind class:** `text-clinical-crimson`, `bg-clinical-crimson`, `border-clinical-crimson`
- **CSS variable:** `var(--color-alert-critical)`

### Cautionary State — Amber
```
HEX: #F57C00   RGB: 245, 124, 0
```
- **Use:** Non-blocking clinical warnings, calculation modifications.
- **Tailwind class:** `text-clinical-amber`, `bg-clinical-amber`, `border-clinical-amber`
- **CSS variable:** `var(--color-alert-cautionary)`

### Success / Validated State — Emerald
```
HEX: #388E3C   RGB: 56, 142, 60
```
- **Use:** Validated operations, correct dosages, system confirmations.
- **Tailwind class:** `text-clinical-emerald`, `bg-clinical-emerald`
- **CSS variable:** `var(--color-alert-success)`

---

## 3. Neutral Canvas

### Surface Base — Off-White
```
HEX: #F8F9FA   RGB: 248, 249, 250
```
- **Use:** Page backgrounds, card surfaces, alternating section backgrounds.
- **CSS variable:** `var(--color-surface-base)`

### Text Primary — Charcoal
```
HEX: #212121   RGB: 33, 33, 33
```
- **Use:** Headings, body text, all primary readable content.
- **Tailwind class:** `text-clinical-charcoal`
- **CSS variable:** `var(--color-text-primary)`

### Text Secondary — Muted Gray
```
HEX: #616161   RGB: 97, 97, 97
```
- **Use:** Supporting text, metadata, source citations.
- **Tailwind class:** `text-clinical-muted`
- **CSS variable:** `var(--color-text-secondary)`

---

## 4. Typography Scale

| Role | Size | Weight | Line Height | Tailwind Utility |
|---|---|---|---|---|
| Document Titles | 32px | Bold (700) | 1.2 | `.text-title` |
| Section Headings | 24px | Semi-Bold (600) | 1.3 | `.text-heading` |
| Subheadings / UI Labels | 16px | Medium (500) | 1.4 | `.text-sublabel` |
| Body Text / Clinical Data | 14px | Regular (400) | 1.5 | `.text-body` |
| Micro-notation / Citations | 12px | Regular (400) | 1.4 | `.text-micro` |

**Primary Typeface:** Inter (geometric sans-serif)
- Fallbacks: `-apple-system`, `system-ui`, `sans-serif`
- Loaded via: Google Fonts CDN (`Inter:wght@300;400;500;600;700;800;900`)

---

## 5. WCAG 2.1 AA Contrast Matrix

| Text Color | Background | Ratio | Status |
|---|---|---|---|
| `#FFFFFF` | `#1A2B4C` (Brand Primary) | ~10.4:1 | ✅ AAA |
| `#FFFFFF` | `#007A87` (Interactive) | ~4.7:1 | ✅ AA |
| `#212121` | `#F8F9FA` (Surface Base) | ~18.1:1 | ✅ AAA |
| `#616161` | `#FFFFFF` | ~5.9:1 | ✅ AA |
| `#007A87` | `#1A2B4C` | ~2.1:1 | ❌ FAIL — FORBIDDEN |
| `#616161` | `#F8F9FA` | ~5.9:1 | ✅ AA |

---

## 6. Image & Asset Rendering Prompt

Use this directive for all AI-generated clinical photography:

> Studio lighting, clean clinical healthcare setting, high-contrast composition, 85mm focal length.
> Background palette restricted to Surface Base Off-White (#F8F9FA) and Text Secondary Muted Gray (#616161).
> Primary subject accents: Deep Slate Blue (#1A2B4C) shadows and Clinical Cyan (#007A87) highlights.
> Avoid warm tones, cinematic lens flares, or abstract artistic rendering.
> Ensure absolute geometric precision of all medical equipment depicted.

---

## 7. SVG Icon Standards

- `viewBox="0 0 24 24"` required on all icons
- Color fills via inline styles using: `#1A2B4C`, `#007A87`, `#212121`
- `stroke-width: 2px` on all line icons
- Icon library: Lucide v0.460.0 (pinned)

---

*Last updated: June 2026 — Lifeline Medical Technologies, LLC*
