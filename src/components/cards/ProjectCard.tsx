"use client";
import Link from "next/link";
import { Clock, Trash2, Users, Bookmark, ArrowRight } from "lucide-react";
import { cn } from "@/lib/utils";
import { MetadataChip } from "@/components/ui/MetadataChip";
import { SupervisionBadge } from "@/components/ui/SupervisionBadge";
import { useAuth } from "@/lib/auth-context";
import { useState } from "react";
import type { SupervisionLevel } from "@/types";
import { isUuid } from "@/lib/validation/identifiers";

export interface ProjectCardProject {
  id: string;
  title: string;
  /** One-line summary, part of the §4.4 card anatomy. */
  description?: string;
  emoji: string;
  bgColor: string;
  timeEstimate: string;
  cleanupLevel: string;
  ageRange: string;
  supervisionLevel?: SupervisionLevel;
  matchLabel?: "Great Match" | "Close Match" | "Partial Match";
}

interface ProjectCardProps {
  project: ProjectCardProject;
  showMatch?: boolean;
  /** Pass when the caller already knows this project is saved (e.g. the
   * Library "Saved" tab), along with the saved_projects row id needed to
   * unsave it. */
  initialSaved?: boolean;
  savedProjectId?: string;
  /** Notified after a successful save/unsave so a parent list (e.g.
   * Library) can update its own state without a full refetch. */
  onSaveChange?: (saved: boolean, savedProjectId: string | null) => void;
}

export function ProjectCard({ project, showMatch = false, initialSaved = false, savedProjectId, onSaveChange }: ProjectCardProps) {
  const { session } = useAuth();
  const [saved, setSaved] = useState(initialSaved);
  const [savedId, setSavedId] = useState<string | null>(savedProjectId ?? null);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Mock/offline sample projects use slug-like ids that were never
  // persisted as a real projects.id UUID — bookmarking them would always
  // 400. Disable rather than let the click silently no-op.
  const bookmarkable = isUuid(project.id);

  const handleBookmark = async (e: React.MouseEvent) => {
    e.preventDefault();
    if (!session || saving || !bookmarkable) return;
    setSaving(true);
    setError(null);
    try {
      if (saved) {
        if (!savedId) {
          setError("Can't unsave this right now");
          return;
        }
        const res = await fetch(`/api/saved-projects/${savedId}`, {
          method: "DELETE",
          headers: { Authorization: `Bearer ${session.access_token}` },
        });
        if (res.ok) {
          setSaved(false);
          setSavedId(null);
          onSaveChange?.(false, null);
        } else if (res.status === 401) {
          setError("Sign in to manage saved projects");
        } else {
          setError("Could not remove — try again");
        }
      } else {
        const res = await fetch("/api/saved-projects", {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${session.access_token}`,
          },
          body: JSON.stringify({ projectId: project.id }),
        });
        if (res.ok) {
          const data = await res.json();
          const newSavedId: string | null = data.savedProject?.id ?? null;
          setSaved(true);
          setSavedId(newSavedId);
          onSaveChange?.(true, newSavedId);
        } else if (res.status === 409) {
          setSaved(true);
        } else if (res.status === 429) {
          setError("Save limit reached — upgrade to Plus for unlimited saves");
        } else if (res.status === 401) {
          setError("Sign in to save projects");
        } else {
          setError("Could not save — try again");
        }
      }
    } catch {
      setError("Network error — try again");
    } finally {
      setSaving(false);
    }
  };

  return (
    <Link href={`/projects/${project.id}`} className="block group">
      <div className="bg-white rounded-3xl shadow-card hover:shadow-card-hover transition-all duration-200 overflow-hidden">
        <div className={cn("h-32 flex items-center justify-center relative", project.bgColor)}>
          <span className="text-5xl">{project.emoji}</span>
          {showMatch && project.matchLabel && (
            <span className={cn(
              "absolute top-3 right-3 px-2.5 py-1 rounded-full text-xs font-heading font-semibold",
              project.matchLabel === "Great Match" ? "bg-orange-500/15 text-orange-700" : "bg-cream-100 text-walnut-700"
            )}>
              {project.matchLabel}
            </span>
          )}
          <button
            onClick={handleBookmark}
            disabled={!bookmarkable || saving}
            aria-label={saved ? "Remove from saved" : "Save project"}
            title={error ?? (!bookmarkable ? "This sample project can't be saved yet" : undefined)}
            className={cn(
              "absolute top-3 left-3 w-7 h-7 bg-white/80 rounded-full flex items-center justify-center hover:bg-white transition-colors",
              (!session || !bookmarkable) && "opacity-40 cursor-default"
            )}
          >
            <Bookmark
              size={13}
              className={cn(
                error ? "text-coral" : saved ? "text-builder-500 fill-builder-500" : "text-walnut-700"
              )}
            />
          </button>
          {error && (
            <span role="status" className="sr-only">
              {error}
            </span>
          )}
        </div>
        {/* Card anatomy per spec §4.4: title, one-line description, the
            always-visible Reality Indicator chip row, then the Start CTA. */}
        <div className="p-4">
          <h3 className="font-heading font-semibold text-base text-charcoal-900">{project.title}</h3>
          {project.description ? (
            <p className="mt-1 line-clamp-2 font-body text-xs leading-relaxed text-walnut-600">
              {project.description}
            </p>
          ) : null}
          <div className="mt-2 flex flex-wrap gap-1.5">
            <MetadataChip icon={<Clock size={11} />} label={project.timeEstimate} className="tabular" />
            <MetadataChip icon={<Trash2 size={11} />} label={project.cleanupLevel + " mess"} />
            <MetadataChip icon={<Users size={11} />} label={"Ages " + project.ageRange} className="tabular" />
            {project.supervisionLevel && <SupervisionBadge level={project.supervisionLevel} />}
          </div>
          <span className="mt-3 flex items-center gap-1 font-heading text-sm font-semibold text-builder-500 transition-colors group-hover:text-builder-600">
            Start
            <ArrowRight size={13} aria-hidden />
          </span>
        </div>
      </div>
    </Link>
  );
}
