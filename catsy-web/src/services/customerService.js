import { apiClient } from './apiClient';

export const customerService = {
    login: (username, password) => apiClient.post('/customer/login', { username, password }),

    signup: (userData) => apiClient.post('/customer/signup', userData),

    updateProfile: (customerId, data) => apiClient.put(`/customer/update/${customerId}`, {
        first_name: data.firstName,
        last_name: data.lastName,
        email: data.email,
        contact: data.phone,
        password: data.password
    }),

    getProfile: (customerId) => apiClient.get(`/customer/${customerId}`)
};
