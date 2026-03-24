import React, { createContext, useContext, useState, useEffect } from 'react';
import { getSession, clearSession } from '../utils/sessionManager';

const UserContext = createContext();

export function UserProvider({ children }) {
    const [userInfo, setUserInfo] = useState(null);
    const [isLoggedIn, setIsLoggedIn] = useState(false);
    const [isInitialized, setIsInitialized] = useState(false);

    useEffect(() => {
        const session = getSession();
        if (session) {
            setUserInfo(session);
            setIsLoggedIn(true);
        }
        setIsInitialized(true);
    }, []);

    const login = (userData) => {
        setUserInfo(userData);
        setIsLoggedIn(true);
    };

    const logout = () => {
        clearSession();
        setUserInfo(null);
        setIsLoggedIn(false);
    };

    const saveSession = (updates) => {
        setUserInfo(prev => {
            const newUser = { ...prev, ...updates };
            // Optional: persistence logic already in sessionManager but we can force it here
            return newUser;
        });
    };

    const confirmDeactivation = () => {
        logout();
    };

    return (
        <UserContext.Provider value={{
            userInfo,
            isLoggedIn,
            isDeactivated: false,
            authError: { title: '', message: '' },
            isInitialized,
            login,
            logout,
            saveSession,
            confirmDeactivation,
            setUserInfo,
            setIsLoggedIn
        }}>
            {children}
        </UserContext.Provider>
    );
}

export function useUser() {
    const context = useContext(UserContext);
    if (!context) {
        throw new Error('useUser must be used within a UserProvider');
    }
    return context;
}
