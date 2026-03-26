/**
 * materialsService.js — Service Layer (ISP/SRP)
 * Handles all API calls for raw_materials_inventory and product_recipe.
 * Follows the same pattern as adminService.js.
 */
import { apiClient } from './apiClient';

export const materialsService = {
    // --- Raw Materials CRUD ---
    getAll: () => apiClient.get('/api/admin/materials'),

    create: (data) => apiClient.post('/api/admin/materials', data),

    update: (id, data) => apiClient.put(`/api/admin/materials/${id}`, data),

    delete: (id) => apiClient.delete(`/api/admin/materials/${id}`),

    /** Unit-change guard: returns { in_use: boolean } */
    checkInUse: (id) => apiClient.get(`/api/admin/materials/${id}/in-use`),

    // --- Product Recipes ---
    getRecipe: (productId) => apiClient.get(`/api/admin/materials/products/${productId}/recipe`),

    upsertRecipe: (productId, ingredients) => apiClient.put(`/api/admin/materials/products/${productId}/recipe`, { ingredients }),
};
