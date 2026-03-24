import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { adminService } from '../../../services/adminService';

export function useAccounts(enabled = true) {
    const queryClient = useQueryClient();

    const query = useQuery({
        queryKey: ['admin', 'users'],
        queryFn: () => adminService.getUsers(),
        enabled,
    });

    const createMutation = useMutation({
        mutationFn: (newUser) => adminService.createUser(newUser),
        onSuccess: () => queryClient.invalidateQueries({ queryKey: ['admin', 'users'] })
    });

    const deleteMutation = useMutation({
        mutationFn: (id) => adminService.deleteUser(id),
        onSuccess: () => queryClient.invalidateQueries({ queryKey: ['admin', 'users'] })
    });

    return {
        users: query.data || [],
        isLoading: query.isLoading,
        error: query.error,
        createUser: createMutation.mutateAsync,
        deleteUser: deleteMutation.mutateAsync,
    };
}
