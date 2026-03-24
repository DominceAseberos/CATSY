/**
 * ProtectedRoute — Centralised auth/role guard (Fix #7 — SRP in App.jsx).
 *
 * Usage:
 *   <ProtectedRoute isAllowed={isLoggedIn && isAdmin} redirectTo="/admin/login">
 *     <AdminPage />
 *   </ProtectedRoute>
 */
import React from 'react';
import { Navigate } from 'react-router-dom';

export default function ProtectedRoute({ isAllowed, redirectTo = '/', children }) {
    if (!isAllowed) {
        return <Navigate to={redirectTo} replace />;
    }
    return children;
}
