"use client";
import { Suspense } from "react";
import { useSearchParams } from "next/navigation";
import { AppShell } from "@/components/layout/AppShell";
import { ProjectCard } from "@/components/cards/ProjectCard";
import { FilterChip } from "@/components/ui/FilterChip";
import { EmptyState } from "@/components/ui/EmptyState";
import { projects, materials } from "@/lib/mock-data";
import { useState } from "react";

const matchLabels: ("Great Match" | "Close Match" | "Partial Match")[] = [
  "Great Match", "Great Match", "Close Match", "Partial Match", "Close Match"
];

function ResultsContent() {
  const searchParams = useSearchParams();
  const selectedIds = searchParams.getAll("materials");
  const [activeFilter, setActiveFilter] = useState("All");

  const filters = ["All", "Quick", "Low Mess", "Independent"];

  const labeledProjects = projects.map((p, i) => ({
    ...p,
    matchLabel: matchLabels[i] ?? "Partial Match" as const,
  }));

  const filtered = labeledProjects.filter(p => {
    if (activeFilter === "Quick") return parseInt(p.timeEstimate) <= 15;
    if (activeFilter === "Low Mess") return p.cleanupLevel === "Low";
    if (activeFilter === "Independent") return p.supervisionLevel === "Independent";
    return true;
  });

  const selectedNames = selectedIds
    .map(id => materials.find(m => m.id === id)?.name)
    .filter(Boolean)
    .join(", ");

  return (
    <div className="max-w-2xl mx-auto">
      <div className="px-4 pt-6 pb-3">
        <h1 className="font-heading font-bold text-2xl text-charcoal-900">
          {filtered.length > 0 ? "Here’s what you can build" : "Let’s find something"}
        </h1>
        {selectedNames && (
          <p className="text-sm text-walnut-600 mt-0.5">Using: {selectedNames}</p>
        )}
      </div>

      <div className="px-4 mb-4 overflow-x-auto">
        <div className="flex gap-2 pb-1">
          {filters.map(f => (
            <FilterChip
              key={f}
              label={f}
              active={activeFilter === f}
              onClick={() => setActiveFilter(f)}
            />
          ))}
        </div>
      </div>

      {filtered.length === 0 ? (
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
            <ProjectCard key={project.id} project={project} showMatch />
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
