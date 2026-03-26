/**
 * @module useSeats
 * @description Custom hook for the Seat Overview domain.
 *
 * Single Responsibility: Fetches the live seat map from `/api/seats`
 * and exposes loading state. Zero UI rendering logic.
 *
 * Open/Closed: Extend with `filterByStatus(status)` or `fetchByZone(zone)`
 * without modifying the existing `fetchSeats` function.
 */
import { useState, useCallback } from 'react';
import { apiClient } from '../services/apiClient';

export function useSeats() {
  const [seatsMap, setSeatsMap] = useState([]);
  const [loading, setLoading] = useState(false);

  const fetchSeats = useCallback(async () => {
    try {
      setLoading(true);
      const res = await apiClient.get('/api/seats');
      setSeatsMap(res.data || []);
      return res.data;
    } finally {
      setLoading(false);
    }
  }, []);

  return {
    seatsMap,
    loading,
    fetchSeats
  };
}
