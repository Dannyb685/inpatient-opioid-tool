import posthog from 'posthog-js';

// TODO: Replace with your actual Project API Key and Host
const POSTHOG_KEY = 'phc_INSERT_KEY_HERE';
const POSTHOG_HOST = 'https://us.i.posthog.com'; 

export const initAnalytics = () => {
    // Only initialize if we are in a browser environment and have a key (or placeholder)
    if (typeof window !== 'undefined') {
        posthog.init(POSTHOG_KEY, {
            api_host: POSTHOG_HOST,
            autocapture: false, // We will manually track events for precision
            capture_pageview: false, // We will manually track page/tab views
            persistence: 'localStorage',
        });
    }
};

export const trackEvent = (eventName: string, properties?: Record<string, any>) => {
    if (typeof window !== 'undefined') {
        posthog.capture(eventName, properties);
    }
};

export const trackPageView = (viewName: string) => {
    trackEvent('$pageview', {
        $current_url: window.location.href,
        view: viewName
    });
};
