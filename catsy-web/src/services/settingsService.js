import { apiClient } from './apiClient';

export const settingsService = {
    getSettings: () => apiClient.get('/api/settings'),

    updateSettings: (data) => apiClient.patch('/api/admin/settings', data),
};
