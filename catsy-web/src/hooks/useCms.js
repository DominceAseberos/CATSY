import { useState, useCallback } from 'react';
import { apiClient } from '../services/apiClient';

export function useCms() {
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(false);

  const fetchAdminItems = useCallback(async () => {
    try {
      setLoading(true);
      const res = await apiClient.get('/api/admin/cms');
      setItems(res.data || []);
      return res.data;
    } finally {
      setLoading(false);
    }
  }, []);

  const fetchPublicItems = useCallback(async () => {
    try {
      setLoading(true);
      const res = await apiClient.get('/api/cms/active');
      return res.data || [];
    } finally {
      setLoading(false);
    }
  }, []);

  const createItem = async (payload) => {
    const res = await apiClient.post('/api/admin/cms', payload);
    await fetchAdminItems();
    return res.data;
  };

  const updateItem = async (id, payload) => {
    const res = await apiClient.put(`/api/admin/cms/${id}`, payload);
    await fetchAdminItems();
    return res.data;
  };

  const deleteItem = async (id) => {
    await apiClient.delete(`/api/admin/cms/${id}`);
    await fetchAdminItems();
  };

  return {
    items,
    loading,
    fetchAdminItems,
    fetchPublicItems,
    createItem,
    updateItem,
    deleteItem
  };
}
