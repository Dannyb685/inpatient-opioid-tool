/** @type {import('tailwindcss').Config} */
module.exports = {
    content: ["./index.html", "./privacy.html", "./support.html"],
    theme: {
        extend: {
            colors: {
                clinical: {
                    teal: '#0d9488',
                    rose: '#e11d48',
                    amber: '#d97706',
                    slate: '#0f172a',
                    bg: '#f8fafc'
                }
            },
            fontFamily: {
                sans: ['Inter', '-apple-system', 'system-ui', 'sans-serif'],
            }
        }
    },
    plugins: [],
}
