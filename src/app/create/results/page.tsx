"use client";
import { Suspense, useEffect, useState, useRef } from "react";
import { useSearchParams } from "next/navigation";
import { Clock, Trash2, ChevronDown, ChevronUp } from "lucide-react";
import { AppShell } from "@/components/layout/AppShell";
import { ActivityCard } from "@/components/cards/ActivityCard";
import { FilterChip } from "@/components/ui/FilterChip";
import { EmptyState } from "@/components/ui/EmptyState";
import { MetadataChip } from "@/components/ui/MetadataChip";
import type { ActivityMatch } from "@/app/api/activity-recommendations/route";
import type { AiSuggestion } from "@/lib/ai/suggestions";
import { useAuth } from "@/lib/auth-context";

const FILTERS = ["All", "Quick", "Easy", "Family"] as const;
type Filter = typeof FILTERS[number];

const AI_EMOJIS = ["💡", "🎨", "🔨", "✂️", "🌟"];

function AiSuggestionCard({ suggestion, index }: { suggestion: AiSuggestion; index: number }) {
  const [expanded, setExpanded] = useState(false);
  return (
    <div className="bg-white rounded-3xl shadow-card overflow-hidden">
      <div className="h-28 bg-cream-100 flex items-center justify-center relative">
        <span className="text-4xl">{AI_EMOJIS[index % AI_EMOJIS.length]}</span>
        <span className="absolute top-3 right-3 px-2.5 py-1 rounded-full text-xs font-heading font-semibold bg-builder-500/15 text-builder-700">
          AI Idea
        </span>
      </div>
      <div className="p-4">
        <h3 className="font-heading font-semibold text-base text-charcoal-900 mb-1">{suggestion.title}</h3>
        <p className="text-xs text-walnut-600 mb-2 line-clamp-2">{suggestion.description}</p>
        <div className="flex flex-wrap gap-1.5 mb-3">
          <MetadataChip icon={<Clock size={11} />} label={`${suggestion.timeMinutes} min`} />
          <MetadataChip icon={<Trash2 size={11} />} label={suggestion.cleanupLevel + " mess"} />
        </div>
        <button
          onClick={() => setExpanded(!expanded)}
          className="flex items-center gap-1 text-xs text-builder-600 font-body font-medium"
        >
          {expanded ? <><ChevronUp size={12} /> Hide steps</> : <><ChevronDown size={12} /> Show steps</>}
        </button>
        {expanded && (
          <ol className="mt-2 space-y-1.5 list-none">
            {suggestion.steps.map((step, i) => (
              <li key={i} className="text-xs text-charcoal-800">
                <span className="font-semibold text-builder-600">{i + 1}.</span> {step}
              </li>
            ))}
          </ol>
        )}
      </div>
    </div>
  );
}

