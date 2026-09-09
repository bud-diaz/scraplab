"use client";
import { useState, useEffect } from "react";
import { AppShell } from "@/components/layout/AppShell";
import { PageHeader } from "@/components/layout/PageHeader";
import { ProjectCard } from "@/components/cards/ProjectCard";
import { FilterChip } from "@/components/ui/FilterChip";
import { EmptyState } from "@/components/ui/EmptyState";
import { useAuth } from "@/lib/auth-context";
import { toDisplayProject } from "@/lib/display";

const tabs = ["Saved", "History", "Collections"];

interface ApiProject {
  id: string;
  slug: string;
  title: string;
  time_minutes: number;
  age_min: number;
  age_max: number;
  cleanup_level: string;
  supervision_level: string;
  difficulty: string;
  description: string;
}

interface SavedProjectRow {
  id: string;
  project: ApiProject;
}

interface SavedProject {
  savedId: string;
  project: ApiProject;
}

interface BuildHistoryRow {
  id: string;
  completion_status: string;
  project: ApiProject;
}

export default function LibraryPage() {
  const [activeTab, setActiveTab] = useState("Saved");
  const { session } = useAuth();

  // null = not yet fetched; [] = fetched but empty
  const [savedProjects, setSavedProjects] = useState<SavedProject[] | null>(null);
  const [historyProjects, setHistoryProjects] = useState<(ApiProject & { status: string })[] | null>(null);

  // Derive loading: authenticated but data not yet arrived
  const loading = !!session && (savedProjects === null || historyProjects === null);

  useEffect(() => {
    if (!session) return;
    const headers = { Authorization: `Bearer ${session.access_token}` };

    Promise.all([
      fetch('/api/saved-projects', { headers }).then(r => r.ok ? r.json() : { savedProjects: [] }),
      fetch('/api/build-history', { headers }).then(r => r.ok ? r.json() : { buildHistory: [] }),
    ])
      .then(([savedData, historyData]) => {
        setSavedProjects(
          (savedData.savedProjects as SavedProjectRow[])
            .filter(r => r.project)
            .map(r => ({ savedId: r.id, project: r.project }))
        );
        setHistoryProjects(
          (historyData.buildHistory as BuildHistoryRow[])
            .filter(r => r.project)
            .map(r => ({ ...r.project, status: r.completion_status }))
        );
      })
      .catch(() => {
        setSavedProjects([]);
        setHistoryProjects([]);
      });
  }, [session]);

  const savedDisplay = (savedProjects ?? []).map(p => ({ savedId: p.savedId, display: toDisplayProject(p.project) }));
  const historyDisplay = (historyProjects ?? []).map(p => toDisplayProject(p));

  const handleUnsave = (savedId: string) => {
    setSavedProjects(prev => (prev ?? []).filter(p => p.savedId !== savedId));
  };

  return (
    <AppShell>
      <div className="max-w-2xl mx-auto">
        <PageHeader title="Build Log" subtitle="Saved projects and build history" />

        {/* Spec §6: a dense tab bar shouldn't be the first thing under the
            header. The counts lead, and the views read as a secondary filter
            row in the same chip language the rest of the app uses. */}
        <p className="px-4 pb-3 font-body text-sm text-walnut-600">
          <span className="tabular font-semibold text-charcoal-900">{savedProjects?.length ?? 0}</span> saved
          {" · "}
          <span className="tabular font-semibold text-charcoal-900">{historyProjects?.length ?? 0}</span> built
        </p>

        <div className="mb-4 flex gap-2 overflow-x-auto px-4 pb-1">
          {tabs.map(tab => (
            <FilterChip
              key={tab}
              label={tab}
              active={activeTab === tab}
              onClick={() => setActiveTab(tab)}
            />
          ))}
        </div>

        <div className="px-4 pb-8">
          {activeTab === "Saved" && (
            loading ? (
              <div className="grid grid-cols-2 gap-3">
                {[0, 1].map(i => (
                  <div key={i} className="bg-cream-100 rounded-3xl h-48 animate-pulse" />
                ))}
              </div>
            ) : savedDisplay.length > 0 ? (
              <div className="grid grid-cols-2 gap-3">
                {savedDisplay.map(({ savedId, display }) => (
                  <ProjectCard
                    key={savedId}
                    project={{ ...display, supervisionLevel: display.supervisionLevelRaw }}
                    initialSaved
                    savedProjectId={savedId}
                    onSaveChange={(saved) => {
                      if (!saved) handleUnsave(savedId);
                    }}
                  />
                ))}
              </div>
            ) : (
              <EmptyState
                emoji="📚"
                title="Your workshop shelf is empty"
                description="Save projects you want to build later."
                ctaLabel="Find a Build"
                ctaHref="/create/manual"
              />
            )
          )}

          {activeTab === "History" && (
            loading ? (
              <div className="space-y-3">
                {[0, 1].map(i => (
                  <div key={i} className="bg-cream-100 rounded-3xl h-20 animate-pulse" />
                ))}
              </div>
            ) : historyDisplay.length > 0 ? (
              <div className="space-y-3">
                {(historyProjects ?? []).map((p, i) => {
                  const display = historyDisplay[i];
                  return (
                    <div key={p.id} className="bg-white rounded-3xl shadow-card p-4 flex items-center gap-4">
                      <div className={`w-14 h-14 ${display.bgColor} rounded-2xl flex items-center justify-center text-2xl shrink-0`}>
                        {display.emoji}
                      </div>
                      <div className="flex-1">
                        <h3 className="font-heading font-semibold text-sm text-charcoal-900">{display.title}</h3>
                        <p className="text-xs text-walnut-500">{display.timeEstimate} · {display.cleanupLevel} mess</p>
                      </div>
                      <span className={`text-xs px-2 py-1 rounded-full font-heading font-semibold ${
                        p.status === 'completed' ? 'bg-sunshine/30 text-charcoal-900' :
                        p.status === 'abandoned' ? 'bg-kraft-300 text-walnut-700' :
                        'bg-cream-200 text-walnut-600'
                      }`}>
                        {p.status === 'completed' ? 'Done' : p.status === 'abandoned' ? 'Stopped' : 'In Progress'}
                      </span>
                    </div>
                  );
                })}
              </div>
            ) : (
              <EmptyState
                emoji="🔨"
                title="Nothing built yet"
                description="Start a build and it'll show up here."
                ctaLabel="Let's fix that"
                ctaHref="/create/manual"
              />
            )
          )}

          {activeTab === "Collections" && (
            <EmptyState
              emoji="✨"
              title="Collections coming soon"
              description="Themed packs and seasonal collections will live here."
              ctaLabel="Explore Challenges"
              ctaHref="/challenges"
            />
          )}
        </div>
      </div>
    </AppShell>
  );
}
