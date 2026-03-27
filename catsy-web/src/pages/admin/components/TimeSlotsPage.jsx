import React from 'react';
import { Clock, Save, RefreshCw } from 'lucide-react';
import { useSettings } from '../../../context/SettingsContext';
import { useState, useEffect } from 'react';

/**
 * OperatingHoursPage (formerly TimeSlotsPage)
 * Replaces the old time-slot list with a simple Opening / Closing time + seat capacity form.
 * Reads / writes via the SettingsContext which calls PATCH /api/admin/settings.
 */
export default function TimeSlotsPage() {
  const { settings, updateSettings, isLoading } = useSettings();
  const [form, setForm] = useState({ opening_time: '17:00', closing_time: '00:00', total_seats: 10 });
  const [saving, setSaving] = useState(false);
  const [saved, setSaved] = useState(false);

  useEffect(() => {
    if (settings) {
      setForm({
        opening_time: settings.opening_time?.slice(0, 5) ?? '17:00',
        closing_time: settings.closing_time?.slice(0, 5) ?? '00:00',
        total_seats: settings.total_seats ?? 10,
      });
    }
  }, [settings]);

  const handleSave = async () => {
    setSaving(true);
    setSaved(false);
    try {
      await updateSettings(form);
      setSaved(true);
      setTimeout(() => setSaved(false), 3000);
    } catch (err) {
      console.error('Failed to save operating hours', err);
    } finally {
      setSaving(false);
    }
  };

  const fields = [
    { key: 'opening_time', label: 'Opening Time', type: 'time', hint: 'When the restaurant opens (e.g. 17:00)' },
    { key: 'closing_time', label: 'Closing Time', type: 'time', hint: 'When the restaurant closes (e.g. 00:00 = midnight)' },
    { key: 'total_seats', label: 'Total Seat Capacity', type: 'number', hint: 'Maximum number of guests that can be seated' },
  ];

  return (
    <div className="animate-in fade-in slide-in-from-bottom-4 duration-500 max-w-xl">
      <div className="flex items-center justify-between mb-8">
        <div>
          <h2 className="text-2xl font-bold text-white flex items-center gap-3">
            <Clock className="text-brand-accent" size={24} />
            Operating Hours
          </h2>
          <p className="text-neutral-400 text-sm mt-1">
            Configure restaurant opening hours and seating capacity. Changes reflect immediately across the system.
          </p>
        </div>
      </div>

      {isLoading ? (
        <div className="text-neutral-400 text-sm py-12 text-center animate-pulse">Loading settings…</div>
      ) : (
        <div className="bg-neutral-800/40 border border-neutral-700/50 rounded-2xl p-6 space-y-6">
          {fields.map(field => (
            <div key={field.key}>
              <label className="block text-xs font-bold text-neutral-400 uppercase tracking-wider mb-1.5">
                {field.label}
              </label>
              <input
                type={field.type}
                min={field.type === 'number' ? 1 : undefined}
                value={form[field.key] ?? ''}
                onChange={e => setForm(prev => ({
                  ...prev,
                  [field.key]: field.type === 'number' ? parseInt(e.target.value, 10) || 0 : e.target.value,
                }))}
                className="w-full p-3 bg-neutral-900 border border-neutral-700 rounded-xl text-white text-sm outline-none focus:border-brand-accent transition-colors"
              />
              {field.hint && (
                <p className="text-[11px] text-neutral-500 mt-1.5">{field.hint}</p>
              )}
            </div>
          ))}

          <button
            onClick={handleSave}
            disabled={saving}
            className={`w-full flex items-center justify-center gap-2 font-black py-3 rounded-xl transition-all text-sm shadow-lg active:scale-95 disabled:opacity-50 ${
              saved
                ? 'bg-green-500 hover:bg-green-600 text-white shadow-green-500/20'
                : 'bg-white hover:bg-neutral-200 text-neutral-900'
            }`}
          >
            {saving ? (
              <><RefreshCw size={16} className="animate-spin" /> Saving…</>
            ) : saved ? (
              <><Save size={16} /> Saved Successfully!</>
            ) : (
              <><Save size={16} /> Save Operating Hours</>
            )}
          </button>
        </div>
      )}
    </div>
  );
}
