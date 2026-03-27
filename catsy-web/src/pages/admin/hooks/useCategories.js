import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { productService } from '../../../services/productService';

export function useCategories(enabled = true) {
    const queryClient = useQueryClient();

    const query = useQuery({
        queryKey: ['admin', 'categories'],
        queryFn: () => productService.getAllCategories(),
        enabled,
    });

    const createMutation = useMutation({
        mutationFn: (newCategory) => productService.createCategory(newCategory),
        onSuccess: () => queryClient.invalidateQueries({ queryKey: ['admin', 'categories'] })
    });

    const updateMutation = useMutation({
        mutationFn: ({ id, data }) => productService.updateCategory(id, data),
        onSuccess: () => queryClient.invalidateQueries({ queryKey: ['admin', 'categories'] })
    });

    const deleteMutation = useMutation({
        mutationFn: (id) => productService.deleteCategory(id),
        onSuccess: () => queryClient.invalidateQueries({ queryKey: ['admin', 'categories'] })
    });

    return {
        categories: query.data || [],
        isLoading: query.isLoading,
        error: query.error,
        createCategory: createMutation.mutateAsync,
        updateCategory: updateMutation.mutateAsync,
        deleteCategory: deleteMutation.mutateAsync,
    };
}
