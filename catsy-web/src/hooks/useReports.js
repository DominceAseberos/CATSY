import { useState, useCallback } from 'react';
import { apiClient } from '../services/apiClient';

export function useReports() {
  const [loading, setLoading] = useState(false);
  const [salesData, setSalesData] = useState(null);
  const [feedbackData, setFeedbackData] = useState([]);
  
  const fetchSales = useCallback(async (period = 'today', from_date, to_date) => {
    try {
      setLoading(true);
      let query = `?period=${period}`;
      if (from_date && to_date) {
        query = `?from_date=${from_date}&to_date=${to_date}`;
      }
      const response = await apiClient.get(`/api/admin/reports/sales${query}`);
      setSalesData(response.data);
      return response.data;
    } finally {
      setLoading(false);
    }
  }, []);

  const fetchFeedback = useCallback(async () => {
    try {
      setLoading(true);
      const response = await apiClient.get('/api/admin/reports/feedback');
      setFeedbackData(response.data);
      return response.data;
    } finally {
      setLoading(false);
    }
  }, []);

  return {
    loading,
    salesData,
    feedbackData,
    fetchSales,
    fetchFeedback,
  };
}
