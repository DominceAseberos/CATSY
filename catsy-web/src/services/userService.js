/**
 * userService.js — Admin user management operations.
 * Split from adminService.js (Fix #8 — Interface Segregation).
 */
import { apiClient } from './apiClient';

export const userService = {
    getUsers: () => apiClient.get('/admin/users'),
    createUser: (userData) => apiClient.post('/admin/users', userData),
    changePassword: (userId, password) => apiClient.patch(`/admin/users/${userId}/password`, { password }),
    deleteUser: (userId) => apiClient.delete(`/admin/users/${userId}`),
};
