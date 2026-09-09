import { cn } from "@/lib/utils";
import { ShieldCheck, ShieldAlert, ShieldX, ShieldQuestion } from "lucide-react";
import type { SupervisionLevel } from "@/types";

interface SupervisionBadgeProps {
  /** null renders a neutral "unknown" badge rather than omitting the
   * safety label entirely — an unrecognized value must never look like
   * "no supervision needed". */
  level: SupervisionLevel | null;
  className?: string;
}

const SUPERVISION_META: Record<SupervisionLevel, { label: string; bg: string; text: string; icon: typeof ShieldCheck }> = {
  independent:      { label: "Independent",      bg: "bg-leaf/15",    text: "text-leaf-text",    icon: ShieldCheck },
  check_in:         { label: "Check In",          bg: "bg-leaf/15",    text: "text-leaf-text",    icon: ShieldCheck },
  adult_assist:     { label: "Adult Assist",      bg: "bg-caution/15", text: "text-caution-text", icon: ShieldAlert },
  full_supervision: { label: "Full Supervision",  bg: "bg-coral/15",   text: "text-coral-text",   icon: ShieldX },
};

const UNKNOWN_META = { label: "Supervision level unknown", bg: "bg-kraft-300/50", text: "text-walnut-700", icon: ShieldQuestion };

export function SupervisionBadge({ level, className }: SupervisionBadgeProps) {
  const meta = (level ? SUPERVISION_META[level] : undefined) ?? UNKNOWN_META;
  const Icon = meta.icon;
  return (
    <span className={cn(
      "inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-body font-medium",
      meta.bg, meta.text, className
    )}>
      <Icon size={12} strokeWidth={2.5} />
      {meta.label}
    </span>
  );
}
