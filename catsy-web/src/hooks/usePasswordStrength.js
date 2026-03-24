/**
 * usePasswordStrength — Isolated password meter (SRP split from useAuth).
 * Returns score, label, color, and per-requirement feedback.
 */
import { useState, useEffect } from 'react';

const REQUIREMENTS = [
    { id: 'length',  text: 'Min 8 characters',   test: (p) => p.length >= 8 },
    { id: 'upper',   text: 'Uppercase letter',    test: (p) => /[A-Z]/.test(p) },
    { id: 'lower',   text: 'Lowercase letter',    test: (p) => /[a-z]/.test(p) },
    { id: 'number',  text: 'Number',              test: (p) => /\d/.test(p) },
    { id: 'special', text: 'Special character',   test: (p) => /[!@#$%^&*(),.?":{}|<>]/.test(p) },
];

const EMPTY_STRENGTH = { score: 0, label: 'Weak', color: 'bg-red-500', feedback: [] };

export function usePasswordStrength(password, isActive = true) {
    const [strength, setStrength] = useState(EMPTY_STRENGTH);

    useEffect(() => {
        if (!isActive || !password) {
            setStrength(EMPTY_STRENGTH);
            return;
        }

        const feedback = REQUIREMENTS.map((r) => ({ ...r, met: r.test(password) }));
        const score = feedback.filter((r) => r.met).length;

        let label = 'Weak';
        let color = 'bg-red-500';
        if (score > 4) { label = 'Strong';   color = 'bg-green-500'; }
        else if (score > 2) { label = 'Moderate'; color = 'bg-yellow-500'; }

        setStrength({ score, label, color, feedback });
    }, [password, isActive]);

    return strength;
}
