import { logger } from '../utils/logger';
import { getAccessToken, clearSession } from '../utils/sessionManager';
import { toast } from '../context/ToastContext';

const API_BASE_URL = 'http://127.0.0.1:8000';

class ApiError extends Error {
    constructor(message, status, data) {
        super(message);
        this.status = status;
        this.data = data;
    }
}

/**
 * Core HTTP Client to abstract away fetch calls from components
 * Enforces Single Responsibility and Dependency Inversion
 */
export const apiClient = {
    async request(endpoint, options = {}) {
        const url = `${API_BASE_URL}${endpoint}`;
        
        // Auto-inject JWT token if available
        const token = getAccessToken();
        const headers = {
            'Content-Type': 'application/json',
            ...(token ? { 'Authorization': `Bearer ${token}` } : {}),
            ...(options.headers || {}),
        };

        const config = {
            ...options,
            headers,
        };

        try {
            const response = await fetch(url, config);
            
            // Only parse json if there's content
            const contentType = response.headers.get("content-type");
            const data = contentType && contentType.includes("application/json") 
                ? await response.json() 
                : null;

            if (!response.ok) {
                logger.error(`API Error [${response.status}] at ${endpoint}`, data);
                
                // Fast-fail and trigger redirect for expired/invalid tokens
                if (response.status === 401 && !options.skipAuthError) {
                    clearSession();
                    window.dispatchEvent(new CustomEvent('auth-error', {
                        detail: {
                            title: 'Session Expired',
                            message: 'Your session has expired or is invalid. Please sign in again.',
                            status: 401,
                        }
                    }));
                } else if (!options.skipGlobalToast) {
                    const MESSAGE_MAP = {
                        403: 'You do not have permission to perform this action.',
                        404: 'The requested item could not be found. It may have been deleted.',
                        500: 'Something went wrong on our end. Please try again in a moment.',
                    };
                    // 400 and 422 are handled by components.
                    if (response.status !== 400 && response.status !== 422 && response.status !== 401) {
                        const message = MESSAGE_MAP[response.status] ?? 'Could not connect. Please check your internet connection.';
                        toast.error(message);
                    }
                }

                throw new ApiError(data?.detail || response.statusText, response.status, data);
            }

            return data;
        } catch (error) {
            logger.error(`Network Error at ${endpoint}`, error);
            throw error;
        }
    },

    get(endpoint, options = {}) {
        return this.request(endpoint, { ...options, method: 'GET' });
    },

    post(endpoint, body, options = {}) {
        return this.request(endpoint, {
            ...options,
            method: 'POST',
            body: JSON.stringify(body),
        });
    },

    put(endpoint, body, options = {}) {
        return this.request(endpoint, {
            ...options,
            method: 'PUT',
            body: JSON.stringify(body),
        });
    },

    patch(endpoint, body, options = {}) {
        return this.request(endpoint, {
            ...options,
            method: 'PATCH',
            body: JSON.stringify(body),
        });
    },

    delete(endpoint, options = {}) {
        return this.request(endpoint, { ...options, method: 'DELETE' });
    }
};
