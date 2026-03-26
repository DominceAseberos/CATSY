import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { adminService } from '../../../services/adminService';

export function useCategories(enabled = true) {
    const queryClient = useQueryClient();

    const query = useQuery({
        queryKey: ['admin', 'categories'],
        queryFn: () => adminService.getCategories(),
        enabled,
    });

    const createMutation = useMutation({
        mutationFn: (newCategory) => adminService.createCategory(newCategory),
        onSuccess: () => queryClient.invalidateQueries({ queryKey: ['admin', 'categories'] })
    });

    const updateMutation = useMutation({
        mutationFn: ({ id, data }) => adminService.updateCategory(id, data),
        onSuccess: () => queryClient.invalidateQueries({ queryKey: ['admin', 'categories'] })
    });

    const deleteMutation = useMutation({
        mutationFn: (id) => adminService.deleteCategory(id),
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
