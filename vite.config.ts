import path from 'path';
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
    base: './', // CRITICAL: Ensures assets are loaded with relative paths for Capacitor
    plugins: [react()],
    resolve: {
        alias: {
            '@': path.resolve(__dirname, './src'),
        }
    },
    build: {
        rollupOptions: {
            input: {
                main: path.resolve(__dirname, 'index.html'),
                privacy: path.resolve(__dirname, 'privacy.html'),
                support: path.resolve(__dirname, 'support.html'),
            },
        },
    },
    server: {
        port: 3000,
    }
});
