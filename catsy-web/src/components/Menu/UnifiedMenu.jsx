import React, { useRef } from 'react';
import { useMenu } from '../../hooks/useMenu';
import { useGSAP } from '@gsap/react';
import gsap from 'gsap';
import { ChevronDown, Coffee, AlertCircle } from 'lucide-react';

// ─── Constants ──────────────────────────────────────────────────────────────
// Wide (≥1024px): 3 cols × 6 rows = 18 items
// Mobile (<1024px): 2 cols × 6 rows = 12 items
const COLS_WIDE = 3;
const COLS_MOBILE = 2;
const MAX_ROWS = 6;
const LIMIT_WIDE = COLS_WIDE * MAX_ROWS; // 18
const LIMIT_MOBILE = COLS_MOBILE * MAX_ROWS; // 12

export default function UnifiedMenu() {
    const containerRef = useRef(null);
    const gridRef = useRef(null);

    const {
        categories,
        selectedCategory,
        setSelectedCategory,
        isOpen,
        setIsOpen,
        isLoading,
        isMockData
    } = useMenu();

    const [isExpanded, setIsExpanded] = React.useState(false);

    // Reset expansion when category changes
    React.useEffect(() => {
        setIsExpanded(false);
    }, [selectedCategory]);

    // ── Derived state ──────────────────────────────────────────────────────
    const allItems = selectedCategory?.items ?? [];

    // We need two limits depending on screen width. We use CSS to hide the
    // "overflow" items rather than slicing differently per breakpoint —
    // instead we slice to the larger limit (wide) and hide extras via CSS.
    const visibleItems = isExpanded
        ? allItems
        : allItems.slice(0, LIMIT_WIDE);

    // Show button if there are items beyond the *mobile* limit (the stricter one)
    const hasMoreMobile = allItems.length > LIMIT_MOBILE;
    const hasMoreWide = allItems.length > LIMIT_WIDE;
    const showSeeAll = hasMoreMobile || hasMoreWide;

    // ── Animations ────────────────────────────────────────────────────────
    useGSAP(() => {
        if (isLoading || !containerRef.current) return;
        gsap.from('.bev-header', {
            y: 30,
            opacity: 0,
            duration: 1,
            ease: 'power4.out',
            scrollTrigger: {
                trigger: containerRef.current,
                start: 'top 80%',
            }
        });
    }, { scope: containerRef, dependencies: [isLoading] });

    useGSAP(() => {
        if (!gridRef.current) return;
        const tl = gsap.timeline();
        tl.to('.bev-cell', {
            opacity: 0,
            y: -8,
            stagger: 0.02,
            duration: 0.2,
            ease: 'power2.in',
            onComplete: () => {
                gsap.fromTo('.bev-cell',
                    { opacity: 0, y: 8 },
                    {
                        opacity: 1,
                        y: 0,
                        stagger: 0.03,
                        duration: 0.4,
                        ease: 'power3.out'
                    }
                );
            }
        });
    }, { scope: gridRef, dependencies: [selectedCategory, isExpanded] });

    // ── Loading / no-data states ──────────────────────────────────────────
    if (isLoading) {
        return (
            <section className="py-32 bg-white flex justify-center items-center">
                <div className="animate-spin text-neutral-300"><Coffee size={48} /></div>
            </section>
        );
    }

    if (!selectedCategory || categories.length === 0) return null;

    // ── Render ────────────────────────────────────────────────────────────
    return (
        <section
            ref={containerRef}
            id="beverage-library"
            className="py-24 bg-white overflow-hidden relative"
        >
            <div className="container mx-auto px-6 max-w-5xl">

                {/* ── Header ── */}
                <div className="bev-header mb-12 text-center relative z-10">

                    {/* Title row */}
                    <div className="flex items-center justify-center gap-3 mb-5">
                        <p className="text-neutral-400 text-[10px] font-bold uppercase tracking-[0.4em]">
                            Beverage Library
                        </p>
                        {isMockData && (
                            <span className="inline-flex items-center gap-1 text-[9px] font-bold uppercase tracking-wider bg-amber-50 text-amber-600 border border-amber-200 px-2 py-0.5 rounded-full">
                                <AlertCircle size={10} />
                                Fallback Mock Data Enabled
                            </span>
                        )}
                    </div>

                    {/* Category Dropdown */}
                    <div className="relative inline-block">
                        <button
                            id="bev-category-toggle"
                            onClick={() => setIsOpen(!isOpen)}
                            className="group flex items-center gap-3 bg-neutral-50 hover:bg-neutral-100 border border-neutral-200 px-8 py-4 rounded-full transition-all duration-300"
                        >
                            <Coffee size={16} className="text-amber-600 shrink-0" />
                            <span className="text-lg font-bold text-neutral-900 tracking-tight">
                                {isOpen ? 'Select your Cup' : selectedCategory.name}
                            </span>
                            <ChevronDown
                                size={18}
                                className={`text-neutral-400 transition-transform duration-400 ${isOpen ? 'rotate-180' : ''}`}
                            />
                        </button>

                        {/* Dropdown */}
                        {isOpen && (
                            <div className="absolute top-full left-1/2 -translate-x-1/2 z-50 mt-3 w-64 bg-white shadow-[0_30px_60px_-15px_rgba(0,0,0,0.1)] border border-neutral-100 rounded-[2rem] overflow-hidden py-3 animate-in fade-in slide-in-from-top-4 duration-300">
                                {categories.map((choice) => (
                                    <button
                                        key={choice.category_id}
                                        onClick={() => {
                                            setSelectedCategory(choice);
                                            setIsOpen(false);
                                        }}
                                        className={`w-full flex items-center gap-3 px-6 py-3.5 text-left transition-colors ${selectedCategory.category_id === choice.category_id
                                                ? 'bg-neutral-900 text-white'
                                                : 'text-neutral-600 hover:bg-neutral-50 hover:text-neutral-900'
                                            }`}
                                    >
                                        <Coffee size={15} className="opacity-40 shrink-0" />
                                        <span className="font-semibold tracking-tight text-sm">{choice.name}</span>
                                    </button>
                                ))}
                            </div>
                        )}
                    </div>
                </div>

                {/* ── Matrix Grid ── */}
                <div
                    ref={gridRef}
                    className="
                        grid gap-x-6 gap-y-0
                        grid-cols-2
                        lg:grid-cols-3
                    "
                >
                    {visibleItems.map((item, idx) => {
                        // On mobile, hide items beyond 12 (when not expanded)
                        // On wide, always show up to 18 (already sliced)
                        const hiddenOnMobile = !isExpanded && idx >= LIMIT_MOBILE;

                        return (
                            <div
                                key={item.product_id}
                                className={`bev-cell group flex items-center justify-between border-b border-neutral-100 py-3 cursor-default transition-colors duration-200 hover:bg-neutral-50 px-1 ${hiddenOnMobile ? 'hidden lg:flex' : 'flex'
                                    }`}
                            >
                                {/* Name */}
                                <span className="text-sm font-medium text-neutral-800 truncate flex-1 pr-3 group-hover:text-amber-700 transition-colors duration-200">
                                    {item.product_name}
                                </span>

                                {/* Price */}
                                <span className="text-sm font-bold text-neutral-500 font-mono shrink-0 tabular-nums">
                                    {/* Show price as-is if it already has a symbol, else prefix ₱ */}
                                    {String(item.product_price).match(/^[\$₱€£]/)
                                        ? item.product_price
                                        : `₱${item.product_price}`}
                                </span>
                            </div>
                        );
                    })}
                </div>

                {/* ── See All / Show Less ── */}
                {showSeeAll && (
                    <div className="mt-8 lg:mt-10 flex justify-center">
                        <button
                            id="bev-see-all-btn"
                            onClick={() => setIsExpanded(!isExpanded)}
                            className="inline-flex items-center gap-2 px-7 py-2.5 bg-neutral-50 hover:bg-neutral-100 text-neutral-600 font-bold text-xs uppercase tracking-widest rounded-full border border-neutral-200 transition-all duration-300"
                        >
                            {isExpanded ? 'Show Less' : 'See All'}
                            <ChevronDown
                                size={14}
                                className={`transition-transform duration-300 ${isExpanded ? 'rotate-180' : ''}`}
                            />
                        </button>
                    </div>
                )}

            </div>

            {/* Decorative watermark */}
            <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 pointer-events-none select-none opacity-[0.02] text-[18vw] font-black text-neutral-900 leading-none">
                MENU
            </div>
        </section>
    );
}
