import { apiClient } from './apiClient';

export const productService = {
    // Products
    getAllProducts: () => apiClient.get('/products'),
    createProduct: (product) => apiClient.post('/products', product),
    updateProduct: (id, product) => apiClient.put(`/products/${id}`, product),
    deleteProduct: (id) => apiClient.delete(`/products/${id}`),

    // Categories
    getAllCategories: () => apiClient.get('/categories'),
    createCategory: (category) => apiClient.post('/categories', category),
    updateCategory: (id, category) => apiClient.put(`/categories/${id}`, category),
    deleteCategory: (id) => apiClient.delete(`/categories/${id}`)
};
