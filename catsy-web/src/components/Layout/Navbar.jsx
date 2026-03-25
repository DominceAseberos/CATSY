import React, { useState } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { Menu, X, LogOut, User, CreditCard, Calendar, Home } from 'lucide-react';
import { useUser } from '../../context/UserContext';

const Navbar = () => {
    const location = useLocation();
    const navigate = useNavigate();
    const activePage = location.pathname === '/' ? 'home' : location.pathname.substring(1);

    const [isMenuOpen, setIsMenuOpen] = useState(false);
    const [showLogoutModal, setShowLogoutModal] = useState(false);
    const { isLoggedIn, userInfo: user, logout } = useUser();

    const toggleMenu = () => setIsMenuOpen(!isMenuOpen);

    const navLinks = isLoggedIn
        ? [
            { id: 'home', label: 'Home', icon: Home },
            { id: 'reservation', label: 'Reservation', icon: Calendar },
            { id: 'profile', label: 'Profile', icon: User },
            { id: 'loyalty', label: 'Loyalty Card', icon: CreditCard },
            { id: 'logout', label: 'Logout', icon: LogOut },
        ]
        : [
            { id: 'home', label: 'Home', icon: Home },
            { id: 'login', label: 'Login', icon: User },
            { id: 'reservation', label: 'Reservation', icon: Calendar },
        ];

    const handleLinkClick = (id) => {
        if (id === 'logout') {
            setShowLogoutModal(true);
        } else {
            navigate(id === 'home' ? '/' : `/${id}`);
        }
        setIsMenuOpen(false);
    };

    const confirmLogout = () => {
        logout();
        setShowLogoutModal(false);
        navigate('/login');
    };

    return (
        <nav className="fixed top-0 w-full bg-white shadow-md z-[1000] font-sans">
            <div className="w-full px-4 sm:px-6 lg:px-8">
                <div className="flex justify-between h-20 items-center">
                    {/* Logo Section */}
                    <div
                        className="flex items-center cursor-pointer"
                        onClick={() => handleLinkClick('home')}
                    >
                        <div className="flex flex-col leading-none select-none">
                            <span className="font-catsy text-2xl tracking-tight text-neutral-900 uppercase">
                                CATSY
                            </span>
                            <span className="font-coffee text-xl font-semibold text-neutral-500 uppercase">
                                COFFEE
                            </span>
                        </div>
                    </div>

                    {/* Desktop Menu */}
                    <div className="hidden md:flex items-center space-y-0 space-x-8">
                        {navLinks.map((link) => (
                            <button
                                key={link.id}
                                onClick={() => handleLinkClick(link.id)}
                                className={`text-lg font-semibold transition-colors duration-200 hover:text-neutral-900 ${activePage === link.id ? 'text-neutral-900 border-b-2 border-neutral-900' : 'text-neutral-500'
                                    }`}
                            >
                                {link.label}
                            </button>
                        ))}
                        {isLoggedIn && (
                            <div className="ml-4 flex items-center bg-neutral-100 px-4 py-2 rounded-full">
                                <span className="text-neutral-700 font-medium">Hi, {user.firstName}</span>
                            </div>
                        )}
                    </div>

                    {/* Mobile Menu Button */}
                    <div className="md:hidden flex items-center">
                        <button
                            onClick={toggleMenu}
                            className="text-neutral-900 focus:outline-none p-2"
                        >
                            {isMenuOpen ? <X size={32} /> : <Menu size={32} />}
                        </button>
                    </div>
                </div>
            </div>

            {/* Mobile Menu Dropdown */}
            {isMenuOpen && (
                <div className="md:hidden bg-white border-t border-neutral-100 animate-in slide-in-from-top duration-300">
                    <div className="px-4 pt-4 pb-6 space-y-2">
                        {navLinks.map((link) => (
                            <button
                                key={link.id}
                                onClick={() => handleLinkClick(link.id)}
                                className={`flex items-center w-full px-4 py-4 text-xl font-bold rounded-lg transition-colors ${activePage === link.id
                                    ? 'bg-neutral-900 text-white'
                                    : 'text-neutral-700 hover:bg-neutral-50'
                                    }`}
                            >
                                <link.icon className="mr-4" size={24} />
                                {link.label}
                            </button>
                        ))}
                    </div>
                </div>
            )}

            {/* Logout Confirmation Modal */}
            {showLogoutModal && (
                <div className="fixed inset-0 z-[10000] bg-black/80 backdrop-blur-sm flex items-center justify-center p-6 animate-fade-in">
                    <div className="bg-neutral-900 border border-white/10 w-full sm:max-w-sm rounded-3xl p-6 shadow-2xl animate-slide-up-fade text-center">
                        <div className="w-16 h-16 bg-red-500/10 rounded-full flex items-center justify-center mx-auto mb-4">
                            <LogOut size={28} className="text-red-500" />
                        </div>
                        <h3 className="text-2xl font-bold text-white mb-2">Sign Out</h3>
                        <p className="text-neutral-400 mb-8">Are you sure you want to end your active session and log out?</p>
                        
                        <div className="flex gap-3">
                            <button
                                onClick={() => setShowLogoutModal(false)}
                                className="flex-1 py-3 px-4 bg-neutral-800 text-white rounded-xl font-bold hover:bg-neutral-700 transition"
                            >
                                Cancel
                            </button>
                            <button
                                onClick={confirmLogout}
                                className="flex-1 py-3 px-4 bg-red-500 text-white rounded-xl font-bold hover:bg-red-600 transition"
                            >
                                Yes, Logout
                            </button>
                        </div>
                    </div>
                </div>
            )}
        </nav>
    );
};

export default Navbar;
