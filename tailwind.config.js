/** @type {import('tailwindcss').Config} */
module.exports = {
    content: [
        "./src/**/*.{js,ts,jsx,tsx}",
    ],
    theme: {
        extend: {
            fontFamily: {
                sans: ['Inter', 'sans-serif'],
            },
            colors: {
                surface: {
                    base: 'rgb(var(--color-surface-base) / <alpha-value>)',
                    card: 'rgb(var(--color-surface-card) / <alpha-value>)',
                    highlight: 'rgb(var(--color-surface-highlight) / <alpha-value>)',
                },
                text: {
                    primary: 'rgb(var(--color-text-primary) / <alpha-value>)',
                    secondary: 'rgb(var(--color-text-secondary) / <alpha-value>)',
                    tertiary: 'rgb(var(--color-text-tertiary) / <alpha-value>)',
                },
                action: {
                    DEFAULT: 'rgb(var(--color-action) / <alpha-value>)',
                    bg: 'rgb(var(--color-action-bg) / <alpha-value>)',
                    border: 'rgb(var(--color-action-border) / <alpha-value>)',
                },
                danger: {
                    DEFAULT: 'rgb(var(--color-danger) / <alpha-value>)',
                    bg: 'rgb(var(--color-danger-bg) / <alpha-value>)',
                },
                warning: {
                    DEFAULT: 'rgb(var(--color-warning) / <alpha-value>)',
                    bg: 'rgb(var(--color-warning-bg) / <alpha-value>)',
                },
                border: 'rgb(var(--color-border) / <alpha-value>)',
                // Keep original palette for legacy support during refactor if needed, but prefer semantic
                teal: {
                    50: '#f0fdfa',
                    100: '#ccfbf1',
                    500: '#14b8a6',
                    600: '#0d9488',
                    700: '#0f766e',
                },
                slate: {
                    50: '#f8fafc',
                    100: '#f1f5f9',
                    200: '#e2e8f0',
                    400: '#94a3b8',
                    500: '#64748b',
                    600: '#475569',
                    800: '#1e293b',
                    900: '#0f172a',
                }
            }
        },
    },
    plugins: [],
}
