import { apiClient } from './apiClient';

export const productService = {
    // Products
    getAllProducts: () => apiClient.get('/products'),
    createProduct: (product) => apiClient.post('/admin/products', product),
    updateProduct: (id, product) => apiClient.put(`/admin/products/${id}`, product),
    deleteProduct: (id) => apiClient.delete(`/admin/products/${id}`),

    // Categories
    getAllCategories: () => apiClient.get('/categories'),
    createCategory: (category) => apiClient.post('/admin/categories', category),
    updateCategory: (id, category) => apiClient.put(`/admin/categories/${id}`, category),
    deleteCategory: (id) => apiClient.delete(`/admin/categories/${id}`)
};
