import React, { createContext, useContext, useState, useCallback, useEffect } from 'react';
import { CheckCircle, AlertTriangle, Info, XCircle, X } from 'lucide-react';
import { useGSAP } from '@gsap/react';
import gsap from 'gsap';

const ToastContext = createContext(null);

export function ToastProvider({ children }) {
  const [toasts, setToasts] = useState([]);

  const addToast = useCallback((message, type = 'info', duration = 4000) => {
    const id = crypto.randomUUID();
    setToasts(prev => [...prev, { id, message, type }]);
    
    // Auto remove after duration
    setTimeout(() => {
      setToasts(prev => prev.filter(t => t.id !== id));
    }, duration);
  }, []);

  const toastMethods = {
    success: (msg) => addToast(msg, 'success'),
    error:   (msg) => addToast(msg, 'error'),
    warning: (msg) => addToast(msg, 'warning'),
    info:    (msg) => addToast(msg, 'info'),
  };

  // Register the module-level singleton on mount
  useEffect(() => {
    toast._register(toastMethods);
  }, [addToast]);

  return (
    <ToastContext.Provider value={toastMethods}>
      {children}
      <ToastContainer toasts={toasts} removeToast={(id) => setToasts(prev => prev.filter(t => t.id !== id))} />
    </ToastContext.Provider>
  );
}

export function useToast() {
  const ctx = useContext(ToastContext);
  if (!ctx) throw new Error('useToast must be used inside ToastProvider');
  return ctx;
}

// Module-level singleton for use outside React tree (e.g. apiClient interceptors)
let _toast = null;
export const toast = {
  success: (msg) => _toast?.success(msg),
  error:   (msg) => _toast?.error(msg),
  warning: (msg) => _toast?.warning(msg),
  info:    (msg) => _toast?.info(msg),
  _register: (instance) => { _toast = instance; },
};


function ToastContainer({ toasts, removeToast }) {
  return (
    <div className="fixed top-4 right-4 z-[9999] flex flex-col gap-2 w-full max-w-sm px-4 sm:px-0">
      {toasts.map(t => (
        <ToastItem key={t.id} toast={t} onRemove={() => removeToast(t.id)} />
      ))}
    </div>
  );
}

function ToastItem({ toast, onRemove }) {
  const ICONS = {
    success: <CheckCircle className="w-5 h-5 text-green-500" />,
    error: <XCircle className="w-5 h-5 text-red-500" />,
    warning: <AlertTriangle className="w-5 h-5 text-orange-500" />,
    info: <Info className="w-5 h-5 text-blue-500" />
  };

  const STYLES = {
    success: 'bg-white border text-gray-800 shadow-sm',
    error: 'bg-red-50 text-red-800 border-red-100',
    warning: 'bg-orange-50 text-orange-800 border-orange-100',
    info: 'bg-blue-50 text-blue-800 border-blue-100'
  };

  return (
    <div className={`flex items-start gap-3 p-4 rounded-xl shadow-lg border ${STYLES[toast.type]} animate-in slide-in-from-top-2 fade-in duration-200`}>
      <div className="flex-shrink-0 mt-0.5">{ICONS[toast.type]}</div>
      <p className="flex-1 text-sm font-medium leading-relaxed">{toast.message}</p>
      <button onClick={onRemove} className="flex-shrink-0 p-1 opacity-50 hover:opacity-100 transition-opacity">
        <X className="w-4 h-4" />
      </button>
    </div>
  );
}
