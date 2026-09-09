"use client";
import Link from "next/link";
import { Clock, Zap, Users } from "lucide-react";
import { cn } from "@/lib/utils";
import { MetadataChip } from "@/components/ui/MetadataChip";
import { SupervisionBadge } from "@/components/ui/SupervisionBadge";
import type { Activity } from "@/types";
import { CATEGORY_TILE, categoryEmoji } from "@/lib/categoryTheme";
import { normalizeActivitySupervisionLevel } from "@/lib/activities/supervision";

// Neutral Ink/Slate scale, not green/yellow/red — difficulty must never be
// mistaken for the Leaf/Amber/Coral supervision-safety coding on the same card.
const DIFFICULTY_COLOR: Record<string, string> = {
  easy: "bg-kraft-300/50 text-walnut-700",
  medium: "bg-kraft-500/30 text-walnut-800",
  hard: "bg-charcoal-900 text-white",
  adaptive: "bg-builder-500/15 text-builder-600",
};

interface ActivityCardProps {
  activity: Activity;
  matchLabel?: "Perfect Match" | "Good Match" | "Partial Match";
}

export function ActivityCard({ activity, matchLabel }: ActivityCardProps) {
  const bg = CATEGORY_TILE;
  const emoji = categoryEmoji(activity.category);
  const diffColor = DIFFICULTY_COLOR[activity.difficulty] ?? "bg-cream-100 text-walnut-700";

  return (
    <Link href={`/explore/${activity.slug}`} className="block group">
      <div className="bg-white rounded-3xl shadow-card hover:shadow-card-hover transition-all duration-200 overflow-hidden h-full flex flex-col">
        <div className={cn("h-28 flex items-center justify-center relative flex-shrink-0", bg)}>
          <span className="text-4xl">{emoji}</span>
          {matchLabel ? (
            <span className={cn(
              "absolute top-3 right-3 px-2.5 py-0.5 rounded-full text-xs font-heading font-semibold",
              matchLabel === "Perfect Match" ? "bg-orange-500/15 text-orange-700" : "bg-cream-100 text-walnut-700"
            )}>
              {matchLabel}
            </span>
          ) : (
            <span className={cn(
              "absolute top-3 right-3 px-2.5 py-0.5 rounded-full text-xs font-heading font-semibold",
              diffColor
            )}>
              {activity.difficulty}
            </span>
          )}
          {activity.premium && (
            <span className="absolute top-3 left-3 px-2 py-0.5 rounded-full text-xs font-heading font-semibold bg-sunshine text-charcoal-900">
              Plus
            </span>
          )}
        </div>
        <div className="p-4 flex flex-col gap-2 flex-1">
          <h3 className="font-heading font-semibold text-sm text-charcoal-900 leading-snug line-clamp-2">
            {activity.title}
          </h3>
          {activity.one_liner && (
            <p className="text-xs text-walnut-600 font-body line-clamp-2 leading-relaxed">
              {activity.one_liner}
            </p>
          )}
          <div className="flex flex-wrap gap-1.5 mt-auto pt-1">
            <MetadataChip icon={<Clock size={10} />} label={`${activity.time_minutes}m`} />
            <MetadataChip icon={<Zap size={10} />} label={activity.energy_level} />
            <MetadataChip icon={<Users size={10} />} label={activity.age_ranges[0] ?? "all ages"} />
            {activity.supervision_level && (
              <SupervisionBadge level={normalizeActivitySupervisionLevel(activity.supervision_level)} />
            )}
          </div>
        </div>
      </div>
    </Link>
  );
}
