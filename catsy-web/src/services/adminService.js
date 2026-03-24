import { apiClient } from './apiClient';

export const adminService = {
    login: async (email, password) => {
        return apiClient.post('/admin/login', { email, password });
    },

    getUsers: () => apiClient.get('/admin/users'),

    createUser: (userData) => apiClient.post('/admin/users', userData),

    changePassword: (userId, password) => apiClient.patch(`/admin/users/${userId}/password`, { password }),

    deleteUser: (userId) => apiClient.delete(`/admin/users/${userId}`),

    getProducts: () => apiClient.get('/admin/products'),

    createProduct: (productData) => apiClient.post('/admin/products', productData),

    updateProduct: (productId, productData) => apiClient.put(`/admin/products/${productId}`, productData),

    deleteProduct: (productId) => apiClient.delete(`/admin/products/${productId}`),

    getCategories: () => apiClient.get('/admin/categories'),

    createCategory: (categoryData) => apiClient.post('/admin/categories', categoryData),

    updateCategory: (categoryId, categoryData) => apiClient.put(`/admin/categories/${categoryId}`, categoryData),

    deleteCategory: (categoryId) => apiClient.delete(`/admin/categories/${categoryId}`),

    // Reservations
    getReservations: () => apiClient.get('/api/staff/reservations'),

    updateReservationStatus: (reservationId, status) => apiClient.patch(`/api/staff/reservations/${reservationId}`, { status })
};
