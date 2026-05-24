"use client";
import { useState, useEffect } from "react";
import { AppShell } from "@/components/layout/AppShell";
import { PageHeader } from "@/components/layout/PageHeader";
import { ProjectCard } from "@/components/cards/ProjectCard";
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

interface BuildHistoryRow {
  id: string;
  completion_status: string;
  project: ApiProject;
}

export default function LibraryPage() {
  const [activeTab, setActiveTab] = useState("Saved");
  const { session } = useAuth();

  // null = not yet fetched; [] = fetched but empty
  const [savedProjects, setSavedProjects] = useState<ApiProject[] | null>(null);
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
          (savedData.savedProjects as SavedProjectRow[]).map(r => r.project).filter(Boolean)
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

  const savedDisplay = (savedProjects ?? []).map(p => toDisplayProject(p));
  const historyDisplay = (historyProjects ?? []).map(p => toDisplayProject(p));

  return (
    <AppShell>
      <div className="max-w-2xl mx-auto">
        <PageHeader title="Your Library" subtitle="Saved projects and build history" />

        <div className="px-4 mb-4 flex gap-1 bg-cream-100 rounded-2xl p-1">
          {tabs.map(tab => (
            <button
              key={tab}
              onClick={() => setActiveTab(tab)}
              className={`flex-1 py-2 text-sm font-heading font-semibold rounded-xl transition-all ${
                activeTab === tab
                  ? "bg-white text-charcoal-900 shadow-card"
                  : "text-walnut-600 hover:text-charcoal-900"
              }`}
            >
              {tab}
            </button>
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
                {savedDisplay.map(project => (
                  <ProjectCard key={project.id} project={project} />
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
                        p.status === 'completed' ? 'bg-green-100 text-green-700' :
                        p.status === 'abandoned' ? 'bg-red-50 text-red-600' :
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
