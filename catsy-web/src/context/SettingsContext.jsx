import React, { createContext, useContext, useState, useEffect, useCallback } from 'react';
import { settingsService } from '../services/settingsService';
import { logger } from '../utils/logger';

const SettingsContext = createContext();

export function SettingsProvider({ children }) {
    const [settings, setSettings] = useState(null);
    const [isLoading, setIsLoading] = useState(true);

    const refreshSettings = useCallback(async () => {
        setIsLoading(true);
        try {
            const data = await settingsService.getSettings();
            setSettings(data);
        } catch (error) {
            logger.error('Failed to fetch settings:', error);
        } finally {
            setIsLoading(false);
        }
    }, []);

    useEffect(() => {
        refreshSettings();
    }, [refreshSettings]);

    const updateSettings = async (data) => {
        try {
            const result = await settingsService.updateSettings(data);
            setSettings(prev => ({ ...prev, ...data }));
            return result;
        } catch (error) {
            logger.error('Failed to update settings:', error);
            throw error;
        }
    };

    return (
        <SettingsContext.Provider value={{ settings, isLoading, updateSettings, refreshSettings }}>
            {children}
        </SettingsContext.Provider>
    );
}

export function useSettings() {
    const context = useContext(SettingsContext);
    if (!context) {
        throw new Error('useSettings must be used within a SettingsProvider');
    }
    return context;
}