function ResultsContent() {
  const searchParams = useSearchParams();
  const selectedIds = searchParams.getAll("materials");
  const childAge = Math.max(3, Math.min(18, parseInt(searchParams.get("age") ?? "7", 10)));
  const { session } = useAuth();

  const [activeFilter, setActiveFilter] = useState<Filter>("All");
  const [matches, setMatches] = useState<ActivityMatch[]>([]);
  const [aiSuggestions, setAiSuggestions] = useState<AiSuggestion[]>([]);
  const [loading, setLoading] = useState(() => selectedIds.length > 0);
  const [error, setError] = useState<string | null>(null);
  const [limitReached, setLimitReached] = useState(false);
  const loadedFor = useRef<string>("");

  useEffect(() => {
    const key = `${selectedIds.join(",")}:age${childAge}`;
    if (!selectedIds.length || loadedFor.current === key) return;
    loadedFor.current = key;

    let cancelled = false;
    setLoading(true);
    setError(null);
    setLimitReached(false);

    async function load() {
      const res = await fetch('/api/activity-recommendations', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          ...(session ? { Authorization: `Bearer ${session.access_token}` } : {}),
        },
        body: JSON.stringify({
          materialIds: selectedIds,
          childAge,
          requestId: `${key}:${session?.user.id ?? "guest"}`,
        }),
      });
      if (res.status === 429) {
        if (!cancelled) setLimitReached(true);
        return;
      }
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      const data: { matches: ActivityMatch[]; aiSuggestions: AiSuggestion[] } = await res.json();
      if (!cancelled) {
        setMatches(data.matches ?? []);
        setAiSuggestions(data.aiSuggestions ?? []);
      }
    }

    load()
      .catch(e => { if (!cancelled) setError(e instanceof Error ? e.message : 'Something went wrong') })
      .finally(() => { if (!cancelled) setLoading(false) });

    return () => { cancelled = true; };
  }, [selectedIds.join(","), childAge, session]); // eslint-disable-line react-hooks/exhaustive-deps

  const filtered = matches.filter(({ activity }) => {
    if (activeFilter === "Quick") return activity.time_minutes <= 20;
    if (activeFilter === "Easy") return activity.difficulty === "easy";
    if (activeFilter === "Family") return activity.age_ranges.includes("family");
    return true;
  });

  const hasAnything = filtered.length > 0 || aiSuggestions.length > 0;

  return (
    <div className="max-w-2xl mx-auto">
      <div className="px-4 pt-6 pb-3">
        <h1 className="font-heading font-bold text-2xl text-charcoal-900">
          {loading ? "Finding builds…" : hasAnything ? "Here's what you can build" : "Let's find something"}
        </h1>
      </div>

      <div className="px-4 mb-4 overflow-x-auto">
        <div className="flex gap-2 pb-1">
          {FILTERS.map(f => (
            <FilterChip key={f} label={f} active={activeFilter === f} onClick={() => setActiveFilter(f)} />
          ))}
        </div>
      </div>

      {loading ? (
        <div className="px-4 grid grid-cols-2 gap-3">
          {[1, 2, 3, 4].map(i => (
            <div key={i} className="bg-white rounded-3xl shadow-card h-44 animate-pulse" />
          ))}
        </div>
      ) : limitReached ? (
        <div className="px-4">
          <EmptyState
            emoji="✨"
            title="Daily limit reached"
            description="You've used today's free recommendations. Upgrade to ScrapLab Plus for unlimited builds, or come back tomorrow."
            ctaLabel="Upgrade to Plus"
            ctaHref="/subscription"
          />
        </div>
      ) : error ? (
        <div className="px-4">
          <div className="bg-orange-50 border border-orange-200 rounded-2xl p-4 text-sm text-orange-700">{error}</div>
        </div>
      ) : !hasAnything ? (
        <EmptyState
          emoji="🔧"
          title="Not quite enough yet"
          description="Add a few more materials and we'll find the perfect build for you."
          ctaLabel="Pick More Materials"
          ctaHref="/create/manual"
        />
      ) : (
        <div className="pb-8">
          {filtered.length > 0 && (
            <div className="px-4 grid grid-cols-2 gap-3">
              {filtered.map(({ activity, matchLabel }) => (
                <ActivityCard key={activity.id} activity={activity} matchLabel={matchLabel} />
              ))}
            </div>
          )}

          {aiSuggestions.length > 0 && (
            <div className="mt-6">
              <div className="px-4 mb-3 flex items-center gap-2">
                <span className="text-sm font-heading font-semibold text-walnut-700">AI-Generated Ideas</span>
                <span className="text-xs text-walnut-500 font-body">via Gemini</span>
              </div>
              <div className="px-4 grid grid-cols-2 gap-3">
                {aiSuggestions.map((s, i) => (
                  <AiSuggestionCard key={i} suggestion={s} index={i} />
                ))}
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  );
}

export default function ResultsPage() {
  return (
    <AppShell>
      <Suspense fallback={<div className="p-8 text-center text-walnut-600">Loading results...</div>}>
        <ResultsContent />
      </Suspense>
    </AppShell>
  );
}
