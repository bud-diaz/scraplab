"use client";
import Link from "next/link";
import { Zap } from "lucide-react";
import { useAuth } from "@/lib/auth-context";
import { usePlanAccess } from "@/lib/hooks/usePlanAccess";

export function PlanUsageIndicator() {
  const { session } = useAuth();
  const access = usePlanAccess();

  if (!session || !access) return null;

  if (access.plan === 'plus') {
    return (
      <div className="flex items-center gap-1.5 bg-walnut-700 text-white px-3 py-1.5 rounded-2xl text-xs font-heading font-semibold">
        <Zap size={12} />
        Plus
      </div>
    );
  }

  const used = access.usage.recommendationsToday;
  const limit = access.limits.dailyRecommendations ?? 3;
  const pct = Math.min((used / limit) * 100, 100);
  const atLimit = used >= limit;

  return (
    <Link
      href="/upgrade"
      className={`flex items-center gap-2.5 px-3 py-1.5 rounded-2xl text-xs font-heading font-semibold transition-colors ${
        atLimit ? 'bg-coral/10 text-coral-text hover:bg-coral/20' : 'bg-cream-100 text-walnut-700 hover:bg-cream-200'
      }`}
    >
      <span className="tabular whitespace-nowrap">
        {atLimit ? 'Limit reached' : `${used}/${limit} builds today`}
      </span>
      <div className="w-16 h-1.5 bg-cream-200 rounded-full overflow-hidden">
        <div
          className={`h-full rounded-full transition-all ${atLimit ? 'bg-coral' : 'bg-builder-500'}`}
          style={{ width: `${pct}%` }}
        />
      </div>
    </Link>
  );
}
