/**
 * adminService.js — Admin-specific operations (login + reservations only).
 * User management → userService.js
 * Product management → productService.js
 * Category management → productService.js (categories)
 */
import { apiClient } from './apiClient';

export const adminService = {
    login: (email, password) => apiClient.post('/admin/login', { email, password }),

    // Reservations
    getReservations: () => apiClient.get('/api/staff/reservations'),
    updateReservationStatus: (reservationId, status) =>
        apiClient.patch(`/api/staff/reservations/${reservationId}`, { status }),

    // Audit logs
    getAuditLogs: (limit = 100, offset = 0) =>
        apiClient.get(`/admin/audit-logs?limit=${limit}&offset=${offset}`),
};
