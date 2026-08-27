"use client";
import { useState, useEffect, useCallback } from "react";
import { Search, X, SlidersHorizontal } from "lucide-react";
import { PageHeader } from "@/components/layout/PageHeader";
import { FilterChip } from "@/components/ui/FilterChip";
import { ActivityCard } from "@/components/cards/ActivityCard";
import type { Activity, ActivityCategory, ActivityDifficulty, ActivityAgeRange } from "@/types";

const CATEGORIES: { value: ActivityCategory; label: string }[] = [
  { value: "engineering", label: "Engineering" },
  { value: "science", label: "Science" },
  { value: "art", label: "Art" },
  { value: "storytelling", label: "Storytelling" },
  { value: "pretend-play", label: "Pretend Play" },
  { value: "cooperative", label: "Cooperative" },
  { value: "puzzle", label: "Puzzle" },
  { value: "seasonal", label: "Seasonal" },
];

const DIFFICULTIES: { value: ActivityDifficulty; label: string }[] = [
  { value: "easy", label: "Easy" },
  { value: "medium", label: "Medium" },
  { value: "hard", label: "Hard" },
  { value: "adaptive", label: "Adaptive" },
];

const AGE_RANGES: { value: ActivityAgeRange; label: string }[] = [
  { value: "3-5", label: "Ages 3–5" },
  { value: "6-8", label: "Ages 6–8" },
  { value: "9-12", label: "Ages 9–12" },
  { value: "13+", label: "Ages 13+" },
  { value: "family", label: "Family" },
];

const TIME_FILTERS: { value: number; label: string }[] = [
  { value: 15, label: "≤ 15 min" },
  { value: 30, label: "≤ 30 min" },
  { value: 60, label: "≤ 60 min" },
];

export default function ExplorePage() {
  const [activities, setActivities] = useState<Activity[]>([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(true);

  const [search, setSearch] = useState("");
  const [debouncedSearch, setDebouncedSearch] = useState("");
  const [filtersOpen, setFiltersOpen] = useState(false);
  const [category, setCategory] = useState<ActivityCategory | null>(null);
  const [difficulty, setDifficulty] = useState<ActivityDifficulty | null>(null);
  const [ageRange, setAgeRange] = useState<ActivityAgeRange | null>(null);
  const [timeMax, setTimeMax] = useState<number | null>(null);

  // Debounce search input
  useEffect(() => {
    const t = setTimeout(() => setDebouncedSearch(search), 350);
    return () => clearTimeout(t);
  }, [search]);

  const fetchActivities = useCallback(async () => {
    setLoading(true);
    const params = new URLSearchParams({ limit: "100" });
    if (category) params.set("category", category);
    if (difficulty) params.set("difficulty", difficulty);
    if (ageRange) params.set("age_range", ageRange);
    if (timeMax) params.set("time_max", String(timeMax));
    if (debouncedSearch) params.set("search", debouncedSearch);

    try {
      const res = await fetch(`/api/activities?${params}`);
      const json = await res.json();
      setActivities(json.activities ?? []);
      setTotal(json.total ?? 0);
    } finally {
      setLoading(false);
    }
  }, [category, difficulty, ageRange, timeMax, debouncedSearch]);

  useEffect(() => { fetchActivities(); }, [fetchActivities]);

  const hasFilters = !!(category || difficulty || ageRange || timeMax || search);
  const activeFilterCount = [category, difficulty, ageRange, timeMax].filter(Boolean).length;

  function clearFilters() {
    setCategory(null);
    setDifficulty(null);
    setAgeRange(null);
    setTimeMax(null);
    setSearch("");
  }

  return (
    <div className="pb-24">
      <PageHeader
        title="Browse"
        subtitle={`${total} activities to discover`}
      />

      {/* Search + filter control — spec §4.3 */}
      <div className="px-4 mb-4 flex items-center gap-2">
        <div className="relative flex-1">
          <Search size={16} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-walnut-500 pointer-events-none" />
          <input
            type="search"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search activities…"
            className="w-full pl-9 pr-4 py-2.5 rounded-2xl border border-kraft-400 bg-white text-sm font-body text-charcoal-900 placeholder:text-walnut-500 focus:outline-none focus:ring-2 focus:ring-builder-400"
          />
        </div>
        <button
          type="button"
          onClick={() => setFiltersOpen((o) => !o)}
          aria-expanded={filtersOpen}
          className={`flex shrink-0 items-center gap-1.5 rounded-full px-3.5 py-2.5 font-heading text-sm font-medium transition-colors ${
            filtersOpen || hasFilters
              ? "bg-builder-500 text-white"
              : "border border-kraft-400 bg-white text-walnut-700"
          }`}
        >
          <SlidersHorizontal size={15} aria-hidden />
          Filters
          {activeFilterCount > 0 && (
            <span className="tabular rounded-full bg-white/25 px-1.5 text-xs">{activeFilterCount}</span>
          )}
        </button>
      </div>

      {/* Spec §6: the category rows are a secondary filter, not the first
          thing under the header — they stay collapsed until asked for. */}
      <div className={`space-y-2 mb-5 ${filtersOpen ? "" : "hidden"}`}>
        <div className="flex gap-2 overflow-x-auto px-4 pb-1 scrollbar-hide">
          {CATEGORIES.map((c) => (
            <FilterChip
              key={c.value}
              label={c.label}
              active={category === c.value}
              onClick={() => setCategory(category === c.value ? null : c.value)}
            />
          ))}
        </div>
        <div className="flex gap-2 overflow-x-auto px-4 pb-1 scrollbar-hide">
          {DIFFICULTIES.map((d) => (
            <FilterChip
              key={d.value}
              label={d.label}
              active={difficulty === d.value}
              onClick={() => setDifficulty(difficulty === d.value ? null : d.value)}
            />
          ))}
          {TIME_FILTERS.map((t) => (
            <FilterChip
              key={t.value}
              label={t.label}
              active={timeMax === t.value}
              onClick={() => setTimeMax(timeMax === t.value ? null : t.value)}
            />
          ))}
        </div>
        <div className="flex gap-2 overflow-x-auto px-4 pb-1 scrollbar-hide">
          {AGE_RANGES.map((a) => (
            <FilterChip
              key={a.value}
              label={a.label}
              active={ageRange === a.value}
              onClick={() => setAgeRange(ageRange === a.value ? null : a.value)}
            />
          ))}
          {hasFilters && (
            <button
              onClick={clearFilters}
              className="flex items-center gap-1.5 px-3.5 py-1.5 rounded-full text-sm font-heading font-medium whitespace-nowrap bg-cream-200 text-walnut-700 border border-kraft-300 hover:bg-kraft-300 transition-colors flex-shrink-0"
            >
              <X size={13} />
              Clear
            </button>
          )}
        </div>
      </div>

      {/* Grid */}
      <div className="px-4">
        {loading ? (
          <div className="grid grid-cols-2 gap-3">
            {Array.from({ length: 6 }).map((_, i) => (
              <div key={i} className="bg-white rounded-3xl shadow-card h-52 animate-pulse" />
            ))}
          </div>
        ) : activities.length === 0 ? (
          <div className="text-center py-16 text-walnut-500 font-body text-sm">
            No activities match your filters.{" "}
            {hasFilters && (
              <button onClick={clearFilters} className="underline text-builder-500">
                Clear filters
              </button>
            )}
          </div>
        ) : (
          <div className="grid grid-cols-2 gap-3">
            {activities.map((a) => (
              <ActivityCard key={a.id} activity={a} />
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
