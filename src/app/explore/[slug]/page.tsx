import { notFound } from "next/navigation";
import Link from "next/link";
import { MetadataChip } from "@/components/ui/MetadataChip";
import { SupervisionBadge } from "@/components/ui/SupervisionBadge";
import { Button } from "@/components/ui/Button";
import { createServiceClient } from "@/lib/db/client";
import { Clock, Zap, Users, ArrowLeft, Lightbulb, Shield, Wrench } from "lucide-react";
import { cn } from "@/lib/utils";
import type { Activity, SupervisionLevel } from "@/types";
import { CATEGORY_TILE, categoryEmoji } from "@/lib/categoryTheme";

// Neutral Ink/Slate scale, not green/yellow/red — difficulty must never be
// mistaken for the Leaf/Amber/Coral supervision-safety coding on this page.
const DIFFICULTY_COLOR: Record<string, string> = {
  easy: "bg-kraft-300/50 text-walnut-700",
  medium: "bg-kraft-500/30 text-walnut-800",
  hard: "bg-charcoal-900 text-white",
  adaptive: "bg-builder-500/15 text-builder-600",
};

async function fetchActivity(slug: string): Promise<Activity | null> {
  const db = createServiceClient();
  const { data, error } = await db
    .from("activities")
    .select("*")
    .or(`id.eq.${slug},slug.eq.${slug}`)
    .single();
  if (error || !data) return null;
  return data as Activity;
}

