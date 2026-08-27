import { Lock } from "lucide-react";
import { cn } from "@/lib/utils";

/**
 * Locked/premium marker — new_scraplab-design-spec.md §4.4, which calls for the
 * "Unlock" lock-icon pill rather than a bare text badge. Soft-filled and fully
 * rounded like every other chip in the system (§5).
 */
export function UnlockPill({ label = "Unlock", className }: { label?: string; className?: string }) {
  return (
    <span
      className={cn(
        "inline-flex items-center gap-1 rounded-full bg-orange-500/15 px-2 py-0.5 font-heading text-[10px] font-semibold text-orange-700",
        className
      )}
    >
      <Lock size={9} strokeWidth={2.5} aria-hidden />
      {label}
    </span>
  );
}
