import { Save, X, Eye, EyeOff, AlertCircle } from 'lucide-react';
import { useState, useEffect } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { productSchema, categorySchema, materialSchema, accountSchema } from '../../../utils/validationSchemas';
import RecipeEditor from './RecipeEditor';

const UNITS = ['grams', 'ml', 'pcs', 'kg', 'liters', 'oz', 'tbsp', 'tsp'];

export default function AdminForm({ activeTab, isEditing, setIsEditing, currentItem, setCurrentItem, categories, materials = [], products = [], handleSave, setProcessingMessage }) {
    // Select schema based on active tab
    const schemas = {
        products: productSchema,
        categories: categorySchema,
        materials: materialSchema,
        accounts: accountSchema
    };

    const schema = schemas[activeTab] || productSchema;

    const {
        register,
        handleSubmit,
        reset,
        formState: { errors },
        watch,
        setValue
    } = useForm({
        resolver: zodResolver(schema),
        defaultValues: currentItem || {}
    });

    // Sync form with currentItem when it changes (e.g. from parent openEdit/openCreate)
    useEffect(() => {
        if (currentItem) {
            reset(currentItem);
        }
    }, [currentItem, reset]);

    const onSubmit = (data) => {
        // Sync local form data back to parent state before triggering parent's handleSave logic
        setCurrentItem(data);
        
        // Trigger the parent's handleSave (which shows confirmation)
        // We mock an event object for compatibility with parent's e.preventDefault()
        handleSave({ preventDefault: () => {} });
    };

    // Local UI states
    const [showPassword, setShowPassword] = useState(false);
    const [confirmPassword, setConfirmPassword] = useState('');

    // Password strength state (for account creation only)
    const [passwordStrength, setPasswordStrength] = useState({
        score: 0,
        label: 'Weak',
        color: 'bg-red-500',
        feedback: []
    });

    // Watch password for strength calculation
    const watchedPassword = watch('password');

    // Calculate password strength in real-time
    useEffect(() => {
        if (activeTab !== 'accounts' || !watchedPassword) {
            setPasswordStrength({ score: 0, label: 'Weak', color: 'bg-red-500', feedback: [] });
            return;
        }

        const p = watchedPassword;
        const requirements = [
            { id: 'length', text: 'Min 8 characters', met: p.length >= 8 },
            { id: 'upper', text: 'Uppercase letter', met: /[A-Z]/.test(p) },
            { id: 'lower', text: 'Lowercase letter', met: /[a-z]/.test(p) },
            { id: 'number', text: 'Number', met: /\d/.test(p) },
            { id: 'special', text: 'Special character', met: /[!@#$%^&*(),.?":{}|<>]/.test(p) }
        ];

        const metCount = requirements.filter(r => r.met).length;
        let score = metCount;
        let label = 'Weak';
        let color = 'bg-red-500';

        if (score > 4) {
            label = 'Strong';
            color = 'bg-green-500';
        } else if (score > 2) {
            label = 'Moderate';
            color = 'bg-yellow-500';
        }

        setPasswordStrength({ score, label, color, feedback: requirements });
    }, [watchedPassword, activeTab]);

    if (!isEditing) return null;

    return (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm">
            <div className="w-full max-w-3xl bg-neutral-800 p-8 md:p-10 rounded-[2.5rem] border border-neutral-700 shadow-2xl max-h-[90vh] overflow-y-auto">
                <div className="flex justify-between items-center mb-8 sticky top-0 bg-neutral-800 z-10 pb-4 border-b border-neutral-700/50">
                    <h2 className="text-3xl font-bold">
                        {currentItem?.id || currentItem?.product_id || currentItem?.category_id || currentItem?.material_id ? 'Edit' : 'Create'} 
                        {activeTab === 'products' ? ' Product' : activeTab === 'categories' ? ' Claimable Reward' : activeTab === 'materials' ? ' Material' : ' Account'}
                    </h2>
                    <button onClick={() => setIsEditing(false)} className="text-neutral-400 hover:text-white transition-colors"><X size={32} /></button>
                </div>

                <form onSubmit={handleSubmit(onSubmit)} className="space-y-8">
                    {activeTab === 'products' ? (
                        <>
                            <div>
                                <label className="block text-lg font-bold text-neutral-400 mb-3 uppercase tracking-wider font-sans">Product Name</label>
                                <input
                                    type="text"
                                    {...register('product_name')}
                                    className={`w-full bg-neutral-900 border ${errors.product_name ? 'border-red-500' : 'border-neutral-700'} rounded-lg px-5 py-4 text-xl focus:outline-none focus:border-green-500 transition-colors font-sans`}
                                />
                                {errors.product_name && <p className="text-red-500 text-sm mt-1 flex items-center gap-1"><AlertCircle size={14} /> {errors.product_name.message}</p>}
                            </div>
                            <div>
                                <label className="block text-lg font-bold text-neutral-400 mb-3 uppercase tracking-wider font-sans">Description</label>
                                <textarea
                                    {...register('product_description')}
                                    className={`w-full bg-neutral-900 border ${errors.product_description ? 'border-red-500' : 'border-neutral-700'} rounded-xl px-5 py-4 text-xl focus:outline-none focus:border-green-500 transition-colors font-sans resize-none`}
                                    rows={3}
                                    placeholder="Brief product description..."
                                />
                                {errors.product_description && <p className="text-red-500 text-sm mt-1 flex items-center gap-1"><AlertCircle size={14} /> {errors.product_description.message}</p>}
                            </div>
                            <div className="grid grid-cols-2 gap-4">
                                <div>
                                    <label className="block text-lg font-bold text-neutral-400 mb-3 uppercase tracking-wider font-sans">Price (₱)</label>
                                    <input
                                        type="number"
                                        step="0.01"
                                        {...register('product_price', { valueAsNumber: true })}
                                        className={`w-full bg-neutral-900 border ${errors.product_price ? 'border-red-500' : 'border-neutral-700'} rounded-xl px-5 py-4 text-xl focus:outline-none focus:border-green-500 transition-colors font-sans`}
                                    />
                                    {errors.product_price && <p className="text-red-500 text-sm mt-1 flex items-center gap-1"><AlertCircle size={14} /> {errors.product_price.message}</p>}
                                </div>
                                <div>
                                    <label className="block text-lg font-bold text-neutral-400 mb-3 uppercase tracking-wider font-sans">Category</label>
                                    <select
                                        {...register('category_id', { valueAsNumber: true })}
                                        className={`w-full bg-neutral-900 border ${errors.category_id ? 'border-red-500' : 'border-neutral-700'} rounded-xl px-5 py-4 text-xl focus:outline-none focus:border-green-500 transition-colors font-sans`}
                                    >
                                        <option value="">Select Category</option>
                                        {categories.map(c => (
                                            <option key={c.category_id} value={c.category_id}>{c.name}</option>
                                        ))}
                                    </select>
                                    {errors.category_id && <p className="text-red-500 text-sm mt-1 flex items-center gap-1"><AlertCircle size={14} /> {errors.category_id.message}</p>}
                                </div>
                            </div>
                            <div className="flex gap-10 py-2">
                                <label className="flex items-center gap-3 cursor-pointer group">
                                    <input type="checkbox" {...register('product_is_available')} className="accent-green-500 w-6 h-6" />
                                    <span className="text-xl text-neutral-300 group-hover:text-white transition-colors font-sans font-bold">Available</span>
                                </label>
                                <label className="flex items-center gap-3 cursor-pointer group">
                                    <input type="checkbox" {...register('product_is_featured')} className="accent-yellow-500 w-6 h-6" />
                                    <span className="text-xl text-neutral-300 group-hover:text-white transition-colors font-sans font-bold">Featured</span>
                                </label>
                                <label className="flex items-center gap-3 cursor-pointer group">
                                    <input type="checkbox" {...register('product_is_eligible')} className="accent-blue-500 w-6 h-6" />
                                    <span className="text-xl text-neutral-300 group-hover:text-white transition-colors font-sans font-bold">+1 Stamp</span>
                                </label>
                                <label className="flex items-center gap-3 cursor-pointer group">
                                    <input type="checkbox" {...register('product_is_reward')} className="accent-purple-500 w-6 h-6" />
                                    <span className="text-xl text-neutral-300 group-hover:text-white transition-colors font-sans font-bold">Claimable Reward</span>
                                </label>
                            </div>
                            {/* Recipe Editor — only for existing products */}
                            {currentItem.product_id ? (
                                <RecipeEditor
                                    productId={currentItem.product_id}
                                    productPrice={currentItem.product_price}
                                    materials={materials}
                                    setProcessingMessage={setProcessingMessage}
                                />
                            ) : (
                                <p className="text-sm text-amber-400/80 bg-amber-500/10 px-4 py-3 rounded-xl border border-amber-500/20">
                                    💡 Save this product first to add a recipe.
                                </p>
                            )}
                        </>
                    ) : activeTab === 'categories' ? (
                        <>
                            <div>
                                <label className="block text-lg font-bold text-neutral-400 mb-3 uppercase tracking-wider font-sans">Reward Name</label>
                                <input
                                    type="text"
                                    {...register('name')}
                                    className={`w-full bg-neutral-900 border ${errors.name ? 'border-red-500' : 'border-neutral-700'} rounded-xl px-5 py-4 text-xl focus:outline-none focus:border-green-500 transition-colors font-sans`}
                                />
                                {errors.name && <p className="text-red-500 text-sm mt-1 flex items-center gap-1"><AlertCircle size={14} /> {errors.name.message}</p>}
                            </div>
                            <div>
                                <label className="block text-lg font-bold text-neutral-400 mb-3 uppercase tracking-wider font-sans">Description</label>
                                <textarea
                                    {...register('description')}
                                    className={`w-full bg-neutral-900 border ${errors.description ? 'border-red-500' : 'border-neutral-700'} rounded-xl px-5 py-4 text-xl focus:outline-none focus:border-green-500 transition-colors resize-none font-sans`}
                                    rows={4}
                                    placeholder="Optional description..."
                                />
                                {errors.description && <p className="text-red-500 text-sm mt-1 flex items-center gap-1"><AlertCircle size={14} /> {errors.description.message}</p>}
                            </div>
                            <div>
                                <label className="block text-lg font-bold text-neutral-400 mb-3 uppercase tracking-wider font-sans">Linked Product (Optional)</label>
                                <select
                                    {...register('linked_product_id', { valueAsNumber: true })}
                                    className="w-full bg-neutral-900 border border-neutral-700 rounded-xl px-5 py-4 text-xl focus:outline-none focus:border-green-500 transition-colors font-sans"
                                >
                                    <option value="">None (Standalone Category/Reward)</option>
                                    {products.map(p => (
                                        <option key={p.product_id} value={p.product_id}>{p.product_name}</option>
                                    ))}
                                </select>
                                <p className="text-sm text-neutral-500 mt-2">Linking a product allows this to be redeemed as a free drink reward.</p>
                            </div>
                        </>
                    ) : activeTab === 'materials' ? (
                        <>
                            <div>
                                <label className="block text-lg font-bold text-neutral-400 mb-3 uppercase tracking-wider font-sans">Material Name</label>
                                <input
                                    type="text"
                                    {...register('material_name')}
                                    className={`w-full bg-neutral-900 border ${errors.material_name ? 'border-red-500' : 'border-neutral-700'} rounded-xl px-5 py-4 text-xl focus:outline-none focus:border-green-500 transition-colors font-sans`}
                                />
                                {errors.material_name && <p className="text-red-500 text-sm mt-1 flex items-center gap-1"><AlertCircle size={14} /> {errors.material_name.message}</p>}
                            </div>
                            <div className="grid grid-cols-2 gap-6">
                                <div>
                                    <label className="block text-lg font-bold text-neutral-400 mb-3 uppercase tracking-wider font-sans">Unit</label>
                                    <select
                                        {...register('material_unit')}
                                        className={`w-full bg-neutral-900 border ${errors.material_unit ? 'border-red-500' : 'border-neutral-700'} rounded-xl px-5 py-4 text-xl focus:outline-none focus:border-green-500 transition-colors font-sans`}
                                    >
                                        {UNITS.map(u => <option key={u} value={u}>{u}</option>)}
                                    </select>
                                    {errors.material_unit && <p className="text-red-500 text-sm mt-1 flex items-center gap-1"><AlertCircle size={14} /> {errors.material_unit.message}</p>}
                                </div>
                                <div>
                                    <label className="block text-lg font-bold text-neutral-400 mb-3 uppercase tracking-wider font-sans">Cost per Unit (₱)</label>
                                    <input
                                        type="number"
                                        step="0.0001"
                                        min="0"
                                        {...register('cost_per_unit', { valueAsNumber: true })}
                                        placeholder="e.g. 0.0500"
                                        className={`w-full bg-neutral-900 border ${errors.cost_per_unit ? 'border-red-500' : 'border-neutral-700'} rounded-xl px-5 py-4 text-xl focus:outline-none focus:border-green-500 transition-colors font-sans`}
                                    />
                                    {errors.cost_per_unit && <p className="text-red-500 text-sm mt-1 flex items-center gap-1"><AlertCircle size={14} /> {errors.cost_per_unit.message}</p>}
                                </div>
                            </div>
                            <div className="grid grid-cols-2 gap-6">
                                <div>
                                    <label className="block text-lg font-bold text-neutral-400 mb-3 uppercase tracking-wider font-sans">Current Stock</label>
                                    <input
                                        type="number"
                                        step="any"
                                        min="0"
                                        {...register('material_stock', { valueAsNumber: true })}
                                        className={`w-full bg-neutral-900 border ${errors.material_stock ? 'border-red-500' : 'border-neutral-700'} rounded-xl px-5 py-4 text-xl focus:outline-none focus:border-green-500 transition-colors font-sans`}
                                    />
                                    {errors.material_stock && <p className="text-red-500 text-sm mt-1 flex items-center gap-1"><AlertCircle size={14} /> {errors.material_stock.message}</p>}
                                </div>
                                <div>
                                    <label className="block text-lg font-bold text-neutral-400 mb-3 uppercase tracking-wider font-sans">Reorder Level <span className="text-neutral-600">(Optional)</span></label>
                                    <input
                                        type="number"
                                        step="any"
                                        min="0"
                                        {...register('material_reorder_level', { valueAsNumber: true })}
                                        placeholder="Alert threshold..."
                                        className={`w-full bg-neutral-900 border ${errors.material_reorder_level ? 'border-red-500' : 'border-neutral-700'} rounded-xl px-5 py-4 text-xl focus:outline-none focus:border-green-500 transition-colors font-sans`}
                                    />
                                    {errors.material_reorder_level && <p className="text-red-500 text-sm mt-1 flex items-center gap-1"><AlertCircle size={14} /> {errors.material_reorder_level.message}</p>}
                                </div>
                            </div>
                        </>
                    ) : (
                        // User Creation Form
                        <>
                            <div className="grid grid-cols-2 gap-6">
                                <div>
                                    <label className="block text-lg font-bold text-neutral-400 mb-3 uppercase tracking-wider font-sans">First Name</label>
                                    <input
                                        type="text"
                                        {...register('first_name')}
                                        className={`w-full bg-neutral-900 border ${errors.first_name ? 'border-red-500' : 'border-neutral-700'} rounded-xl px-5 py-4 text-xl focus:outline-none focus:border-green-500 transition-colors font-sans`}
                                    />
                                    {errors.first_name && <p className="text-red-500 text-sm mt-1 flex items-center gap-1"><AlertCircle size={14} /> {errors.first_name.message}</p>}
                                </div>
                                <div>
                                    <label className="block text-lg font-bold text-neutral-400 mb-3 uppercase tracking-wider font-sans">Last Name</label>
                                    <input
                                        type="text"
                                        {...register('last_name')}
                                        className={`w-full bg-neutral-900 border ${errors.last_name ? 'border-red-500' : 'border-neutral-700'} rounded-xl px-5 py-4 text-xl focus:outline-none focus:border-green-500 transition-colors font-sans`}
                                    />
                                    {errors.last_name && <p className="text-red-500 text-sm mt-1 flex items-center gap-1"><AlertCircle size={14} /> {errors.last_name.message}</p>}
                                </div>
                            </div>
                            <div>
                                <label className="block text-lg font-bold text-neutral-400 mb-3 uppercase tracking-wider font-sans">Email Address</label>
                                <input
                                    type="email"
                                    {...register('email')}
                                    className={`w-full bg-neutral-900 border ${errors.email ? 'border-red-500' : 'border-neutral-700'} rounded-xl px-5 py-4 text-xl focus:outline-none focus:border-green-500 transition-colors font-sans`}
                                />
                                {errors.email && <p className="text-red-500 text-sm mt-1 flex items-center gap-1"><AlertCircle size={14} /> {errors.email.message}</p>}
                            </div>
                            <div>
                                <label className="block text-lg font-bold text-neutral-400 mb-3 uppercase tracking-wider font-sans">QR Code UID <span className="text-neutral-600">(Optional - Auto-generated if empty)</span></label>
                                <input
                                    type="text"
                                    {...register('qr_code')}
                                    className="w-full bg-neutral-900 border border-neutral-700 rounded-xl px-5 py-4 text-xl focus:outline-none focus:border-green-500 transition-colors font-sans font-mono"
                                    placeholder="Auto-generated if empty"
                                />
                            </div>
                            <div className="grid grid-cols-2 gap-6">
                                <div>
                                    <label className="block text-lg font-bold text-neutral-400 mb-3 uppercase tracking-wider font-sans">Contact Number <span className="text-neutral-600">(Optional)</span></label>
                                    <input
                                        type="tel"
                                        {...register('contact')}
                                        className="w-full bg-neutral-900 border border-neutral-700 rounded-xl px-5 py-4 text-xl focus:outline-none focus:border-green-500 transition-colors font-sans"
                                    />
                                </div>
                                <div>
                                    <label className="block text-lg font-bold text-neutral-400 mb-3 uppercase tracking-wider font-sans">Role</label>
                                    <select
                                        {...register('role')}
                                        className="w-full bg-neutral-900 border border-neutral-700 rounded-xl px-5 py-4 text-xl focus:outline-none focus:border-green-500 transition-colors capitalize font-sans"
                                    >
                                        <option value="customer">Customer</option>
                                        <option value="staff">Staff</option>
                                        <option value="admin">Admin</option>
                                    </select>
                                    {errors.role && <p className="text-red-500 text-sm mt-1 flex items-center gap-1"><AlertCircle size={14} /> {errors.role.message}</p>}
                                </div>
                            </div>
                            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                                <div>
                                    <label className="block text-lg font-bold text-neutral-400 mb-3 uppercase tracking-wider font-sans">Password</label>
                                    <div className="relative">
                                        <input
                                            type={showPassword ? "text" : "password"}
                                            {...register('password')}
                                            className={`w-full bg-neutral-900 border ${errors.password ? 'border-red-500' : 'border-neutral-700'} rounded-xl px-5 py-4 text-xl focus:outline-none focus:border-green-500 transition-colors font-sans`}
                                            placeholder="Set initial password..."
                                        />
                                        <button
                                            type="button"
                                            onClick={() => setShowPassword(!showPassword)}
                                            className="absolute right-4 top-1/2 -translate-y-1/2 text-neutral-500 hover:text-white transition-colors"
                                        >
                                            {showPassword ? <EyeOff size={24} /> : <Eye size={24} />}
                                        </button>
                                    </div>
                                    {errors.password && <p className="text-red-500 text-sm mt-1 flex items-center gap-1"><AlertCircle size={14} /> {errors.password.message}</p>}
                                </div>

                                <div>
                                    <label className="block text-lg font-bold text-neutral-400 mb-3 uppercase tracking-wider font-sans">Confirm Password</label>
                                    <div className="relative">
                                        <input
                                            type={showPassword ? "text" : "password"}
                                            value={confirmPassword}
                                            onChange={e => setConfirmPassword(e.target.value)}
                                            className={`w-full bg-neutral-900 border rounded-xl px-5 py-4 text-xl focus:outline-none transition-colors font-sans
                                                ${confirmPassword
                                                    ? (confirmPassword === watch('password') ? 'border-green-500/50 focus:border-green-500' : 'border-red-500/50 focus:border-red-500')
                                                    : 'border-neutral-700 focus:border-green-500'
                                                }`}
                                            placeholder="Repeat password..."
                                        />
                                        {confirmPassword && (
                                            <div className="absolute right-12 top-1/2 -translate-y-1/2">
                                                {confirmPassword === watch('password')
                                                    ? <span className="text-green-500 text-sm font-bold uppercase font-sans">Match</span>
                                                    : <span className="text-red-500 text-sm font-bold uppercase font-sans">Mismatch</span>
                                                }
                                            </div>
                                        )}
                                    </div>
                                    {confirmPassword && confirmPassword !== watch('password') && (
                                        <p className="mt-2 text-base text-red-500 font-sans">Passwords do not match.</p>
                                    )}
                                </div>
                            </div>

                            {/* Full-width Password Strength Indicator */}
                            {watch('password') && (
                                <div className="mt-6 p-6 bg-black/20 rounded-[2rem] border border-neutral-700/50 space-y-4">
                                    <div className="flex justify-between items-center px-1">
                                        <span className={`text-sm font-black uppercase tracking-widest font-sans ${passwordStrength.color.replace('bg-', 'text-')}`}>
                                            Security Level: {passwordStrength.label}
                                        </span>
                                        <span className="text-neutral-500 text-xs font-bold uppercase font-sans">
                                            {passwordStrength.score}/5 Required
                                        </span>
                                    </div>

                                    <div className="h-2 w-full bg-neutral-800 rounded-full overflow-hidden">
                                        <div
                                            className={`h-full transition-all duration-700 ease-out ${passwordStrength.color} shadow-[0_0_10px_rgba(34,197,94,0.3)]`}
                                            style={{ width: `${(passwordStrength.score / 5) * 100}%` }}
                                        />
                                    </div>

                                    <div className="grid grid-cols-2 md:grid-cols-3 gap-y-4 gap-x-6 pt-2">
                                        {passwordStrength.feedback.map(req => (
                                            <div key={req.id} className="flex items-center gap-3 group transition-all">
                                                <div className={`w-3 h-3 rounded-full transition-colors duration-300 ${req.met ? 'bg-green-500 shadow-[0_0_8px_rgba(34,197,94,0.5)]' : 'bg-neutral-700'}`} />
                                                <span className={`text-base font-bold transition-colors duration-300 font-sans ${req.met ? 'text-white' : 'text-neutral-500'}`}>
                                                    {req.text}
                                                </span>
                                            </div>
                                        ))}
                                    </div>
                                </div>
                            )}
                        </>
                    )}

                    <div className="flex justify-end gap-6 mt-12">
                        <button type="button" onClick={() => setIsEditing(false)} className="px-10 py-5 rounded-2xl font-bold text-xl text-neutral-400 hover:bg-neutral-800 transition-colors font-sans">Cancel</button>
                        <button
                            type="submit"
                            disabled={activeTab === 'accounts' && !currentItem.id && (passwordStrength.score < 5 || confirmPassword !== watch('password'))}
                            className={`px-10 py-5 rounded-2xl font-bold text-xl shadow-xl shadow-green-900/20 active:scale-95 transition-all flex items-center gap-3 font-sans
                                ${activeTab === 'accounts' && !currentItem.id && (passwordStrength.score < 5 || confirmPassword !== watch('password'))
                                    ? 'bg-neutral-700 text-neutral-500 cursor-not-allowed opacity-50'
                                    : 'bg-green-600 hover:bg-green-500 text-white'}`}
                        >
                            <Save size={24} /> Save Changes
                        </button>
                    </div>
                </form>
            </div>
        </div>
    );
}
