import React, { useEffect, useState } from 'react';
import { TrendingUp, ShoppingBag, AlertTriangle, Users, RefreshCw } from 'lucide-react';
import { apiClient } from '../../../services/apiClient';
import { Skeleton } from '../../../components/ui/Skeleton';

function StatCard({ icon: Icon, label, value, subtext, color = "blue", loading }) {
  const colorMap = {
    blue: 'bg-blue-50 text-blue-600 border-blue-100',
    green: 'bg-green-50 text-green-600 border-green-100',
    orange: 'bg-orange-50 text-orange-700 border-orange-100',
    red: 'bg-red-50 text-red-600 border-red-100',
  };

  if (loading) {
    return (
      <div className="p-5 rounded-2xl border border-neutral-700 bg-neutral-800/60">
        <Skeleton className="w-10 h-10 mb-4" variant="circular" />
        <Skeleton className="w-1/2 mb-2 h-3 bg-neutral-700" />
        <Skeleton className="w-1/3 h-6 bg-neutral-700" />
      </div>
    );
  }

  return (
    <div className="flex flex-col p-5 rounded-2xl border border-neutral-700 bg-neutral-800/60 gap-3 hover:border-neutral-600 transition-colors">
      <div className={`w-10 h-10 rounded-xl flex items-center justify-center ${colorMap[color]}`}>
        <Icon className="w-5 h-5" />
      </div>
      <div>
        <p className="text-xs text-neutral-400 font-medium uppercase tracking-wider">{label}</p>
        <p className="text-2xl font-bold text-white mt-0.5">{value ?? '—'}</p>
        {subtext && <p className="text-xs text-neutral-500 mt-1">{subtext}</p>}
      </div>
    </div>
  );
}

export default function DashboardPage() {
  const [stats, setStats] = useState(null);
  const [lowStock, setLowStock] = useState([]);
  const [loading, setLoading] = useState(true);
  const [recentOrders, setRecentOrders] = useState([]);

  const fetchDashboard = async () => {
    try {
      setLoading(true);
      const [salesRes, stockRes, ordersRes] = await Promise.all([
        apiClient.get('/api/admin/reports/sales?period=today'),
        apiClient.get('/api/admin/inventory/low-stock'),
        apiClient.get('/api/staff/orders?limit=5'),
      ]);
      setStats(salesRes?.data);
      setLowStock(stockRes || []);
      setRecentOrders(ordersRes || []);
    } catch (e) {
      console.error('Dashboard fetch error:', e);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchDashboard(); }, []);

  return (
    <div className="animate-in fade-in slide-in-from-bottom-4 duration-500">
      {/* Header */}
      <div className="flex items-center justify-between mb-8">
        <div>
          <h2 className="text-2xl font-bold text-white">Dashboard</h2>
          <p className="text-neutral-400 text-sm mt-1">Today's snapshot — {new Date().toLocaleDateString('en-PH', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' })}</p>
        </div>
        <button onClick={fetchDashboard} className="flex items-center gap-2 text-sm text-neutral-400 hover:text-white px-4 py-2 rounded-xl border border-neutral-700 hover:border-neutral-500 transition-all">
          <RefreshCw className="w-4 h-4" />
          Refresh
        </button>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
        <StatCard
          icon={TrendingUp}
          label="Today's Sales"
          value={stats ? `₱${stats.total?.toLocaleString('en-PH', { minimumFractionDigits: 2 })}` : null}
          subtext={stats ? `${stats.total_orders} orders` : null}
          color="green"
          loading={loading}
        />
        <StatCard
          icon={ShoppingBag}
          label="Cash"
          value={stats ? `₱${stats.cash?.toLocaleString('en-PH', { minimumFractionDigits: 2 })}` : null}
          color="blue"
          loading={loading}
        />
        <StatCard
          icon={ShoppingBag}
          label="GCash / Maya"
          value={stats ? `₱${((stats.gcash || 0) + (stats.maya || 0)).toLocaleString('en-PH', { minimumFractionDigits: 2 })}` : null}
          color="blue"
          loading={loading}
        />
        <StatCard
          icon={AlertTriangle}
          label="Low Stock Items"
          value={loading ? null : lowStock.length}
          subtext={lowStock.length > 0 ? "Requires immediate restocking" : "All materials sufficient"}
          color={lowStock.length > 0 ? "red" : "green"}
          loading={loading}
        />
      </div>

      {/* Recent Orders */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-neutral-800/60 border border-neutral-700 rounded-2xl p-5">
          <h3 className="text-sm font-semibold text-white mb-4 flex items-center gap-2">
            <ShoppingBag className="w-4 h-4 text-blue-400" />
            Recent Orders
          </h3>
          {loading ? (
            <div className="space-y-3">
              {[...Array(4)].map((_, i) => <Skeleton key={i} className="h-10 w-full bg-neutral-700" />)}
            </div>
          ) : recentOrders.length === 0 ? (
            <p className="text-neutral-500 text-sm py-6 text-center">No orders today</p>
          ) : (
            <div className="divide-y divide-neutral-700">
              {recentOrders.map(order => (
                <div key={order.id || order.order_id} className="py-3 flex items-center justify-between">
                  <div>
                    <p className="text-sm text-white font-medium">#{(order.id || order.order_id || '').slice(-6).toUpperCase()}</p>
                    <p className="text-xs text-neutral-400">{order.payment_method || 'Pending payment'}</p>
                  </div>
                  <div className="text-right">
                    <p className="text-sm font-semibold text-white">₱{(order.total_amount || 0).toFixed(2)}</p>
                    <span className={`text-xs px-2 py-0.5 rounded-full font-medium ${
                      order.payment_status === 'paid' ? 'bg-green-900/40 text-green-400' : 'bg-yellow-900/40 text-yellow-400'
                    }`}>{order.payment_status || 'open'}</span>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Low Stock Alerts */}
        <div className="bg-neutral-800/60 border border-neutral-700 rounded-2xl p-5">
          <h3 className="text-sm font-semibold text-white mb-4 flex items-center gap-2">
            <AlertTriangle className="w-4 h-4 text-orange-400" />
            Low Stock Alerts
          </h3>
          {loading ? (
            <div className="space-y-3">
              {[...Array(4)].map((_, i) => <Skeleton key={i} className="h-10 w-full bg-neutral-700" />)}
            </div>
          ) : lowStock.length === 0 ? (
            <p className="text-neutral-500 text-sm py-6 text-center">✅ All materials are sufficiently stocked</p>
          ) : (
            <div className="divide-y divide-neutral-700">
              {lowStock.map(m => (
                <div key={m.material_id} className="py-3 flex items-center justify-between">
                  <div>
                    <p className="text-sm text-white font-medium">{m.material_name}</p>
                    <p className="text-xs text-neutral-400">{m.material_stock} {m.material_unit} remaining</p>
                  </div>
                  <span className="text-xs bg-red-900/40 text-red-400 px-2 py-0.5 rounded-full font-medium">
                    {m.material_stock <= 0 ? 'Out of Stock' : 'Low Stock'}
                  </span>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
