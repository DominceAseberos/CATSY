import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { adminService } from '../../../services/adminService';

export function useReservations(enabled = true) {
    const queryClient = useQueryClient();

    const query = useQuery({
        queryKey: ['admin', 'reservations'],
        queryFn: () => adminService.getReservations(),
        enabled,
    });

    const updateStatusMutation = useMutation({
        mutationFn: ({ id, status }) => adminService.updateReservationStatus(id, status),
        onSuccess: () => queryClient.invalidateQueries({ queryKey: ['admin', 'reservations'] })
    });

    return {
        reservations: query.data || [],
        isLoading: query.isLoading,
        error: query.error,
        updateReservationState: (id, status) => updateStatusMutation.mutateAsync({ id, status }),
    };
}
