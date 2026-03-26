import React, { useEffect, useState } from 'react';
import { RefreshCw, Users, Coffee, BookOpen } from 'lucide-react';
import { useSeats } from '../../../hooks/useSeats';
import { Skeleton } from '../../../components/ui/Skeleton';

const STATUS_STYLES = {
  available: {
    ring: 'ring-green-500/30',
    bg: 'bg-green-900/20 border-green-700/40 hover:bg-green-900/30',
    dot: 'bg-green-400',
    label: 'Available',
    badge: 'text-green-400',
  },
  occupied: {
    ring: 'ring-red-500/30',
    bg: 'bg-red-900/20 border-red-700/40 hover:bg-red-900/30',
    dot: 'bg-red-400',
    label: 'Occupied',
    badge: 'text-red-400',
  },
  reserved: {
    ring: 'ring-blue-500/30',
    bg: 'bg-blue-900/20 border-blue-700/40 hover:bg-blue-900/30',
    dot: 'bg-blue-400',
    label: 'Reserved',
    badge: 'text-blue-400',
  },
};

function SeatCard({ seat }) {
  const [showTooltip, setShowTooltip] = useState(false);
  const style = STATUS_STYLES[seat.status] || STATUS_STYLES.available;

  return (
    <div
      className={`relative flex flex-col items-center justify-center p-5 rounded-2xl border cursor-pointer ring-2 transition-all duration-200 ${style.bg} ${style.ring}`}
      onMouseEnter={() => setShowTooltip(true)}
      onMouseLeave={() => setShowTooltip(false)}
    >
      <div className={`w-2.5 h-2.5 rounded-full mb-3 ${style.dot}`} />
      <Coffee className="w-6 h-6 text-neutral-400 mb-2" />
      <p className="text-white text-sm font-semibold">Table {seat.seat_number}</p>
      <div className="flex items-center gap-1 mt-1">
        <Users className="w-3 h-3 text-neutral-400" />
        <span className="text-xs text-neutral-400">{seat.capacity}</span>
      </div>
      <span className={`text-xs font-medium mt-2 ${style.badge}`}>{style.label}</span>

      {/* Tooltip / popup */}
      {showTooltip && seat.reservation && (
        <div className="absolute z-10 bottom-full mb-2 left-1/2 -translate-x-1/2 bg-neutral-800 border border-neutral-600 rounded-xl p-3 shadow-xl w-52 text-left">
          <p className="text-white text-xs font-semibold mb-1">{seat.reservation.customer_name || 'Guest'}</p>
          <p className="text-neutral-400 text-xs">🕐 {seat.reservation.time_slot ? new Date(seat.reservation.time_slot).toLocaleTimeString('en-PH', { hour: '2-digit', minute: '2-digit' }) : '—'}</p>
          <p className="text-neutral-400 text-xs">👥 {seat.reservation.guest_count} guest(s)</p>
        </div>
      )}
    </div>
  );
}

export default function SeatOverviewPage() {
  const { seatsMap, loading, fetchSeats } = useSeats();

  useEffect(() => { fetchSeats(); }, []);

  // Auto-refresh every 30 seconds
  useEffect(() => {
    const interval = setInterval(fetchSeats, 30000);
    return () => clearInterval(interval);
  }, [fetchSeats]);

  const counts = seatsMap.reduce((acc, seat) => {
    acc[seat.status] = (acc[seat.status] || 0) + 1;
    return acc;
  }, {});

  return (
    <div className="animate-in fade-in slide-in-from-bottom-4 duration-500">
      <div className="flex items-center justify-between mb-8">
        <div>
          <h2 className="text-2xl font-bold text-white">Seat Overview</h2>
          <p className="text-neutral-400 text-sm mt-1">Live today's reservation map — updates every 30s</p>
        </div>
        <button onClick={fetchSeats} className="flex items-center gap-2 text-sm text-neutral-400 hover:text-white px-4 py-2 rounded-xl border border-neutral-700 hover:border-neutral-500 transition-all">
          <RefreshCw className="w-4 h-4" /> Refresh
        </button>
      </div>

      {/* Legend & Counts */}
      <div className="flex flex-wrap gap-4 mb-6">
        {['available', 'reserved', 'occupied'].map(s => (
          <div key={s} className="flex items-center gap-2 text-sm text-neutral-300">
            <div className={`w-2.5 h-2.5 rounded-full ${STATUS_STYLES[s].dot}`} />
            <span className="capitalize">{s}</span>
            <span className="text-neutral-500">({counts[s] || 0})</span>
          </div>
        ))}
      </div>

      {/* Grid */}
      {loading ? (
        <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-4">
          {[...Array(8)].map((_, i) => (
            <Skeleton key={i} className="h-36 w-full bg-neutral-700 rounded-2xl" />
          ))}
        </div>
      ) : seatsMap.length === 0 ? (
        <div className="text-center py-16 text-neutral-400">
          <Coffee className="w-12 h-12 mx-auto mb-4 opacity-40" />
          <p>No tables/seats configured yet.</p>
        </div>
      ) : (
        <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-4">
          {seatsMap.map(seat => (
            <SeatCard key={seat.id} seat={seat} />
          ))}
        </div>
      )}
    </div>
  );
}
