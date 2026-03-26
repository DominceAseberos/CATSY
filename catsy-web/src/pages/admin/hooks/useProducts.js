import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { adminService } from '../../../services/adminService';

export function useProducts(enabled = true) {
    const queryClient = useQueryClient();

    const query = useQuery({
        queryKey: ['admin', 'products'],
        queryFn: () => adminService.getProducts(),
        enabled,
    });

    const createMutation = useMutation({
        mutationFn: (newProduct) => adminService.createProduct(newProduct),
        onSuccess: () => queryClient.invalidateQueries({ queryKey: ['admin', 'products'] })
    });

    const updateMutation = useMutation({
        mutationFn: ({ id, data }) => adminService.updateProduct(id, data),
        onSuccess: () => queryClient.invalidateQueries({ queryKey: ['admin', 'products'] })
    });

    const deleteMutation = useMutation({
        mutationFn: (id) => adminService.deleteProduct(id),
        onSuccess: () => queryClient.invalidateQueries({ queryKey: ['admin', 'products'] })
    });

    return {
        products: query.data || [],
        isLoading: query.isLoading,
        error: query.error,
        createProduct: createMutation.mutateAsync,
        updateProduct: updateMutation.mutateAsync,
        deleteProduct: deleteMutation.mutateAsync,
    };
}
