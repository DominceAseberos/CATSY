import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { productService } from '../../../services/productService';

export function useProducts(enabled = true) {
    const queryClient = useQueryClient();

    const query = useQuery({
        queryKey: ['admin', 'products'],
        queryFn: () => productService.getAllProducts(),
        enabled,
    });

    const createMutation = useMutation({
        mutationFn: (newProduct) => productService.createProduct(newProduct),
        onSuccess: () => queryClient.invalidateQueries({ queryKey: ['admin', 'products'] })
    });

    const updateMutation = useMutation({
        mutationFn: ({ id, data }) => productService.updateProduct(id, data),
        onSuccess: () => queryClient.invalidateQueries({ queryKey: ['admin', 'products'] })
    });

    const deleteMutation = useMutation({
        mutationFn: (id) => productService.deleteProduct(id),
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
