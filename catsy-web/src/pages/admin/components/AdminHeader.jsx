import { useState } from 'react';
import { NavLink } from 'react-router-dom';
import { Coffee, LayoutGrid, Users, LogOut, FlaskConical, Gift, BookOpen, LayoutDashboard, Armchair, Clock, BarChart3, Megaphone, Download } from 'lucide-react';
import { useUser } from '../../../context/UserContext';
import StatusModal from '../../../components/UI/StatusModal';

export default function AdminHeader({ setIsEditing, setSelectedUser, hasLowStock = false }) {
    const { logout } = useUser();
    const [statusModal, setStatusModal] = useState({ isOpen: false, type: 'info', title: '', message: '', onConfirm: null });

    const handleLogoutClick = () => {
        setStatusModal({
            isOpen: true,
            type: 'error',
            title: 'Sign Out',
            message: 'Are you sure you want to sign out?',
            confirmLabel: 'Sign Out',
            onConfirm: confirmLogout,
            closeLabel: 'Cancel'
        });
    };

    const confirmLogout = () => {
        // Show success state
        setStatusModal({
            isOpen: true,
            type: 'success',
            title: 'Signed Out',
            message: 'You have been successfully signed out.',
            onConfirm: null, // removing onConfirm hides the buttons (if StatusModal handles it, or we can just let it sit there)
            closeLabel: '' // Hide close button text if possible, or we rely on the timeout
        });

        setTimeout(() => {
            logout();
            // Redirect happens automatically via UserContext/App.jsx
        }, 1500);
    };

    return (
        <>
            <header className="mb-12 flex flex-col gap-6">
                <div className="flex justify-between items-center w-full">
                    <h1 className="text-4xl font-black font-display text-white tracking-tight">Backstage Admin</h1>

                    <div className="flex items-center gap-4">
                        <NavLink
                            to="/admin/profile"
                            onClick={() => { setIsEditing(false); setSelectedUser(null); }}
                            className={({ isActive }) => `w-12 h-12 rounded-full border-2 flex items-center justify-center transition-all duration-300 ${isActive ? 'border-brand-accent bg-brand-accent/10 text-brand-accent shadow-[0_0_20px_rgba(255,255,255,0.15)]' : 'border-neutral-700 text-neutral-400 hover:border-neutral-500 hover:text-white'}`}
                            title="My Profile"
                        >
                            <Users size={20} />
                        </NavLink>

                        <div className="w-px h-8 bg-neutral-800 mx-1"></div>

                        <button
                            onClick={handleLogoutClick}
                            className="flex items-center gap-2 px-4 py-3 text-neutral-400 hover:text-white hover:bg-red-500/10 rounded-xl transition-all border border-transparent hover:border-red-500/20 group"
                            title="Logout Admin"
                        >
                            <LogOut size={22} className="group-hover:text-red-500 transition-colors" />
                            <span className="font-bold text-sm group-hover:text-red-500">Sign Out</span>
                        </button>
                    </div>
                </div>

                {/* Navigation Rows */}
                <div className="flex flex-col gap-3">
                    <div className="flex flex-wrap gap-2 bg-neutral-800/40 p-1.5 rounded-2xl border border-neutral-700/50 w-fit">
                        <NavLink
                            to="/admin/products"
                            onClick={() => { setIsEditing(false); setSelectedUser(null); }}
                            className={({ isActive }) => `px-6 py-3 rounded-xl flex items-center gap-2.5 transition-all duration-300 font-bold text-lg ${isActive ? 'bg-neutral-700 text-white shadow-lg' : 'text-neutral-400 hover:text-white'}`}
                        >
                            <Coffee size={20} /> Products
                        </NavLink>
                        <NavLink
                            to="/admin/categories"
                            onClick={() => { setIsEditing(false); setSelectedUser(null); }}
                            className={({ isActive }) => `px-6 py-3 rounded-xl flex items-center gap-2.5 transition-all duration-300 font-bold text-lg ${isActive ? 'bg-neutral-700 text-white shadow-lg' : 'text-neutral-400 hover:text-white'}`}
                        >
                            <LayoutGrid size={20} /> Claimable Rewards
                        </NavLink>
                        <NavLink
                            to="/admin/materials"
                            onClick={() => { setIsEditing(false); setSelectedUser(null); }}
                            className={({ isActive }) => `px-6 py-3 rounded-xl flex items-center gap-2.5 transition-all duration-300 font-bold text-lg ${isActive ? 'bg-neutral-700 text-white shadow-lg' : 'text-neutral-400 hover:text-white'}`}
                        >
                            <FlaskConical size={20} />
                            <span className="relative">
                                Inventory
                                {hasLowStock && (
                                    <span className="absolute -top-1 -right-3 w-2.5 h-2.5 rounded-full bg-amber-400 shadow-[0_0_6px_rgba(251,191,36,0.7)]" />
                                )}
                            </span>
                        </NavLink>
                        <NavLink
                            to="/admin/accounts"
                            onClick={() => { setIsEditing(false); setSelectedUser(null); }}
                            className={({ isActive }) => `px-6 py-3 rounded-xl flex items-center gap-2.5 transition-all duration-300 font-bold text-lg ${isActive ? 'bg-neutral-700 text-white shadow-lg' : 'text-neutral-400 hover:text-white'}`}
                        >
                            <Users size={20} /> Accounts
                        </NavLink>
                        <NavLink
                            to="/admin/reservations"
                            onClick={() => { setIsEditing(false); setSelectedUser(null); }}
                            className={({ isActive }) => `px-6 py-3 rounded-xl flex items-center gap-2.5 transition-all duration-300 font-bold text-lg ${isActive ? 'bg-neutral-700 text-white shadow-lg' : 'text-neutral-400 hover:text-white'}`}
                        >
                            <BookOpen size={20} /> Reservations
                        </NavLink>
                        <NavLink
                            to="/admin/loyalty"
                            onClick={() => { setIsEditing(false); setSelectedUser(null); }}
                            className={({ isActive }) => `px-6 py-3 rounded-xl flex items-center gap-2.5 transition-all duration-300 font-bold text-lg ${isActive ? 'bg-neutral-700 text-white shadow-lg' : 'text-neutral-400 hover:text-white'}`}
                        >
                            <Gift size={20} /> Loyalty
                        </NavLink>
                    </div>

                    <div className="flex flex-wrap gap-2 bg-neutral-800/40 p-1.5 rounded-2xl border border-neutral-700/50 w-fit">
                        <NavLink
                            to="/admin/dashboard"
                            onClick={() => { setIsEditing(false); setSelectedUser(null); }}
                            className={({ isActive }) => `px-4 py-2.5 rounded-xl flex items-center gap-2 transition-all duration-300 font-bold text-base ${isActive ? 'bg-neutral-700 text-white shadow-lg' : 'text-neutral-400 hover:text-white'}`}
                        >
                            <LayoutDashboard size={18} /> Dashboard
                        </NavLink>
                        <NavLink
                            to="/admin/seats"
                            onClick={() => { setIsEditing(false); setSelectedUser(null); }}
                            className={({ isActive }) => `px-4 py-2.5 rounded-xl flex items-center gap-2 transition-all duration-300 font-bold text-base ${isActive ? 'bg-neutral-700 text-white shadow-lg' : 'text-neutral-400 hover:text-white'}`}
                        >
                            <Armchair size={18} /> Seats
                        </NavLink>
                        <NavLink
                            to="/admin/time-slots"
                            onClick={() => { setIsEditing(false); setSelectedUser(null); }}
                            className={({ isActive }) => `px-4 py-2.5 rounded-xl flex items-center gap-2 transition-all duration-300 font-bold text-base ${isActive ? 'bg-neutral-700 text-white shadow-lg' : 'text-neutral-400 hover:text-white'}`}
                        >
                            <Clock size={18} /> Time Slots
                        </NavLink>
                        <NavLink
                            to="/admin/reports"
                            onClick={() => { setIsEditing(false); setSelectedUser(null); }}
                            className={({ isActive }) => `px-4 py-2.5 rounded-xl flex items-center gap-2 transition-all duration-300 font-bold text-base ${isActive ? 'bg-neutral-700 text-white shadow-lg' : 'text-neutral-400 hover:text-white'}`}
                        >
                            <BarChart3 size={18} /> Reports
                        </NavLink>
                        <NavLink
                            to="/admin/cms"
                            onClick={() => { setIsEditing(false); setSelectedUser(null); }}
                            className={({ isActive }) => `px-4 py-2.5 rounded-xl flex items-center gap-2 transition-all duration-300 font-bold text-base ${isActive ? 'bg-neutral-700 text-white shadow-lg' : 'text-neutral-400 hover:text-white'}`}
                        >
                            <Megaphone size={18} /> CMS
                        </NavLink>
                        <NavLink
                            to="/admin/apk"
                            onClick={() => { setIsEditing(false); setSelectedUser(null); }}
                            className={({ isActive }) => `px-4 py-2.5 rounded-xl flex items-center gap-2 transition-all duration-300 font-bold text-base ${isActive ? 'bg-neutral-700 text-white shadow-lg' : 'text-neutral-400 hover:text-white'}`}
                        >
                            <Download size={18} /> APK
                        </NavLink>
                    </div>
                </div>
            </header>

            <StatusModal
                isOpen={statusModal.isOpen}
                onClose={() => setStatusModal({ ...statusModal, isOpen: false })}
                type={statusModal.type}
                title={statusModal.title}
                message={statusModal.message}
                onConfirm={statusModal.onConfirm}
                confirmLabel={statusModal.confirmLabel}
                closeLabel={statusModal.closeLabel}
            />
        </>
    );
}
