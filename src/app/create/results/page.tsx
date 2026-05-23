"use client";
import { Suspense, useEffect, useState, useRef } from "react";
import { useSearchParams } from "next/navigation";
import { AppShell } from "@/components/layout/AppShell";
import { ProjectCard } from "@/components/cards/ProjectCard";
import { FilterChip } from "@/components/ui/FilterChip";
import { EmptyState } from "@/components/ui/EmptyState";
import { useAuth } from "@/lib/auth-context";
import { toDisplayProject } from "@/lib/display";
import type { DisplayProject } from "@/lib/display";
import type { ProjectRecommendation, MatchType } from "@/types";

const FILTERS = ["All", "Quick", "Low Mess", "Independent"];

function ResultsContent() {
  const searchParams = useSearchParams();
  const selectedIds = searchParams.getAll("materials");
  const { session } = useAuth();
  const [activeFilter, setActiveFilter] = useState("All");
  const [projects, setProjects] = useState<DisplayProject[]>([]);
  const [loading, setLoading] = useState(() => selectedIds.length > 0);
  const [error, setError] = useState<string | null>(null);
  const loadedFor = useRef<string>("");

  useEffect(() => {
    const key = `${session?.access_token ?? "anon"}:${selectedIds.join(",")}`;
    if (!selectedIds.length || loadedFor.current === key) return;
    loadedFor.current = key;

    let cancelled = false;
    setLoading(true);
    setError(null);

    async function load() {
      // Authenticated path: use the recommendation engine (ranked + age-aware)
      if (session) {
        const res = await fetch('/api/recommendations', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${session.access_token}`,
          },
          body: JSON.stringify({ materialIds: selectedIds, childAge: 7 }),
        });

        if (res.ok) {
          const { recommendations }: { recommendations: ProjectRecommendation[] } = await res.json();
          if (recommendations.length === 0) { if (!cancelled) setProjects([]); return; }

          // Fetch all projects once to resolve recommendation IDs to full project data
          const projRes = await fetch('/api/projects');
          const { projects: allProjects } = await projRes.json();
          // eslint-disable-next-line @typescript-eslint/no-explicit-any
          const byId = Object.fromEntries((allProjects as any[]).map((p: any) => [p.id, p]));

          const display = recommendations
            .map((r: ProjectRecommendation) => {
              const p = byId[r.projectId];
              if (!p) return null;
              return toDisplayProject(p, r.matchType as MatchType);
            })
            .filter((p): p is DisplayProject => p !== null);

          if (!cancelled) setProjects(display);
          return;
        }
        // Fall through to unauthenticated path on non-OK (e.g. 400 from slug IDs, 429 limit)
      }

      // Unauthenticated (or recommendation failure) path: filter projects by material
      const res = await fetch(`/api/projects?materials=${selectedIds.join(',')}`);
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      const { projects: raw }: { projects: any[] } = await res.json();
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      if (!cancelled) setProjects(raw.map((p: any) => toDisplayProject(p)));
    }

    load()
      .catch(e => { if (!cancelled) setError(e instanceof Error ? e.message : 'Something went wrong') })
      .finally(() => { if (!cancelled) setLoading(false) });

    return () => { cancelled = true; };
  }, [session?.access_token, selectedIds.join(",")]); // eslint-disable-line react-hooks/exhaustive-deps

  const filtered = projects.filter(p => {
    if (activeFilter === "Quick") return parseInt(p.timeEstimate) <= 15;
    if (activeFilter === "Low Mess") return p.cleanupLevel === "Low";
    if (activeFilter === "Independent") return p.supervisionLevel === "Independent";
    return true;
  });

  return (
    <div className="max-w-2xl mx-auto">
      <div className="px-4 pt-6 pb-3">
        <h1 className="font-heading font-bold text-2xl text-charcoal-900">
          {loading ? "Finding builds…" : filtered.length > 0 ? "Here's what you can build" : "Let's find something"}
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
      ) : error ? (
        <div className="px-4">
          <div className="bg-orange-50 border border-orange-200 rounded-2xl p-4 text-sm text-orange-700">{error}</div>
        </div>
      ) : filtered.length === 0 ? (
        <EmptyState
          emoji="🔧"
          title="Not quite enough yet"
          description="Add a few more materials and we'll find the perfect build for you."
          ctaLabel="Pick More Materials"
          ctaHref="/create/manual"
        />
      ) : (
        <div className="px-4 grid grid-cols-2 gap-3 pb-8">
          {filtered.map(project => (
            <ProjectCard key={project.id} project={project} showMatch={!!project.matchLabel} />
          ))}
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
