import React, { useEffect, useState } from 'react';
import { TrendingUp, Banknote, Smartphone, BarChart3, RefreshCw } from 'lucide-react';
import { useReports } from '../../../hooks/useReports';
import { Skeleton } from '../../../components/ui/Skeleton';

function MetricCard({ label, value, icon: Icon, color = 'blue' }) {
  const colorMap = {
    blue: 'bg-blue-500/10 text-blue-400',
    green: 'bg-green-500/10 text-green-400',
    purple: 'bg-purple-500/10 text-purple-400',
    orange: 'bg-orange-500/10 text-orange-400',
  };
  return (
    <div className="flex items-center gap-4 p-4 bg-neutral-800/60 border border-neutral-700 rounded-2xl">
      <div className={`w-10 h-10 rounded-xl flex items-center justify-center flex-shrink-0 ${colorMap[color]}`}>
        <Icon className="w-5 h-5" />
      </div>
      <div>
        <p className="text-xs text-neutral-400 uppercase tracking-wider font-medium">{label}</p>
        <p className="text-xl font-bold text-white">{value}</p>
      </div>
    </div>
  );
}

export default function ReportsPage() {
  const { loading, salesData, fetchSales } = useReports();
  const [period, setPeriod] = useState('today');
  const [fromDate, setFromDate] = useState('');
  const [toDate, setToDate] = useState('');

  const load = () => {
    if (period === 'custom' && fromDate && toDate) {
      fetchSales(null, fromDate, toDate);
    } else {
      fetchSales(period);
    }
  };

  useEffect(() => { fetchSales('today'); }, []);

  const fmt = (num) => `₱${(num || 0).toLocaleString('en-PH', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;

  return (
    <div className="animate-in fade-in slide-in-from-bottom-4 duration-500">
      {/* Header */}
      <div className="flex items-center justify-between mb-8">
        <div>
          <h2 className="text-2xl font-bold text-white">Reports & Analytics</h2>
          <p className="text-neutral-400 text-sm mt-1">Sales, payment method breakdown, and daily trends</p>
        </div>
        <button onClick={load} className="flex items-center gap-2 text-sm text-neutral-400 hover:text-white px-4 py-2 rounded-xl border border-neutral-700 hover:border-neutral-500 transition-all">
          <RefreshCw className="w-4 h-4" /> Refresh
        </button>
      </div>

      {/* Filters */}
      <div className="flex flex-wrap gap-3 mb-6 p-4 bg-neutral-800/40 border border-neutral-700 rounded-2xl">
        {['today', 'custom'].map(p => (
          <button
            key={p}
            onClick={() => setPeriod(p)}
            className={`text-sm px-4 py-1.5 rounded-xl font-medium transition-colors capitalize ${period === p ? 'bg-white text-black' : 'text-neutral-400 hover:text-white'}`}
          >
            {p === 'today' ? 'Today' : 'Custom Range'}
          </button>
        ))}
        {period === 'custom' && (
          <div className="flex gap-2 items-center flex-wrap">
            <input type="date" value={fromDate} onChange={e => setFromDate(e.target.value)} className="bg-neutral-800 border border-neutral-700 rounded-xl px-3 py-1.5 text-sm text-white" />
            <span className="text-neutral-500 text-sm">to</span>
            <input type="date" value={toDate} onChange={e => setToDate(e.target.value)} className="bg-neutral-800 border border-neutral-700 rounded-xl px-3 py-1.5 text-sm text-white" />
            <button onClick={load} className="bg-white text-black text-sm px-4 py-1.5 rounded-xl font-medium hover:bg-gray-100 transition-colors">Apply</button>
          </div>
        )}
      </div>

      {/* Metrics */}
      {loading ? (
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
          {[...Array(4)].map((_, i) => <Skeleton key={i} className="h-24 bg-neutral-700 rounded-2xl" />)}
        </div>
      ) : (
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
          <MetricCard label="Total Sales" value={fmt(salesData?.total)} icon={TrendingUp} color="green" />
          <MetricCard label="Cash" value={fmt(salesData?.cash)} icon={Banknote} color="blue" />
          <MetricCard label="GCash" value={fmt(salesData?.gcash)} icon={Smartphone} color="purple" />
          <MetricCard label="Maya" value={fmt(salesData?.maya)} icon={Smartphone} color="orange" />
        </div>
      )}

      {/* Daily Breakdown Table */}
      <div className="bg-neutral-800/60 border border-neutral-700 rounded-2xl overflow-hidden">
        <div className="p-4 border-b border-neutral-700 flex items-center gap-2">
          <BarChart3 className="w-4 h-4 text-neutral-400" />
          <h3 className="text-sm font-semibold text-white">Daily Breakdown</h3>
          <span className="ml-auto text-xs text-neutral-500">{salesData?.total_orders || 0} total orders</span>
        </div>
        {loading ? (
          <div className="p-4 space-y-3">
            {[...Array(5)].map((_, i) => <Skeleton key={i} className="h-10 w-full bg-neutral-700" />)}
          </div>
        ) : !salesData?.daily?.length ? (
          <div className="py-12 text-center text-neutral-500 text-sm">
            No sales data for this period
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-neutral-700 text-neutral-400 text-xs uppercase tracking-wider">
                  <th className="px-4 py-2 text-left font-medium">Date</th>
                  <th className="px-4 py-2 text-right font-medium">Orders</th>
                  <th className="px-4 py-2 text-right font-medium">Total</th>
                  <th className="px-4 py-2 text-right font-medium">Cash</th>
                  <th className="px-4 py-2 text-right font-medium">GCash</th>
                  <th className="px-4 py-2 text-right font-medium">Maya</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-neutral-700/50">
                {salesData.daily.map(row => (
                  <tr key={row.date} className="hover:bg-neutral-700/20 transition-colors">
                    <td className="px-4 py-3 text-white font-medium">{row.date}</td>
                    <td className="px-4 py-3 text-neutral-300 text-right">{row.order_count}</td>
                    <td className="px-4 py-3 text-green-400 text-right font-semibold">{fmt(row.total)}</td>
                    <td className="px-4 py-3 text-neutral-300 text-right">{fmt(row.cash)}</td>
                    <td className="px-4 py-3 text-neutral-300 text-right">{fmt(row.gcash)}</td>
                    <td className="px-4 py-3 text-neutral-300 text-right">{fmt(row.maya)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
}
