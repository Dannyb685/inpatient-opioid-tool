/** @type {import('tailwindcss').Config} */
// Canonical Design Token System — Lifeline Medical Technologies
// Colors directly match the iOS app's src/input.css to ensure complete visual consistency.
module.exports = {
    content: ["./index.html", "./privacy.html", "./support.html", "./integration.html"],
    theme: {
        screens: {
            'md': '768px',   // Tablet Portrait
            'lg': '1024px',  // Tablet Landscape
            'xl': '1280px',  // Max Desktop Container
        },
        container: {
            center: true,
            screens: {
                'xl': '1280px',
            }
        },
        extend: {
            colors: {
                clinical: {
                    // Primary Brand Dominant — Slate 900
                    slate:   '#0F172A',
                    // Secondary Interactive — Teal 600
                    teal:    '#0D9488',
                    // Critical Warning — Rose 600
                    rose:    '#E11D48',
                    // Cautionary State — Amber 600
                    amber:   '#D97706',
                    // Surface Base — Slate 50
                    bg:      '#F8FAFC',
                }
            },
            fontFamily: {
                // Primary typeface: Inter (geometric sans-serif for clinical legibility)
                sans: ['Inter', '-apple-system', 'system-ui', 'sans-serif'],
            },
        }
    },
    plugins: [],
}
