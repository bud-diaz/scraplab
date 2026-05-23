"use client";
import Link from "next/link";
import { Camera, Hand, Shuffle } from "lucide-react";

const quickActions = [
  {
    iconType: "hand" as const,
    label: "Manual Pick",
    description: "Choose from your stash",
    href: "/create/manual",
    color: "bg-builder-500",
    locked: false,
  },
  {
    iconType: "camera" as const,
    label: "Scan Materials",
    description: "Photo scan",
    href: "/create/scan",
    color: "bg-walnut-700",
    locked: true,
  },
  {
    iconType: "shuffle" as const,
    label: "Surprise Me",
    description: "Random build",
    href: "/create/results",
    color: "bg-kraft-500",
    locked: false,
  },
];

function ActionIcon({ type }: { type: "hand" | "camera" | "shuffle" }) {
  if (type === "hand") return <Hand size={20} />;
  if (type === "camera") return <Camera size={20} />;
  return <Shuffle size={20} />;
}

export function QuickActions() {
  return (
    <div className="grid grid-cols-3 gap-3">
      {quickActions.map((action) => (
        <Link
          key={action.label}
          href={action.href}
          className="relative bg-white rounded-2xl shadow-card p-3 flex flex-col items-center gap-2 text-center hover:shadow-card-hover transition-all"
        >
          {action.locked && (
            <span className="absolute top-2 right-2 text-[10px] bg-orange-500 text-white px-1.5 py-0.5 rounded-full font-heading font-semibold">Plus</span>
          )}
          <div className={`w-10 h-10 ${action.color} rounded-xl flex items-center justify-center text-white`}>
            <ActionIcon type={action.iconType} />
          </div>
          <div>
            <p className="font-heading font-semibold text-xs text-charcoal-900">{action.label}</p>
            <p className="text-[10px] text-walnut-600 font-body">{action.description}</p>
          </div>
        </Link>
      ))}
    </div>
  );
}
