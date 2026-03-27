import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { userService } from '../../../services/userService';

export function useAccounts(enabled = true) {
    const queryClient = useQueryClient();

    const query = useQuery({
        queryKey: ['admin', 'users'],
        queryFn: () => userService.getUsers(),
        enabled,
    });

    const createMutation = useMutation({
        mutationFn: (newUser) => userService.createUser(newUser),
        onSuccess: () => queryClient.invalidateQueries({ queryKey: ['admin', 'users'] })
    });

    const deleteMutation = useMutation({
        mutationFn: (id) => userService.deleteUser(id),
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
