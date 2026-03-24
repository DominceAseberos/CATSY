import { useState, useEffect } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { customerService } from '../services/customerService';
import { mapAuthError } from '../utils/errorHandler';
import { logger } from '../utils/logger';
import { saveSession } from '../utils/sessionManager';
import { authLoginSchema, authSignupSchema } from '../utils/validationSchemas';

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

    // Reset form when switching between Login and Signup
    useEffect(() => {
        reset();
        setFormError('');
    }, [isLogin, reset]);

    const watchedPassword = watch('password');

    useEffect(() => {
        if (isLogin || !watchedPassword) {
            setPasswordStrength({ score: 0, label: 'Weak', color: 'bg-red-500', feedback: [] });
            return;
        }

        // Logic moved to a utility or kept local for UI feedback
        const p = watchedPassword;
        const requirements = [
            { id: 'length', text: 'Min 8 characters', met: p.length >= 8 },
            { id: 'upper', text: 'Uppercase letter', met: /[A-Z]/.test(p) },
            { id: 'lower', text: 'Lowercase letter', met: /[a-z]/.test(p) },
            { id: 'number', text: 'Number', met: /\d/.test(p) },
            { id: 'special', text: 'Special character', met: /[!@#$%^&*(),.?":{}|<>]/.test(p) }
        ];

        const metCount = requirements.filter(r => r.met).length;
        let score = metCount;
        let label = 'Weak';
        let color = 'bg-red-500';

        if (score > 4) {
            label = 'Strong';
            color = 'bg-green-500';
        } else if (score > 2) {
            label = 'Moderate';
            color = 'bg-yellow-500';
        }

        setPasswordStrength( { score, label, color, feedback: requirements } );
    }, [watchedPassword, isLogin]);

    const onSubmit = async (data) => {
        setLoading(true);
        setFormError('');

        try {
            if (isLogin) {
                // Use the provided 'username' as email for login service
                const response = await customerService.login(data.email, data.password);
                
                // Map the response to our user object structure
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
                // Signup
                const response = await customerService.signup({
                    email: data.email,
                    password: data.password,
                    firstName: data.firstName,
                    lastName: data.lastName,
                    phone: data.phone
                });

                onLoginSuccess({
                    isSignupSuccess: true,
                    message: "Account created! Please check your email for confirmation."
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

    const handleSubmit = hookHandleSubmit(onSubmit);

    return {
        isLogin,
        setIsLogin,
        register,
        watch,
        errors,
        handleSubmit,
        loading,
        formError,
        passwordStrength,
        isPasswordStrong: isLogin || (passwordStrength.score >= 5 && isValid)
    };
}

const mapUserData = (userData) => ({
    id: userData.id,
    email: userData.email,
    firstName: userData.first_name || userData.firstName,
    lastName: userData.last_name || userData.lastName,
    phone: userData.contact || userData.phone,
    accountId: (userData.account_id || userData.accountId) ? String(userData.account_id || userData.accountId) : null,
    role: userData.role || 'customer',
    access_token: userData.access_token,
    refresh_token: userData.refresh_token,
    favoriteItem: userData.favoriteItem || null,
    history: userData.history || []
});
