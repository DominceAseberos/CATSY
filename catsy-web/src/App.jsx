import React from 'react';
import { Routes, Route, Navigate, useNavigate } from 'react-router-dom';
import MobileShell from './components/Layout/MobileShell';
import ProtectedRoute from './components/ProtectedRoute';
import HomePage from './pages/HomePage';
import LoyaltyPage from './pages/LoyaltyPage';
import ProfilePage from './pages/ProfilePage';
import ReservationPage from './pages/ReservationPage';
import LoginPage from './pages/LoginPage';
import AdminPage from './pages/AdminPage';
import AdminLogin from './pages/admin/components/AdminLogin';
import StatusModal from './components/UI/StatusModal';
import CustomerToast from './components/UI/CustomerToast';
import GlobalCustomerLoading from './components/UI/GlobalCustomerLoading';
import gsap from 'gsap';
import { ScrollTrigger } from 'gsap/ScrollTrigger';
import { useTableAvailability } from './hooks/useTableAvailability';
import { logger } from './utils/logger';
import { UserProvider, useUser } from './context/UserContext';
import { SettingsProvider } from './context/SettingsContext';
import { useRoleGuard } from './hooks/useRoleGuard';
import AdminWarningBanner from './components/UI/AdminWarningBanner';
import ErrorBoundary from './components/UI/ErrorBoundary';

gsap.registerPlugin(ScrollTrigger);

const initialTablesData = { available: 0, total: 0, shopStatus: 'Loading...' };

function AppContent() {
    const { isLoggedIn, userInfo, setUserInfo, login, isDeactivated, confirmDeactivation, authError, isInitialized } = useUser();
    const { isAdmin } = useRoleGuard();
    const dynamicData = useTableAvailability(initialTablesData);
    const navigate = useNavigate();

    logger.log('App Rendered.');

    if (!isInitialized) return null;

    /**
     * Auth error modals — rendered in all routing branches so they always surface
     * regardless of which section the user is in.
     */
    const adminAuthErrorModal = (
        <StatusModal
            isOpen={isDeactivated}
            onClose={confirmDeactivation}
            type="error"
            title={authError?.title || 'Session Expired'}
            message={authError?.message || 'Your session has expired. Please sign in again.'}
            closeLabel="Sign Out"
        />
    );

    const customerAuthErrorModal = (
        <CustomerToast
            isOpen={isDeactivated}
            onClose={confirmDeactivation}
            type="error"
            title={authError?.title || 'Session Expired'}
            message={authError?.message || 'Your session has expired. Please sign in again.'}
            closeLabel="Sign Out"
        />
    );

    return (
        <Routes>
            {/* ── Admin Routes ── */}
            <Route path="/admin/login" element={
                <>
                    <AdminLogin onLoginSuccess={(user) => { login(user); navigate('/admin'); }} />
                    {adminAuthErrorModal}
                </>
            } />

            <Route path="/admin" element={<Navigate to="/admin/products" replace />} />

            <Route path="/admin/:tab" element={
                <ProtectedRoute isAllowed={isLoggedIn && isAdmin} redirectTo="/admin/login">
                    <>
                        <AdminPage />
                        {adminAuthErrorModal}
                    </>
                </ProtectedRoute>
            } />

            {/* ── Customer Routes wrapped in MobileShell ── */}
            <Route path="/*" element={
                <MobileShell>
                    {isAdmin && <AdminWarningBanner />}
                    <GlobalCustomerLoading />
                    <Routes>
                        <Route path="/" element={<HomePage tablesData={dynamicData} />} />
                        <Route path="/loyalty" element={<LoyaltyPage />} />
                        <Route path="/profile" element={
                            <ProtectedRoute isAllowed={isLoggedIn} redirectTo="/login">
                                <ProfilePage userInfo={userInfo || {}} setUserInfo={setUserInfo} />
                            </ProtectedRoute>
                        } />
                        <Route path="/reservation" element={<ReservationPage tablesData={dynamicData} />} />

                        <Route path="/login" element={
                            isAdmin ? <Navigate to="/admin" replace /> :
                            isLoggedIn ? <Navigate to="/profile" replace /> :
                            <LoginPage onLoginSuccess={(user) => { login(user); navigate('/profile'); }} />
                        } />

                        <Route path="/signup" element={
                            isAdmin ? <Navigate to="/admin" replace /> :
                            isLoggedIn ? <Navigate to="/profile" replace /> :
                            <LoginPage initialIsLogin={false} onLoginSuccess={(user) => { login(user); navigate('/profile'); }} />
                        } />

                        <Route path="*" element={<Navigate to="/" replace />} />
                    </Routes>
                    {customerAuthErrorModal}
                </MobileShell>
            } />
        </Routes>
    );
}

export default function App() {
    return (
        <ErrorBoundary>
            <UserProvider>
                <SettingsProvider>
                    <AppContent />
                </SettingsProvider>
            </UserProvider>
        </ErrorBoundary>
    );
}
