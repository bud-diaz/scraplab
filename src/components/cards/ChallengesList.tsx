"use client";
import Link from "next/link";
import { Lock, Calendar, Zap, Package } from "lucide-react";

type Challenge = {
  iconType: "calendar" | "package" | "zap" | "lock";
  label: string;
  description: string;
  badge: string;
  badgeColor: string;
  href: string;
  locked: boolean;
  color: string;
};

const challenges: Challenge[] = [
  {
    iconType: "calendar",
    label: "Weekend Build Challenge",
    description: "Build something that can carry 5 things using only recyclables.",
    badge: "Active",
    badgeColor: "bg-orange-500/15 text-orange-700",
    href: "#",
    locked: false,
    color: "bg-builder-500",
  },
  {
    iconType: "package",
    label: "Minimal Materials Mode",
    description: "3 materials. 15 minutes. Make it work.",
    badge: "New",
    badgeColor: "bg-orange-100 text-orange-600",
    href: "/create/manual",
    locked: false,
    color: "bg-kraft-500",
  },
  {
    iconType: "zap",
    label: "Mystery Build",
    description: "We give you 3 random materials. You build something cool.",
    badge: "Plus",
    badgeColor: "bg-walnut-700/10 text-walnut-700",
    href: "/build/mystery",
    locked: true,
    color: "bg-walnut-700",
  },
  {
    iconType: "lock",
    label: "Kid Chooses Chaos",
    description: "Let the kid pick the materials. You figure out the rest.",
    badge: "Coming Soon",
    badgeColor: "bg-cream-200 text-walnut-600",
    href: "#",
    locked: true,
    color: "bg-charcoal-800",
  },
];

function ChallengeIcon({ type }: { type: Challenge["iconType"] }) {
  if (type === "calendar") return <Calendar size={20} />;
  if (type === "package") return <Package size={20} />;
  if (type === "zap") return <Zap size={20} />;
  return <Lock size={20} />;
}

export function ChallengesList() {
  return (
    <>
      {challenges.map(challenge => (
        <Link
          key={challenge.label}
          href={challenge.href}
          className="flex items-center gap-4 bg-white rounded-3xl shadow-card p-4 hover:shadow-card-hover transition-all"
        >
          <div className={`w-12 h-12 ${challenge.color} rounded-2xl flex items-center justify-center text-white shrink-0`}>
            <ChallengeIcon type={challenge.iconType} />
          </div>
          <div className="flex-1 min-w-0">
            <div className="flex items-center gap-2 mb-0.5">
              <h3 className="font-heading font-semibold text-sm text-charcoal-900">{challenge.label}</h3>
              <span className={`text-[10px] font-heading font-semibold px-2 py-0.5 rounded-full ${challenge.badgeColor}`}>
                {challenge.badge}
              </span>
            </div>
            <p className="text-xs text-walnut-600 font-body">{challenge.description}</p>
          </div>
          {challenge.locked && <Lock size={14} className="text-kraft-500 shrink-0" />}
        </Link>
      ))}
    </>
  );
}
