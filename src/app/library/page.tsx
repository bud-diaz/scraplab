"use client";
import { useState } from "react";
import { AppShell } from "@/components/layout/AppShell";
import { PageHeader } from "@/components/layout/PageHeader";
import { ProjectCard } from "@/components/cards/ProjectCard";
import { EmptyState } from "@/components/ui/EmptyState";
import { projects } from "@/lib/mock-data";

const tabs = ["Saved", "History", "Collections"];

export default function LibraryPage() {
  const [activeTab, setActiveTab] = useState("Saved");

  const savedProjects = projects.slice(0, 2);
  const historyProjects = projects.slice(2, 4);

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
            savedProjects.length > 0 ? (
              <div className="grid grid-cols-2 gap-3">
                {savedProjects.map(project => (
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
            historyProjects.length > 0 ? (
              <div className="space-y-3">
                {historyProjects.map(project => (
                  <div key={project.id} className="bg-white rounded-3xl shadow-card p-4 flex items-center gap-4">
                    <div className={`w-14 h-14 ${project.bgColor} rounded-2xl flex items-center justify-center text-2xl shrink-0`}>
                      {project.emoji}
                    </div>
                    <div className="flex-1">
                      <h3 className="font-heading font-semibold text-sm text-charcoal-900">{project.title}</h3>
                      <p className="text-xs text-walnut-500">{project.timeEstimate} · {project.cleanupLevel} mess</p>
                    </div>
                    <span className="text-xs bg-green-100 text-green-700 px-2 py-1 rounded-full font-heading font-semibold">Done</span>
                  </div>
                ))}
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
