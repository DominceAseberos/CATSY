import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { materialsService } from '../../../services/materialsService';

export function useMaterials(enabled = true) {
    const queryClient = useQueryClient();

    const query = useQuery({
        queryKey: ['admin', 'materials'],
        queryFn: () => materialsService.getAll(),
        enabled,
    });

    const createMutation = useMutation({
        mutationFn: (newMaterial) => materialsService.create(newMaterial),
        onSuccess: () => queryClient.invalidateQueries({ queryKey: ['admin', 'materials'] })
    });

    const updateMutation = useMutation({
        mutationFn: ({ id, data }) => materialsService.update(id, data),
        onSuccess: () => queryClient.invalidateQueries({ queryKey: ['admin', 'materials'] })
    });

    const deleteMutation = useMutation({
        mutationFn: (id) => materialsService.delete(id),
        onSuccess: () => queryClient.invalidateQueries({ queryKey: ['admin', 'materials'] })
    });

    const hasLowStock = (query.data || []).some(
        (m) => m.material_reorder_level != null && m.material_stock <= m.material_reorder_level
    );

    return {
        materials: query.data || [],
        isLoading: query.isLoading,
        error: query.error,
        hasLowStock,
        createMaterial: createMutation.mutateAsync,
        updateMaterial: updateMutation.mutateAsync,
        deleteMaterial: deleteMutation.mutateAsync,
    };
}
