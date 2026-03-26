import React from 'react';
import { PackageOpen } from 'lucide-react';

export function EmptyState({ 
  icon: Icon = PackageOpen,
  title = "No data available",
  description = "Get started by creating a new entry.",
  action
}) {
  return (
    <div className="flex flex-col items-center justify-center p-8 text-center min-h-[300px] border-2 border-dashed border-gray-200 rounded-2xl bg-gray-50/50">
      <div className="w-12 h-12 bg-white rounded-full flex items-center justify-center shadow-sm mb-4">
        <Icon className="w-6 h-6 text-gray-400" />
      </div>
      <h3 className="text-lg font-medium text-gray-900 mb-1">{title}</h3>
      <p className="text-sm text-gray-500 max-w-sm mb-6">{description}</p>
      {action && <div>{action}</div>}
    </div>
  );
}
