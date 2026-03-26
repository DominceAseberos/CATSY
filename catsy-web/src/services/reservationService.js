import { apiClient } from './apiClient';

export const reservationService = {
    createReservation: (reservationData) => 
        apiClient.post('/api/customer/reservations', reservationData),

    getMyReservations: () => 
        apiClient.get('/api/customer/reservations'),

    cancelReservation: (id) =>
        apiClient.delete(`/api/customer/reservations/${id}`),

    getAllReservations: () => 
        apiClient.get('/api/staff/reservations'),

    updateReservationStatus: (id, status) => 
        apiClient.patch(`/api/staff/reservations/${id}`, { status })
};
