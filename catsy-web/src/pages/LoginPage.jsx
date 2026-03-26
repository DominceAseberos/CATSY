import React, { useState, useEffect } from 'react';
import MagneticButton from '../components/UI/MagneticButton';
import CustomerToast from '../components/UI/CustomerToast';
import { User, Lock, ArrowRight, Eye, EyeOff, Phone, UserCircle } from 'lucide-react';
import { useAuth } from '../hooks/useAuth';

export default function LoginPage({ onLoginSuccess, initialIsLogin = true }) {
    // Custom hook manages state, validation, and API calls with robust error handling
    const {
        isLogin,
        setIsLogin,
        register,
        handleSubmit,
        loading,
        formError,
        passwordStrength,
        isPasswordStrong,
        errors,
        watch
    } = useAuth((user) => {
        // Handle signup success
        if (user.isSignupSuccess) {
            setModal({
                isOpen: true,
                type: 'success',
                title: 'Account Created',
                message: user.message || 'Your account has been successfully created. Please log in.'
            });
            return;
        }

        // Block staff/admin accounts — they must use the staff portal
        if (user.role === 'admin' || user.role === 'staff') {
            setModal({
                isOpen: true,
                type: 'error',
                title: 'Wrong Portal',
                message: 'Staff accounts must log in via the staff portal. Please visit /admin to access your dashboard.'
            });
            return; // Don't proceed to customer area
        }

        // Intercept success to show modal first
        setModal({
            isOpen: true,
            type: 'success',
            title: isLogin ? 'Welcome Back!' : 'Account Created',
            message: isLogin 
                ? `Good to see you again, ${user.firstName || user.username || 'Friend'}.` 
                : 'Your account has been successfully created.'
        });

        // Delay navigation to let user see the modal
        setTimeout(() => {
            onLoginSuccess(user);
        }, 800);
    }, initialIsLogin);


    const [showPassword, setShowPassword] = useState(false);

    // Animated loading dots: cycles . → .. → ...
    const [dotCount, setDotCount] = useState(1);
    useEffect(() => {
        if (!loading) { setDotCount(1); return; }
        const interval = setInterval(() => {
            setDotCount(prev => prev >= 3 ? 1 : prev + 1);
        }, 400);
        return () => clearInterval(interval);
    }, [loading]);

    // UI-specific State: Modal for error display
    const [modal, setModal] = useState({
        isOpen: false,
        type: 'success', // 'success' | 'error'
        title: '',
        message: ''
    });

    // Sync hook errors to UI Modal
    useEffect(() => {
        if (formError) {
            setModal({
                isOpen: true,
                type: 'error',
                title: isLogin ? 'Login Failed' : 'Signup Error',
                message: formError
            });
        }
    }, [formError, isLogin]);

    const handleCloseModal = () => {
        setModal(prev => ({ ...prev, isOpen: false }));
    };

    return (
        <div className="flex flex-col items-center justify-center min-h-screen px-6 bg-neutral-900 pt-24 pb-20">
            <div className="w-full max-w-sm bg-white p-8 rounded-[2.5rem] shadow-2xl animate-fade-in border border-white/10">
                <div className="text-center mb-10">
                    <h1 className="text-4xl font-sans font-bold text-neutral-900 tracking-tighter mb-2">
                        {isLogin ? "Welcome Back." : "Join Catsy."}
                    </h1>
                    <p className="text-neutral-500 text-sm">
                        {isLogin ? "Sign in to your private portal." : "Start your coffee journey today."}
                    </p>
                </div>

                <form onSubmit={handleSubmit} className="space-y-4">
                    {!isLogin && (
                        <div className="grid grid-cols-2 gap-4">
                            <div className="space-y-2">
                                <label className="text-xs font-bold uppercase text-neutral-400 tracking-wider ml-4">First Name</label>
                                <div className="flex items-center bg-white p-4 rounded-full border border-neutral-100 focus-within:ring-2 focus-within:ring-brand-accent transition-shadow">
                                    <input
                                        type="text"
                                        {...register('firstName')}
                                        className={`w-full bg-transparent outline-none font-bold text-neutral-900 placeholder:font-normal ${errors.firstName ? 'text-red-500' : ''}`}
                                        placeholder="Jane"
                                    />
                                </div>
                                {errors.firstName && <p className="text-red-500 text-[10px] ml-4 font-bold">{errors.firstName.message}</p>}
                            </div>
                            <div className="space-y-2">
                                <label className="text-xs font-bold uppercase text-neutral-400 tracking-wider ml-4">Last Name</label>
                                <div className="flex items-center bg-white p-4 rounded-full border border-neutral-100 focus-within:ring-2 focus-within:ring-brand-accent transition-shadow">
                                    <input
                                        type="text"
                                        {...register('lastName')}
                                        className={`w-full bg-transparent outline-none font-bold text-neutral-900 placeholder:font-normal ${errors.lastName ? 'text-red-500' : ''}`}
                                        placeholder="Doe"
                                    />
                                </div>
                                {errors.lastName && <p className="text-red-500 text-[10px] ml-4 font-bold">{errors.lastName.message}</p>}
                            </div>

                            {/* New Signup Fields: Username & Phone */}
                            <div className="space-y-2">
                                <label className="text-xs font-bold uppercase text-neutral-400 tracking-wider ml-4">Username</label>
                                <div className="flex items-center bg-white p-4 rounded-full border border-neutral-100 focus-within:ring-2 focus-within:ring-brand-accent transition-shadow">
                                    <UserCircle size={20} className="text-neutral-400 mr-2 shrink-0" />
                                    <input
                                        type="text"
                                        {...register('username')}
                                        className={`w-full bg-transparent outline-none font-bold text-neutral-900 placeholder:font-normal ${errors.username ? 'text-red-500' : ''}`}
                                        placeholder="jane_doe"
                                    />
                                </div>
                                {errors.username && <p className="text-red-500 text-[10px] ml-4 font-bold">{errors.username.message}</p>}
                            </div>
                            <div className="space-y-2">
                                <label className="text-xs font-bold uppercase text-neutral-400 tracking-wider ml-4">Phone</label>
                                <div className="flex items-center bg-white p-4 rounded-full border border-neutral-100 focus-within:ring-2 focus-within:ring-brand-accent transition-shadow">
                                    <Phone size={20} className="text-neutral-400 mr-2 shrink-0" />
                                    <input
                                        type="tel"
                                        {...register('phone')}
                                        className={`w-full bg-transparent outline-none font-bold text-neutral-900 placeholder:font-normal ${errors.phone ? 'text-red-500' : ''}`}
                                        placeholder="0912-345-6789"
                                    />
                                </div>
                                {errors.phone && <p className="text-red-500 text-[10px] ml-4 font-bold">{errors.phone.message}</p>}
                            </div>
                        </div>
                    )}

                    <div className="space-y-2">
                        <label className="text-xs font-bold uppercase text-neutral-400 tracking-wider ml-4">Email / Username</label>
                        <div className="flex items-center bg-white p-4 rounded-full border border-neutral-100 focus-within:ring-2 focus-within:ring-brand-accent transition-shadow">
                            <User size={20} className="text-neutral-400 mr-3 shrink-0" />
                            <input
                                type="text"
                                autoComplete="username"
                                {...register('email')}
                                className={`w-full bg-transparent outline-none font-bold text-neutral-900 placeholder:font-normal ${errors.email ? 'text-red-500' : ''}`}
                                placeholder="name@example.com"
                            />
                        </div>
                        {errors.email && <p className="text-red-500 text-[10px] ml-4 font-bold">{errors.email.message}</p>}
                    </div>

                    <div className="space-y-2">
                        <label className="text-xs font-bold uppercase text-neutral-400 tracking-wider ml-4">Password</label>
                        <div className="flex items-center bg-white p-4 rounded-full border border-neutral-100 focus-within:ring-2 focus-within:ring-brand-accent transition-shadow">
                            <Lock size={20} className="text-neutral-400 mr-3 shrink-0" />
                            <input
                                type={showPassword ? "text" : "password"}
                                autoComplete="current-password"
                                {...register('password')}
                                className={`w-full bg-transparent outline-none font-bold text-neutral-900 placeholder:font-normal ${errors.password ? 'text-red-500' : ''}`}
                                placeholder="• • • • • •"
                            />
                            <button
                                type="button"
                                onClick={() => setShowPassword(!showPassword)}
                                className="text-neutral-400 hover:text-neutral-600 transition-colors ml-2"
                            >
                                {showPassword ? <EyeOff size={20} /> : <Eye size={20} />}
                            </button>
                        </div>
                        {errors.password && <p className="text-red-500 text-[10px] ml-4 font-bold">{errors.password.message}</p>}
                    </div>

                    {/* Password Strength Indicator (Sign-up only) */}
                    {!isLogin && watch('password') && (
                            <div className="px-4 pt-1 space-y-3">
                                {/* Strength Bar */}
                                <div className="h-1 w-full bg-neutral-100 rounded-full overflow-hidden">
                                    <div
                                        className={`h-full transition-all duration-500 ${passwordStrength.color}`}
                                        style={{ width: `${(passwordStrength.score / 5) * 100}%` }}
                                    />
                                </div>

                                {/* Strength Label and Checklist */}
                                <div className="flex justify-between items-center">
                                    <span className={`text-[10px] font-bold uppercase ${passwordStrength.color.replace('bg-', 'text-')}`}>
                                        {passwordStrength.label}
                                    </span>
                                </div>

                                <div className="grid grid-cols-2 gap-x-4 gap-y-1">
                                    {passwordStrength.feedback.map(req => (
                                        <div key={req.id} className="flex items-center gap-1.5">
                                            <div className={`w-1 h-1 rounded-full ${req.met ? 'bg-green-500' : 'bg-neutral-200'}`} />
                                            <span className={`text-[10px] ${req.met ? 'text-neutral-900' : 'text-neutral-400'}`}>
                                                {req.text}
                                            </span>
                                        </div>
                                    ))}
                                </div>
                            </div>
                        )}

                    {!isLogin && (
                        <div className="space-y-2">
                            <label className="text-xs font-bold uppercase text-neutral-400 tracking-wider ml-4">Confirm Password</label>
                            <div className="flex items-center bg-white p-4 rounded-full border border-neutral-100 focus-within:ring-2 focus-within:ring-brand-accent transition-shadow">
                                <Lock size={20} className="text-neutral-400 mr-3 shrink-0" />
                                <input
                                    type={showPassword ? "text" : "password"}
                                    {...register('confirmPassword')}
                                    className={`w-full bg-transparent outline-none font-bold text-neutral-900 placeholder:font-normal ${errors.confirmPassword ? 'text-red-500' : ''}`}
                                    placeholder="Confirm password"
                                />
                            </div>
                            {errors.confirmPassword && <p className="text-red-500 text-[10px] ml-4 font-bold">{errors.confirmPassword.message}</p>}
                        </div>
                    )}

                    <MagneticButton
                        type="submit"
                        disabled={loading || !isPasswordStrong}
                        className={`w-full py-4 rounded-full font-bold text-xl shadow-xl mt-4 relative overflow-hidden group transition-all
                            ${(loading || !isPasswordStrong) ? 'bg-neutral-200 text-neutral-400 cursor-not-allowed' : 'bg-neutral-900 text-white'}
                        `}
                    >
                        <div className="relative z-10 flex items-center justify-center gap-2 w-full h-full">
                            <span>{loading ? `Processing${'.'.repeat(dotCount)}` : (isLogin ? "Login" : "Create Account")}</span>
                            {!loading && <ArrowRight size={20} className="transition-transform group-hover:translate-x-1" />}
                        </div>
                    </MagneticButton>
                </form>

                <div className="mt-12 text-center flex flex-col items-center gap-3">
                    <div className="text-sm text-neutral-500 transition-colors">
                        {isLogin ? "Don't have an account?" : "Already have an account?"}
                        <button
                            onClick={() => { setIsLogin(!isLogin); setModal(prev => ({ ...prev, isOpen: false })); }}
                            className="ml-2 font-bold text-neutral-900 underline hover:text-brand-accent transition-colors cursor-pointer"
                        >
                            {isLogin ? "Sign Up" : "Login"}
                        </button>
                    </div>

                    {isLogin && (
                        <a
                            href="#"
                            className="text-xs text-neutral-500 hover:text-neutral-900 hover:underline transition-all tracking-wide"
                        >
                            Forgot Password?
                        </a>
                    )}
                </div>
            </div>

            {/* Customer-themed notification */}
            <CustomerToast
                isOpen={modal.isOpen}
                onClose={handleCloseModal}
                type={modal.type}
                title={modal.title}
                message={modal.message}
            />
        </div>
    );
}
