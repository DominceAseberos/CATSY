import { logger } from '../utils/logger';

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
        const headers = {
            'Content-Type': 'application/json',
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
