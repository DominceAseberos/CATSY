import { useQuery } from '@tanstack/react-query';
import { reservationService } from '../services/reservationService';
import { useUser } from '../context/UserContext';
import { useCallback, useState } from 'react';

export function useReservations(selectedDateStr) {
    const { isLoggedIn } = useUser();
    const [submittedReservation, setSubmittedReservation] = useState(null);

    // Fetch ALL reservations to calculate live capacity
    const { data: allReservations = [], isLoading } = useQuery({
        queryKey: ['public', 'reservations'],
        // Fetch without auth interceptor if possible or with safe read token
        queryFn: async () => {
            try {
                return await reservationService.getReservations();
            } catch {
                return [];
            }
        },
    });

    const TOTAL_TABLES = 10; // Can be linked to settings later
    
    // Calculate active tables on selected date
    const activeOnDate = allReservations.filter(r => 
        ['pending', 'confirmed'].includes(r.status) && 
        new Date(r.reservation_time).toISOString().split('T')[0] === selectedDateStr
    ).length;
    
    const availableTables = Math.max(0, TOTAL_TABLES - activeOnDate);

    // Fetch active reservation if logged in
    const fetchActiveReservation = useCallback(async () => {
        if (!isLoggedIn) return;
        try {
            const reservations = await reservationService.getMyReservations();
            const active = reservations.find(r => ['pending', 'confirmed'].includes(r.status));
            setSubmittedReservation(active || null);
        } catch (error) {
            console.error('Error fetching reservations:', error);
        }
    }, [isLoggedIn]);

    return {
        allReservations,
        availableTables,
        TOTAL_TABLES,
        isLoading,
        submittedReservation,
        fetchActiveReservation,
        setSubmittedReservation
    };
}
