import { useState, useMemo } from 'react';
import { processAdminProducts } from '../utils/adminUtils';

/**
 * Custom hook to manage Admin Page selection state and logic.
 */
export const useAdminTabs = (products, categories) => {
    const [selectedCategoryId, setSelectedCategoryId] = useState('all');
    const [sortBy, setSortBy] = useState('name');
    const [sortOrder, setSortOrder] = useState('asc');

    // Memoized processing results
    const sortedAndFilteredProducts = useMemo(() => {
        return processAdminProducts(products, selectedCategoryId, categories, sortBy, sortOrder);
    }, [products, selectedCategoryId, categories, sortBy, sortOrder]);

    const toggleSort = (type) => {
        if (sortBy === type) {
            setSortOrder(prev => (prev === 'asc' ? 'desc' : 'asc'));
        } else {
            setSortBy(type);
            setSortOrder('asc');
        }
    };

    return {
        selectedCategoryId,
        sortBy,
        sortOrder,
        sortedAndFilteredProducts,
        setSelectedCategoryId,
        toggleSort
    };
};
