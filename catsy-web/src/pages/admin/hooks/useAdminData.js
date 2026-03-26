import { useCallback } from 'react';
import { useQueryClient } from '@tanstack/react-query';
import { useSSE } from '../../../hooks/useSSE';

import { useProducts } from './useProducts';
import { useCategories } from './useCategories';
import { useAccounts } from './useAccounts';
import { useMaterials } from './useMaterials';
import { useReservations } from './useReservations';

/**
 * useAdminData — Legacy Composition Hook
 * Composes the new specific TanStack Query hooks so AdminPage.jsx 
 * continues to function until it is fully decoupled.
 */
export function useAdminData(isLoggedIn = false) {
    const queryClient = useQueryClient();

    const { products, isLoading: prodLoad, createProduct, updateProduct, deleteProduct } = useProducts(isLoggedIn);
    const { categories, isLoading: catLoad, createCategory, updateCategory, deleteCategory } = useCategories(isLoggedIn);
    const { users, isLoading: usrLoad, createUser, deleteUser } = useAccounts(isLoggedIn);
    const { materials, isLoading: matLoad, hasLowStock, createMaterial, updateMaterial, deleteMaterial } = useMaterials(isLoggedIn);
    const { reservations, isLoading: rsvLoad, updateReservationState } = useReservations(isLoggedIn);

    const isLoading = prodLoad || catLoad || usrLoad || matLoad || rsvLoad;

    // Real-time: auto-refresh on ANY relevant data change from the server
    useSSE({
        'reservation.updated': () => queryClient.invalidateQueries({ queryKey: ['admin', 'reservations'] }),
        'menu.updated': () => {
             queryClient.invalidateQueries({ queryKey: ['admin', 'products'] });
             queryClient.invalidateQueries({ queryKey: ['admin', 'categories'] });
        },
        'inventory.updated': () => queryClient.invalidateQueries({ queryKey: ['admin', 'materials'] }),
    });

    const performSave = async (activeTab, currentItem) => {
        if (activeTab === 'products') {
            if (currentItem.product_id) {
                await updateProduct({ id: currentItem.product_id, data: currentItem });
            } else {
                await createProduct(currentItem);
            }
        } else if (activeTab === 'categories') {
            if (currentItem.category_id) {
                await updateCategory({ id: currentItem.category_id, data: currentItem });
            } else {
                await createCategory(currentItem);
            }
        } else if (activeTab === 'accounts') {
            await createUser(currentItem);
        } else if (activeTab === 'materials') {
            if (currentItem.material_id) {
                await updateMaterial({ id: currentItem.material_id, data: currentItem });
            } else {
                await createMaterial(currentItem);
            }
        }
    };

    const performDelete = async (activeTab, id) => {
        if (activeTab === 'products') {
            await deleteProduct(id);
        } else if (activeTab === 'categories') {
            await deleteCategory(id);
        } else if (activeTab === 'accounts') {
            await deleteUser(id);
        } else if (activeTab === 'materials') {
            await deleteMaterial(id);
        }
    };

    return {
        products,
        categories,
        users,
        materials,
        reservations,
        isLoading,
        hasLowStock,
        refreshData: () => {}, // No-op, managed by react-query cache and SSE
        performSave,
        performDelete,
        updateReservationState,
    };
}
