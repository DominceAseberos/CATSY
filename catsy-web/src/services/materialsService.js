/**
 * materialsService.js — Service Layer (ISP/SRP)
 * Handles all API calls for raw_materials_inventory and product_recipe.
 * Follows the same pattern as adminService.js.
 */
import { apiClient } from './apiClient';

export const materialsService = {
    // --- Raw Materials CRUD ---
    getAll: () => apiClient.get('/admin/materials'),

    create: (data) => apiClient.post('/admin/materials', data),

    update: (id, data) => apiClient.put(`/admin/materials/${id}`, data),

    delete: (id) => apiClient.delete(`/admin/materials/${id}`),

    /** Unit-change guard: returns { in_use: boolean } */
    checkInUse: (id) => apiClient.get(`/admin/materials/${id}/in-use`),

    // --- Product Recipes ---
    getRecipe: (productId) => apiClient.get(`/admin/products/${productId}/recipe`),

    upsertRecipe: (productId, ingredients) => apiClient.put(`/admin/products/${productId}/recipe`, { ingredients }),
};
