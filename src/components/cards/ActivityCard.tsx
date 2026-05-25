"use client";
import Link from "next/link";
import { Clock, Zap, Users } from "lucide-react";
import { cn } from "@/lib/utils";
import { MetadataChip } from "@/components/ui/MetadataChip";
import type { Activity } from "@/types";

const CATEGORY_COLORS: Record<string, string> = {
  engineering: "bg-blue-100",
  science: "bg-green-100",
  art: "bg-pink-100",
  storytelling: "bg-purple-100",
  "pretend-play": "bg-yellow-100",
  cooperative: "bg-orange-100",
  puzzle: "bg-cyan-100",
  seasonal: "bg-red-100",
};

const CATEGORY_EMOJI: Record<string, string> = {
  engineering: "🔧",
  science: "🔬",
  art: "🎨",
  storytelling: "📖",
  "pretend-play": "🎭",
  cooperative: "🤝",
  puzzle: "🧩",
  seasonal: "🍂",
};

const DIFFICULTY_COLOR: Record<string, string> = {
  easy: "bg-green-100 text-green-700",
  medium: "bg-yellow-100 text-yellow-700",
  hard: "bg-red-100 text-red-700",
  adaptive: "bg-blue-100 text-blue-700",
};

interface ActivityCardProps {
  activity: Activity;
}

export function ActivityCard({ activity }: ActivityCardProps) {
  const bg = CATEGORY_COLORS[activity.category] ?? "bg-cream-100";
  const emoji = CATEGORY_EMOJI[activity.category] ?? "✨";
  const diffColor = DIFFICULTY_COLOR[activity.difficulty] ?? "bg-cream-100 text-walnut-700";

  return (
    <Link href={`/explore/${activity.slug}`} className="block group">
      <div className="bg-white rounded-3xl shadow-card hover:shadow-card-hover transition-all duration-200 overflow-hidden h-full flex flex-col">
        <div className={cn("h-28 flex items-center justify-center relative flex-shrink-0", bg)}>
          <span className="text-4xl">{emoji}</span>
          <span className={cn(
            "absolute top-3 right-3 px-2.5 py-0.5 rounded-full text-xs font-heading font-semibold",
            diffColor
          )}>
            {activity.difficulty}
          </span>
          {activity.premium && (
            <span className="absolute top-3 left-3 px-2 py-0.5 rounded-full text-xs font-heading font-semibold bg-yellow-400 text-yellow-900">
              Plus
            </span>
          )}
        </div>
        <div className="p-4 flex flex-col gap-2 flex-1">
          <h3 className="font-heading font-semibold text-sm text-charcoal-900 leading-snug line-clamp-2">
            {activity.title}
          </h3>
          {activity.one_liner && (
            <p className="text-xs text-charcoal-600 font-body line-clamp-2 leading-relaxed">
              {activity.one_liner}
            </p>
          )}
          <div className="flex flex-wrap gap-1.5 mt-auto pt-1">
            <MetadataChip icon={<Clock size={10} />} label={`${activity.time_minutes}m`} />
            <MetadataChip icon={<Zap size={10} />} label={activity.energy_level} />
            <MetadataChip icon={<Users size={10} />} label={activity.age_ranges[0] ?? "all ages"} />
          </div>
        </div>
      </div>
    </Link>
  );
}
