import React, { useEffect, useState } from 'react';
import { Plus, Trash2, Clock, Users, RefreshCw } from 'lucide-react';
import { useTimeSlots } from '../../../hooks/useTimeSlots';
import { useToast } from '../../../context/ToastContext';
import { EmptyState } from '../../../components/ui/EmptyState';
import { Button } from '../../../components/ui/Button';

const DEFAULT_SLOTS = [
  '08:00 AM', '09:00 AM', '10:00 AM', '11:00 AM',
  '12:00 PM', '01:00 PM', '02:00 PM', '03:00 PM',
  '04:00 PM', '05:00 PM', '06:00 PM', '07:00 PM',
];

export default function TimeSlotsPage() {
  const { slots, loading, fetchSlots, createSlot, deleteSlot } = useTimeSlots();
  const toast = useToast();
  const [newTime, setNewTime] = useState('');
  const [adding, setAdding] = useState(false);
  const [deletingId, setDeletingId] = useState(null);

  useEffect(() => { fetchSlots(); }, []);

  const handleInitDefaults = async () => {
    try {
      setAdding(true);
      for (const t of DEFAULT_SLOTS) {
        try { await createSlot(t); } catch (_) {} // skip if already exists
      }
      toast.success('Default time slots initialized!');
    } finally { setAdding(false); }
  };

  const handleAdd = async () => {
    if (!newTime.trim()) return;
    try {
      setAdding(true);
      await createSlot(newTime.trim());
      setNewTime('');
      toast.success(`Time slot "${newTime}" added.`);
    } catch (err) {
      toast.error(err.message || 'Could not add slot.');
    } finally { setAdding(false); }
  };

  const handleDelete = async (slot) => {
    try {
      setDeletingId(slot.id);
      if (slot.pending_count > 0) {
        // warn but allow
        toast.warning(`Removing slot with ${slot.pending_count} pending reservation(s). Those reservations remain unchanged.`);
      }
      await deleteSlot(slot.id);
      toast.success('Slot removed.');
    } catch (err) {
      toast.error(err.message || 'Could not remove slot.');
    } finally { setDeletingId(null); }
  };

  return (
    <div className="animate-in fade-in slide-in-from-bottom-4 duration-500">
      <div className="flex items-center justify-between mb-8">
        <div>
          <h2 className="text-2xl font-bold text-white">Time Slots</h2>
          <p className="text-neutral-400 text-sm mt-1">Manage bookable time slots for reservations</p>
        </div>
        <button onClick={fetchSlots} className="flex items-center gap-2 text-sm text-neutral-400 hover:text-white px-4 py-2 rounded-xl border border-neutral-700 hover:border-neutral-500 transition-all">
          <RefreshCw className="w-4 h-4" />
        </button>
      </div>

      {/* Add new slot */}
      <div className="flex gap-3 mb-6">
        <input
          type="text"
          placeholder="e.g. 10:00 AM"
          value={newTime}
          onChange={e => setNewTime(e.target.value)}
          onKeyDown={e => e.key === 'Enter' && handleAdd()}
          className="flex-1 bg-neutral-800 border border-neutral-700 rounded-xl px-4 py-2 text-white text-sm placeholder:text-neutral-500 focus:outline-none focus:border-neutral-500"
        />
        <Button onClick={handleAdd} isLoading={adding} icon={Plus} variant="primary">Add Slot</Button>
      </div>

      {/* Slot list */}
      {loading ? (
        <div className="text-neutral-400 text-sm py-12 text-center">Loading slots...</div>
      ) : slots.length === 0 ? (
        <EmptyState
          icon={Clock}
          title="No time slots configured"
          description="No bookable slots are set up yet. Initialize with defaults or add one above."
          action={
            <Button onClick={handleInitDefaults} isLoading={adding} icon={Plus} variant="primary">
              Initialize Default Slots
            </Button>
          }
        />
      ) : (
        <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-3">
          {slots.map(slot => (
            <div key={slot.id} className="flex items-center justify-between bg-neutral-800 border border-neutral-700 rounded-xl px-4 py-3 hover:border-neutral-600 transition-colors group">
              <div>
                <p className="text-sm font-semibold text-white">{slot.time}</p>
                {slot.pending_count > 0 && (
                  <div className="flex items-center gap-1 mt-0.5">
                    <Users className="w-3 h-3 text-blue-400" />
                    <span className="text-xs text-blue-400">{slot.pending_count} pending</span>
                  </div>
                )}
              </div>
              <button
                onClick={() => handleDelete(slot)}
                disabled={deletingId === slot.id}
                className="opacity-0 group-hover:opacity-100 p-1.5 rounded-lg text-neutral-400 hover:text-red-400 hover:bg-red-900/20 transition-all"
              >
                <Trash2 className="w-4 h-4" />
              </button>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
