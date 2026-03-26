/**
 * @module useReports
 * @description Custom hook for the Reports & Analytics domain.
 *
 * Single Responsibility: This hook ONLY manages state and side-effects
 * for report data (sales aggregation, feedback). It does NOT:
 *   - Render any UI elements
 *   - Handle route navigation or toast notifications
 *
 * Open/Closed: To add a new report type (e.g. inventory or staff reports),
 * add a new `fetchX` function and matching state — existing functions
 * are never modified.
 */
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
