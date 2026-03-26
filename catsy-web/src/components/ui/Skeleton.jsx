import React from 'react';

export function Skeleton({ className = "", variant = "rectangular" }) {
  const variants = {
    circular: "rounded-full",
    rectangular: "rounded-lg",
    text: "rounded h-4",
  };

  return (
    <div 
      className={`animate-pulse bg-gray-200 ${variants[variant]} ${className}`}
    />
  );
}

export function SkeletonCard() {
  return (
    <div className="p-6 rounded-2xl border bg-white shadow-sm w-full">
      <Skeleton className="w-12 h-12 mb-4" variant="circular" />
      <Skeleton className="w-1/3 mb-2" variant="text" />
      <Skeleton className="w-full" variant="text" />
      <Skeleton className="w-2/3 mt-2" variant="text" />
    </div>
  );
}
