import React, { useEffect, useState } from 'react';
import { Plus, Pencil, Trash2, ToggleLeft, ToggleRight, RefreshCw, Megaphone, ImageIcon } from 'lucide-react';
import { useCms } from '../../../hooks/useCms';
import { useToast } from '../../../context/ToastContext';
import { EmptyState } from '../../../components/ui/EmptyState';
import { Button } from '../../../components/ui/Button';
import { Modal } from '../../../components/ui/Modal';

const TYPE_LABELS = {
  banner: { label: 'Banner', color: 'bg-blue-900/40 text-blue-400' },
  announcement: { label: 'Announcement', color: 'bg-orange-900/40 text-orange-400' },
  promo: { label: 'Promo', color: 'bg-green-900/40 text-green-400' },
};

const EMPTY_FORM = { type: 'announcement', title: '', body: '', image_url: '', is_active: true };

export default function CmsPage() {
  const { items, loading, fetchAdminItems, createItem, updateItem, deleteItem } = useCms();
  const toast = useToast();
  const [modalOpen, setModalOpen] = useState(false);
  const [form, setForm] = useState(EMPTY_FORM);
  const [editId, setEditId] = useState(null);
  const [saving, setSaving] = useState(false);
  const [deletingId, setDeletingId] = useState(null);

  useEffect(() => { fetchAdminItems(); }, []);

  const openCreate = () => { setForm(EMPTY_FORM); setEditId(null); setModalOpen(true); };
  const openEdit = (item) => { setForm({ type: item.type, title: item.title, body: item.body || '', image_url: item.image_url || '', is_active: item.is_active }); setEditId(item.id); setModalOpen(true); };

  const handleSave = async () => {
    if (!form.title.trim()) { toast.error('Title is required.'); return; }
    try {
      setSaving(true);
      if (editId) {
        await updateItem(editId, form);
        toast.success('Content updated!');
      } else {
        await createItem(form);
        toast.success('Content created!');
      }
      setModalOpen(false);
    } catch (err) {
      toast.error(err.message || 'Could not save content.');
    } finally { setSaving(false); }
  };

  const handleDelete = async (id) => {
    try {
      setDeletingId(id);
      await deleteItem(id);
      toast.success('Content removed.');
    } catch (err) {
      toast.error(err.message);
    } finally { setDeletingId(null); }
  };

  return (
    <div className="animate-in fade-in slide-in-from-bottom-4 duration-500">
      <div className="flex items-center justify-between mb-8">
        <div>
          <h2 className="text-2xl font-bold text-white">Content Management</h2>
          <p className="text-neutral-400 text-sm mt-1">Manage banners, announcements, and promotions</p>
        </div>
        <div className="flex gap-2">
          <button onClick={fetchAdminItems} className="p-2 text-neutral-400 hover:text-white rounded-xl border border-neutral-700 hover:border-neutral-500 transition-all">
            <RefreshCw className="w-4 h-4" />
          </button>
          <Button onClick={openCreate} icon={Plus}>New Content</Button>
        </div>
      </div>

      {loading ? (
        <div className="text-neutral-400 text-sm py-12 text-center">Loading content...</div>
      ) : items.length === 0 ? (
        <EmptyState
          icon={Megaphone}
          title="No content yet"
          description="Add banners, announcements, or promotions visible in the customer portal."
          action={<Button onClick={openCreate} icon={Plus}>Add Content</Button>}
        />
      ) : (
        <div className="grid gap-4">
          {items.map(item => (
            <div key={item.id} className={`flex items-start gap-4 p-4 rounded-2xl border transition-all ${item.is_active ? 'bg-neutral-800/60 border-neutral-700' : 'bg-neutral-900/40 border-neutral-800 opacity-60'}`}>
              {item.image_url ? (
                <img src={item.image_url} alt={item.title} className="w-16 h-16 rounded-xl object-cover flex-shrink-0" />
              ) : (
                <div className="w-16 h-16 rounded-xl bg-neutral-700 flex items-center justify-center flex-shrink-0">
                  <ImageIcon className="w-6 h-6 text-neutral-500" />
                </div>
              )}
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-2 flex-wrap">
                  <span className={`text-xs px-2 py-0.5 rounded-full font-medium ${TYPE_LABELS[item.type]?.color}`}>
                    {TYPE_LABELS[item.type]?.label || item.type}
                  </span>
                  {!item.is_active && <span className="text-xs px-2 py-0.5 rounded-full bg-neutral-700 text-neutral-400">Inactive</span>}
                </div>
                <p className="text-white font-semibold text-sm mt-1">{item.title}</p>
                {item.body && <p className="text-neutral-400 text-xs mt-0.5 line-clamp-2">{item.body}</p>}
              </div>
              <div className="flex gap-2 flex-shrink-0">
                <button onClick={() => openEdit(item)} className="p-2 text-neutral-400 hover:text-white rounded-lg hover:bg-neutral-700 transition-all">
                  <Pencil className="w-4 h-4" />
                </button>
                <button onClick={() => handleDelete(item.id)} disabled={deletingId === item.id} className="p-2 text-neutral-400 hover:text-red-400 rounded-lg hover:bg-red-900/20 transition-all">
                  <Trash2 className="w-4 h-4" />
                </button>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Create/Edit Modal */}
      <Modal isOpen={modalOpen} onClose={() => setModalOpen(false)} title={editId ? 'Edit Content' : 'New Content'}>
        <div className="space-y-4">
          <div>
            <label className="block text-xs font-medium text-gray-600 mb-1">Type</label>
            <select value={form.type} onChange={e => setForm(f => ({ ...f, type: e.target.value }))}
              className="w-full border border-gray-200 rounded-xl px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-gray-200">
              <option value="announcement">Announcement</option>
              <option value="banner">Banner</option>
              <option value="promo">Promo</option>
            </select>
          </div>
          <div>
            <label className="block text-xs font-medium text-gray-600 mb-1">Title *</label>
            <input value={form.title} onChange={e => setForm(f => ({ ...f, title: e.target.value }))}
              placeholder="Enter title..."
              className="w-full border border-gray-200 rounded-xl px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-gray-200" />
          </div>
          <div>
            <label className="block text-xs font-medium text-gray-600 mb-1">Body</label>
            <textarea value={form.body} onChange={e => setForm(f => ({ ...f, body: e.target.value }))}
              placeholder="Enter description..."
              rows={3}
              className="w-full border border-gray-200 rounded-xl px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-gray-200 resize-none" />
          </div>
          <div>
            <label className="block text-xs font-medium text-gray-600 mb-1">Image URL</label>
            <input value={form.image_url} onChange={e => setForm(f => ({ ...f, image_url: e.target.value }))}
              placeholder="https://..."
              className="w-full border border-gray-200 rounded-xl px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-gray-200" />
          </div>
          <div className="flex items-center gap-3">
            <button onClick={() => setForm(f => ({ ...f, is_active: !f.is_active }))}>
              {form.is_active ? <ToggleRight className="w-8 h-8 text-green-500" /> : <ToggleLeft className="w-8 h-8 text-gray-400" />}
            </button>
            <span className="text-sm text-gray-600">{form.is_active ? 'Active — visible in portal' : 'Inactive — hidden from portal'}</span>
          </div>
          <div className="flex justify-end gap-3 pt-2">
            <Button variant="ghost" onClick={() => setModalOpen(false)}>Cancel</Button>
            <Button onClick={handleSave} isLoading={saving}>{editId ? 'Update' : 'Create'}</Button>
          </div>
        </div>
      </Modal>
    </div>
  );
}
