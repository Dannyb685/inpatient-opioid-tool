/** @type {import('tailwindcss').Config} */
// Design Token System — Lifeline Medical Technologies
// Exact hex values per the approved brand specification document.
module.exports = {
    content: ["./index.html", "./privacy.html", "./support.html", "./integration.html"],
    theme: {
        extend: {
            colors: {
                clinical: {
                    // Primary Brand Dominant — Deep Slate Blue
                    // Anchors corporate identity and primary web navigation elements.
                    slate:   '#1A2B4C',

                    // Secondary Interactive — Clinical Cyan
                    // Exclusive use: primary buttons, active states, interactive UI elements.
                    cyan:    '#007A87',

                    // Functional Alert Spectrum
                    // Critical Warning — Crimson (medical risk alerts, safety thresholds, high-priority contraindications)
                    crimson: '#D32F2F',
                    // Cautionary State — Amber (non-blocking clinical warnings, calculation modifications)
                    amber:   '#F57C00',
                    // Success State — Emerald (validated operations, correct dosages, system confirmations)
                    emerald: '#388E3C',

                    // Neutral Canvas
                    // Surface Base — Off-White
                    bg:      '#F8F9FA',
                    // Text Primary — Charcoal
                    charcoal:'#212121',
                    // Text Secondary — Muted Gray
                    muted:   '#616161',
                }
            },
            fontFamily: {
                // Primary typeface: Inter (geometric sans-serif for clinical legibility)
                sans: ['Inter', '-apple-system', 'system-ui', 'sans-serif'],
            },
            fontSize: {
                // Typographic scale per brand specification
                // Document Titles: 32px, Bold (700), line-height 1.2
                'title':     ['32px', { lineHeight: '1.2', fontWeight: '700' }],
                // Section Headings: 24px, Semi-Bold (600), line-height 1.3
                'heading':   ['24px', { lineHeight: '1.3', fontWeight: '600' }],
                // Subheadings / UI Labels: 16px, Medium (500), line-height 1.4
                'sublabel':  ['16px', { lineHeight: '1.4', fontWeight: '500' }],
                // Body Text / Clinical Data: 14px, Regular (400), line-height 1.5
                'body':      ['14px', { lineHeight: '1.5', fontWeight: '400' }],
                // Micro-notation / Source Citations: 12px, Regular (400), line-height 1.4
                'micro':     ['12px', { lineHeight: '1.4', fontWeight: '400' }],
            },
        }
    },
    plugins: [],
}
