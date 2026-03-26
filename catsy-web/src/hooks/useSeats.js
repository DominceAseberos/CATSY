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
