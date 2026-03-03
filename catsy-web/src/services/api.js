const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000';

/**
 * A generic fetch wrapper for making API calls to the backend bridge.
 */
export const apiClient = async (endpoint, options = {}) => {
    // Ensure endpoint starts with a slash
    const path = endpoint.startsWith('/') ? endpoint : `/${endpoint}`;

    try {
        const response = await fetch(`${API_BASE_URL}${path}`, {
            ...options,
            headers: {
                'Content-Type': 'application/json',
                ...options.headers,
            },
        });

        if (!response.ok) {
            throw new Error(`API Error: ${response.status} ${response.statusText}`);
        }

        return await response.json();
    } catch (error) {
        console.error(`❌ [API Request Failed] ${path}:`, error);
        throw error;
    }
};

// Exporting standard HTTP methods for easier usage
export default {
    baseURL: API_BASE_URL,
    get: (endpoint) => apiClient(endpoint),
    post: (endpoint, body) => apiClient(endpoint, { method: 'POST', body: JSON.stringify(body) }),
    put: (endpoint, body) => apiClient(endpoint, { method: 'PUT', body: JSON.stringify(body) }),
    delete: (endpoint) => apiClient(endpoint, { method: 'DELETE' }),
};
