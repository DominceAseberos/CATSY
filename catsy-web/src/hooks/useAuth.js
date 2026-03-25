/**
 * useAuth — Thin auth coordinator (SRP-compliant after Fix #3).
 *
 * Responsibilities:
 *   • Drive react-hook-form with Zod validation
 *   • Delegate password strength → usePasswordStrength
 *   • Delegate API calls → customerService
 *   • Delegate session persistence → sessionManager
 */
import { useState, useEffect } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { customerService } from '../services/customerService';
import { mapAuthError } from '../utils/errorHandler';
import { logger } from '../utils/logger';
import { saveSession } from '../utils/sessionManager';
import { authLoginSchema, authSignupSchema } from '../utils/validationSchemas';
import { usePasswordStrength } from './usePasswordStrength';

export function useAuth(onLoginSuccess, initialIsLogin = true) {
    const [isLogin, setIsLogin] = useState(initialIsLogin);
    const [loading, setLoading] = useState(false);
    const [formError, setFormError] = useState('');

    const schema = isLogin ? authLoginSchema : authSignupSchema;

    const {
        register,
        handleSubmit: hookHandleSubmit,
        reset,
        watch,
        formState: { errors, isValid }
    } = useForm({
        resolver: zodResolver(schema),
        mode: 'onChange',
        defaultValues: {
            email: '',
            username: '',
            phone: '',
            password: '',
            confirmPassword: '',
            firstName: '',
            lastName: ''
        }
    });

    // Reset form when switching Login ↔ Signup
    useEffect(() => {
        reset();
        setFormError('');
    }, [isLogin, reset]);

    const watchedPassword = watch('password');

    // Delegated to usePasswordStrength (SRP)
    const passwordStrength = usePasswordStrength(watchedPassword, !isLogin);

    const onSubmit = async (data) => {
        setLoading(true);
        setFormError('');
        try {
            if (isLogin) {
                const response = await customerService.login(data.email, data.password);
                const user = mapUserData({
                    ...response.user,
                    access_token: response.access_token,
                    refresh_token: response.refresh_token
                });
                if (user) {
                    saveSession(user);
                    onLoginSuccess(user);
                }
            } else {
                await customerService.signup({
                    email: data.email,
                    password: data.password,
                    username: data.username,
                    firstName: data.firstName,
                    lastName: data.lastName,
                    phone: data.phone
                });
                onLoginSuccess({
                    isSignupSuccess: true,
                    message: 'Account created! Please check your email for confirmation.'
                });
                setIsLogin(true);
            }
        } catch (err) {
            logger.error('Auth Error:', err);
            const { title, message } = mapAuthError(err, isLogin);
            setFormError(`${title ? title + ': ' : ''}${message}`);
        } finally {
            setLoading(false);
        }
    };

    return {
        isLogin,
        setIsLogin,
        register,
        watch,
        errors,
        handleSubmit: hookHandleSubmit(onSubmit),
        loading,
        formError,
        passwordStrength,
        isPasswordStrong: isLogin || (passwordStrength.score >= 5 && isValid),
    };
}

// ── Data mapping (pure function — no side effects) ───────────────────────────
const mapUserData = (userData) => ({
    id: userData.id,
    email: userData.email,
    username: userData.username || userData.user_name || null,
    firstName: userData.first_name || userData.firstName,
    lastName: userData.last_name || userData.lastName,
    phone: userData.contact || userData.phone,
    accountId: (userData.account_id || userData.accountId)
        ? String(userData.account_id || userData.accountId) : null,
    role: userData.role || 'customer',
    access_token: userData.access_token,
    refresh_token: userData.refresh_token,
    favoriteItem: userData.favoriteItem || null,
    history: userData.history || [],
});
