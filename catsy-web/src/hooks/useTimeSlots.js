import { useState, useCallback } from 'react';
import { apiClient } from '../services/apiClient';

export function useTimeSlots() {
  const [slots, setSlots] = useState([]);
  const [loading, setLoading] = useState(false);

  const fetchSlots = useCallback(async () => {
    try {
      setLoading(true);
      const res = await apiClient.get('/api/admin/time-slots');
      setSlots(res.data || []);
      return res.data;
    } finally {
      setLoading(false);
    }
  }, []);

  const createSlot = async (time) => {
    const res = await apiClient.post('/api/admin/time-slots', { time });
    await fetchSlots();
    return res.data;
  };

  const deleteSlot = async (id) => {
    await apiClient.delete(`/api/admin/time-slots/${id}`);
    await fetchSlots();
  };

  return {
    slots,
    loading,
    fetchSlots,
    createSlot,
    deleteSlot
  };
}
