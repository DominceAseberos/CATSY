import React, { createContext, useContext, useState, useCallback } from 'react';
import { AlertTriangle } from 'lucide-react';
import { Modal } from '../components/ui/Modal';
import { Button } from '../components/ui/Button';

const ConfirmContext = createContext(null);

export function ConfirmProvider({ children }) {
  const [dialogState, setDialogState] = useState({
    isOpen: false,
    title: '',
    message: '',
    confirmText: 'Confirm',
    cancelText: 'Cancel',
    onConfirm: () => {},
    onCancel: () => {},
    isDanger: false,
    isLoading: false,
  });

  const confirm = useCallback((options) => {
    return new Promise((resolve, reject) => {
      setDialogState({
        isOpen: true,
        title: options.title || 'Are you sure?',
        message: options.message || 'This action cannot be undone.',
        confirmText: options.confirmText || 'Confirm',
        cancelText: options.cancelText || 'Cancel',
        isDanger: options.isDanger || false,
        onConfirm: async () => {
          setDialogState(prev => ({ ...prev, isLoading: true }));
          try {
            if (options.onConfirm) await options.onConfirm();
            resolve(true);
          } catch (err) {
            reject(err);
          } finally {
            setDialogState(prev => ({ ...prev, isOpen: false, isLoading: false }));
          }
        },
        onCancel: () => {
          setDialogState(prev => ({ ...prev, isOpen: false }));
          resolve(false);
        }
      });
    });
  }, []);

  return (
    <ConfirmContext.Provider value={confirm}>
      {children}
      <Modal isOpen={dialogState.isOpen} onClose={dialogState.onCancel} title={dialogState.title}>
        <div className="flex flex-col gap-4">
          <p className="text-gray-600">{dialogState.message}</p>
          
          {dialogState.isDanger && (
            <div className="flex items-start gap-3 p-3 bg-red-50 text-red-800 rounded-lg text-sm">
              <AlertTriangle className="w-5 h-5 flex-shrink-0" />
              <p>Warning: This action is destructive and cannot be reversed.</p>
            </div>
          )}

          <div className="flex justify-end gap-3 mt-4">
            <Button variant="ghost" onClick={dialogState.onCancel} disabled={dialogState.isLoading}>
              {dialogState.cancelText}
            </Button>
            <Button 
              variant={dialogState.isDanger ? "danger" : "primary"}
              onClick={dialogState.onConfirm}
              isLoading={dialogState.isLoading}
            >
              {dialogState.confirmText}
            </Button>
          </div>
        </div>
      </Modal>
    </ConfirmContext.Provider>
  );
}

export function useConfirm() {
  const ctx = useContext(ConfirmContext);
  if (!ctx) throw new Error('useConfirm must be used within ConfirmProvider');
  return ctx;
}