export default async function ActivityDetailPage({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;
  const activity = await fetchActivity(slug);
  if (!activity) return notFound();

  const bg = CATEGORY_TILE;
  const emoji = categoryEmoji(activity.category);
  const diffColor = DIFFICULTY_COLOR[activity.difficulty] ?? "bg-cream-100 text-walnut-700";

  return (
    <div className="max-w-2xl mx-auto pb-8">
        {/* Hero */}
        <div className={cn("relative h-48 flex items-center justify-center", bg)}>
          <Link href="/explore" className="absolute top-4 left-4 w-9 h-9 bg-white/80 rounded-2xl flex items-center justify-center">
            <ArrowLeft size={16} className="text-charcoal-900" />
          </Link>
          <span className="text-7xl">{emoji}</span>
          <span className={cn(
            "absolute top-4 right-4 px-3 py-1 rounded-full text-xs font-heading font-semibold",
            diffColor
          )}>
            {activity.difficulty}
          </span>
          {activity.premium && (
            <span className="absolute bottom-4 right-4 px-2.5 py-0.5 rounded-full text-xs font-heading font-semibold bg-sunshine text-charcoal-900">
              Plus
            </span>
          )}
        </div>

        <div className="px-4 py-5">
          <p className="text-xs font-heading font-semibold uppercase tracking-wide text-builder-500 mb-1 capitalize">
            {activity.category}
          </p>
          <h1 className="font-heading font-bold text-2xl text-charcoal-900 mb-1">
            {activity.title}
          </h1>
          {activity.one_liner && (
            <p className="text-sm text-walnut-600 mb-4 font-body italic">{activity.one_liner}</p>
          )}

          {/* Metadata chips */}
          <div className="flex flex-wrap gap-2 mb-6">
            <MetadataChip icon={<Clock size={11} />} label={`${activity.time_minutes} min`} />
            <MetadataChip icon={<Zap size={11} />} label={activity.energy_level} />
            <MetadataChip icon={<Users size={11} />} label={activity.age_ranges.join(", ")} />
            <SupervisionBadge level={activity.supervision_level as SupervisionLevel} />
            <MetadataChip icon={<Wrench size={11} />} label={activity.solo_or_group} />
          </div>

          {/* Description */}
          {activity.description && (
            <div className="bg-white rounded-3xl shadow-card p-5 mb-4">
              <p className="text-sm font-body text-charcoal-800 leading-relaxed">{activity.description}</p>
            </div>
          )}

          {/* Materials */}
          <div className="bg-white rounded-3xl shadow-card p-5 mb-4">
            <h2 className="font-heading font-semibold text-base text-charcoal-900 mb-3">Materials</h2>
            <div className="space-y-2">
              <div>
                <p className="text-xs font-heading font-semibold text-walnut-600 uppercase tracking-wide mb-1.5">Required</p>
                <div className="flex flex-wrap gap-2">
                  {activity.materials_required.map((m) => (
                    <span key={m} className="px-2.5 py-1 bg-cream-100 text-walnut-700 rounded-full text-xs font-body">
                      {m}
                    </span>
                  ))}
                </div>
              </div>
              {activity.materials_optional.length > 0 && (
                <div>
                  <p className="text-xs font-heading font-semibold text-walnut-600 uppercase tracking-wide mb-1.5 mt-3">Optional extras</p>
                  <div className="flex flex-wrap gap-2">
                    {activity.materials_optional.map((m) => (
                      <span key={m} className="px-2.5 py-1 bg-white border border-kraft-300 text-walnut-600 rounded-full text-xs font-body">
                        {m}
                      </span>
                    ))}
                  </div>
                </div>
              )}
            </div>
          </div>

          {/* Learning angle */}
          {activity.learning_angle && (
            <div className="bg-builder-500/10 rounded-3xl p-5 mb-4 flex gap-3">
              <Lightbulb size={18} className="text-builder-500 shrink-0 mt-0.5" />
              <div>
                <p className="text-xs font-heading font-semibold text-builder-700 mb-0.5">Learning angle</p>
                <p className="text-sm font-body text-charcoal-800">{activity.learning_angle}</p>
              </div>
            </div>
          )}

          {/* Expansion prompts */}
          {activity.expansion_prompts.length > 0 && (
            <div className="bg-white rounded-3xl shadow-card p-5 mb-4">
              <h2 className="font-heading font-semibold text-base text-charcoal-900 mb-3">Keep the creativity going</h2>
              <ul className="space-y-2">
                {activity.expansion_prompts.map((p, i) => (
                  <li key={i} className="flex items-start gap-2 text-sm font-body text-charcoal-800">
                    <span className="text-builder-400 shrink-0">→</span>
                    {p}
                  </li>
                ))}
              </ul>
            </div>
          )}

          {/* Safety notes */}
          {activity.safety_notes.length > 0 && (
            <div className="bg-caution/15 rounded-3xl p-5 mb-6">
              <h2 className="font-heading font-semibold text-sm text-caution-text mb-2 flex items-center gap-2">
                <Shield size={14} />
                Safety notes
              </h2>
              <ul className="space-y-1">
                {activity.safety_notes.map((n, i) => (
                  <li key={i} className="text-sm font-body text-caution-text">{n}</li>
                ))}
              </ul>
            </div>
          )}

          {/* Skill + scrap tags */}
          <div className="mb-6 space-y-3">
            {activity.skill_tags.length > 0 && (
              <div>
                <p className="text-xs font-heading font-semibold text-walnut-600 uppercase tracking-wide mb-1.5">Skills</p>
                <div className="flex flex-wrap gap-1.5">
                  {activity.skill_tags.map((t) => (
                    <span key={t} className="px-2.5 py-1 bg-cream-100 text-walnut-700 rounded-full text-xs font-body">
                      {t}
                    </span>
                  ))}
                </div>
              </div>
            )}
            {activity.scrap_tags.length > 0 && (
              <div>
                <p className="text-xs font-heading font-semibold text-walnut-600 uppercase tracking-wide mb-1.5">Scrap types</p>
                <div className="flex flex-wrap gap-1.5">
                  {activity.scrap_tags.map((t) => (
                    <span key={t} className="px-2.5 py-1 bg-cream-200 text-walnut-700 rounded-full text-xs font-body">
                      {t}
                    </span>
                  ))}
                </div>
              </div>
            )}
          </div>

          <Button variant="primary" size="lg" className="w-full">
            Let&apos;s build it!
          </Button>
        </div>
    </div>
  );
}
