"use client";
import Link from "next/link";
import { Clock, Trash2, Users, Bookmark } from "lucide-react";
import { Project } from "@/lib/mock-data";
import { cn } from "@/lib/utils";
import { MetadataChip } from "@/components/ui/MetadataChip";

interface ProjectCardProps {
  project: Project;
  showMatch?: boolean;
}

export function ProjectCard({ project, showMatch = false }: ProjectCardProps) {
  return (
    <Link href={`/projects/${project.id}`} className="block group">
      <div className="bg-white rounded-3xl shadow-card hover:shadow-card-hover transition-all duration-200 overflow-hidden">
        <div className={cn("h-32 flex items-center justify-center relative", project.bgColor)}>
          <span className="text-5xl">{project.emoji}</span>
          {showMatch && project.matchLabel && (
            <span className={cn(
              "absolute top-3 right-3 px-2.5 py-1 rounded-full text-xs font-heading font-semibold",
              project.matchLabel === "Great Match" ? "bg-green-100 text-green-700" : "bg-cream-100 text-walnut-700"
            )}>
              {project.matchLabel}
            </span>
          )}
          <button
            onClick={(e) => { e.preventDefault(); }}
            className="absolute top-3 left-3 w-7 h-7 bg-white/80 rounded-full flex items-center justify-center hover:bg-white transition-colors"
          >
            <Bookmark size={13} className="text-walnut-700" />
          </button>
        </div>
        <div className="p-4">
          <h3 className="font-heading font-semibold text-base text-charcoal-900 mb-2">{project.title}</h3>
          <div className="flex flex-wrap gap-1.5">
            <MetadataChip icon={<Clock size={11} />} label={project.timeEstimate} />
            <MetadataChip icon={<Trash2 size={11} />} label={project.cleanupLevel + " mess"} />
            <MetadataChip icon={<Users size={11} />} label={"Ages " + project.ageRange} />
          </div>
        </div>
      </div>
    </Link>
  );
}
