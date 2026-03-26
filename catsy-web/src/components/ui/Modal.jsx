import React, { useEffect, useRef } from 'react';
import { X } from 'lucide-react';
import gsap from 'gsap';

export function Modal({ isOpen, onClose, title, children, maxWidth = 'max-w-md' }) {
  const overlayRef = useRef(null);
  const contentRef = useRef(null);

  useEffect(() => {
    if (isOpen) {
      document.body.style.overflow = 'hidden';
      gsap.to(overlayRef.current, { opacity: 1, duration: 0.2, display: 'flex' });
      gsap.fromTo(contentRef.current, 
        { scale: 0.95, opacity: 0, y: 10 },
        { scale: 1, opacity: 1, y: 0, duration: 0.3, ease: 'back.out(1.5)' }
      );
    } else {
      document.body.style.overflow = 'unset';
      gsap.to(overlayRef.current, { opacity: 0, duration: 0.2, display: 'none' });
    }
    return () => { document.body.style.overflow = 'unset'; };
  }, [isOpen]);

  if (!isOpen) return null;

  return (
    <div ref={overlayRef} className="fixed inset-0 z-[100] hidden items-center justify-center p-4 bg-black/40 backdrop-blur-sm">
      <div 
        ref={contentRef} 
        className={`bg-white w-full rounded-2xl shadow-xl overflow-hidden flex flex-col max-h-[90vh] ${maxWidth}`}
      >
        <div className="flex items-center justify-between p-4 border-b">
          <h2 className="text-lg font-semibold text-gray-900">{title}</h2>
          <button 
            onClick={onClose}
            className="p-2 text-gray-400 hover:text-gray-600 rounded-lg transition-colors"
          >
            <X className="w-5 h-5" />
          </button>
        </div>
        <div className="p-4 overflow-y-auto">
          {children}
        </div>
      </div>
    </div>
  );
}
