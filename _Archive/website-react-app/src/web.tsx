import * as React from 'react';
import { createRoot } from 'react-dom/client';
import OpioidPrecisionApp from './OpioidPrecisionApp';
import { AuthProvider } from './contexts/AuthContext';
import './input.css';

import { initAnalytics } from './analytics';

const container = document.getElementById('root');
if (container) {
    // Initialize Analytics
    initAnalytics();

    const root = createRoot(container);
    root.render(
        <React.StrictMode>
            <AuthProvider>
                <OpioidPrecisionApp />
            </AuthProvider>
        </React.StrictMode>
    );
}
