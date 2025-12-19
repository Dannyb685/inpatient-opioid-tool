import * as React from 'react';
import { createRoot } from 'react-dom/client';
import OpioidPrecisionApp from './OpioidPrecisionApp';
import './input.css';

const container = document.getElementById('root');
if (container) {
    const root = createRoot(container);
    root.render(
        <React.StrictMode>
            <OpioidPrecisionApp />
        </React.StrictMode>
    );
}
