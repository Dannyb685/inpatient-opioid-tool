import * as React from 'react';
import { createRoot } from 'react-dom/client';
import { Analytics } from '@vercel/analytics/react';
import OpioidPrecisionApp from './OpioidPrecisionApp';
import './input.css';

const container = document.getElementById('root');
if (container) {
    const root = createRoot(container);
    root.render(
        <React.StrictMode>
            <OpioidPrecisionApp />
            <Analytics />
        </React.StrictMode>
    );
}
