"use client";
import Link from "next/link";
import { Hand, Camera, Package, Zap, ArrowRight, Lock } from "lucide-react";
import { UnlockPill } from "@/components/ui/UnlockPill";

type Method = {
  iconType: "hand" | "camera" | "package" | "zap";
  label: string;
  description: string;
  href: string;
  color: string;
  badge?: string;
  badgeColor?: string;
  /** Premium: renders the §4.4 Unlock pill instead of a text badge. */
  premium?: boolean;
  locked: boolean;
};

const methods: Method[] = [
  {
    iconType: "hand",
    label: "Choose Materials Manually",
    description: "Tap to select what you have on hand",
    href: "/create/manual",
    color: "bg-builder-500",
    badge: "Most Popular",
    badgeColor: "bg-orange-500/15 text-orange-700",
    locked: false,
  },
  {
    iconType: "camera",
    label: "Scan a Photo",
    description: "Take a photo and we'll detect your materials",
    href: "/create/scan",
    color: "bg-walnut-700",
    premium: true,
    locked: true,
  },
  {
    iconType: "package",
    label: "Use Household Staples",
    description: "Build from your saved usual materials",
    href: "/create/manual",
    color: "bg-kraft-500",
    badge: "Coming Soon",
    badgeColor: "bg-cream-100 text-walnut-600",
    locked: true,
  },
  {
    iconType: "zap",
    label: "Quick Build",
    description: "3 materials or fewer — fast project ideas",
    href: "/create/manual",
    color: "bg-orange-500",
    locked: false,
  },
];

function MethodIcon({ type }: { type: Method["iconType"] }) {
  if (type === "hand") return <Hand size={24} />;
  if (type === "camera") return <Camera size={24} />;
  if (type === "package") return <Package size={24} />;
  return <Zap size={24} />;
}

export function CreateMethods() {
  return (
    <>
      {methods.map((method) => (
        <Link
          key={method.label}
          href={method.href}
          className="flex items-center gap-4 bg-white rounded-3xl shadow-card p-4 hover:shadow-card-hover transition-all group"
        >
          <div className={`w-12 h-12 ${method.color} rounded-2xl flex items-center justify-center text-white shrink-0`}>
            <MethodIcon type={method.iconType} />
          </div>
          <div className="flex-1 min-w-0">
            <div className="flex items-center gap-2 mb-0.5">
              <h3 className="font-heading font-semibold text-base text-charcoal-900">{method.label}</h3>
              {method.premium && <UnlockPill />}
              {method.badge && (
                <span className={`text-[10px] font-heading font-semibold px-2 py-0.5 rounded-full ${method.badgeColor}`}>
                  {method.badge}
                </span>
              )}
            </div>
            <p className="text-sm text-walnut-600 font-body">{method.description}</p>
          </div>
          <div className="shrink-0">
            {method.locked ? (
              <Lock size={16} className="text-kraft-500" />
            ) : (
              <ArrowRight size={16} className="text-walnut-600 group-hover:text-builder-500 transition-colors" />
            )}
          </div>
        </Link>
      ))}
    </>
  );
}
