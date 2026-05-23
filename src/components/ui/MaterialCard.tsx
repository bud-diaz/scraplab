"use client";
import { cn } from "@/lib/utils";

interface MaterialCardProps {
  id: string;
  name: string;
  icon: string;
  selected?: boolean;
  onToggle?: (id: string) => void;
}

export function MaterialCard({ id, name, icon, selected = false, onToggle }: MaterialCardProps) {
  return (
    <button
      onClick={() => onToggle?.(id)}
      className={cn(
        "flex flex-col items-center gap-2 p-3 rounded-2xl border-2 transition-all duration-150 w-full active:scale-95",
        selected
          ? "border-builder-500 bg-builder-500/10 shadow-card"
          : "border-kraft-300 bg-white hover:border-kraft-500"
      )}
    >
      <span className="text-2xl">{icon}</span>
      <span className={cn(
        "text-xs font-heading font-medium text-center leading-tight",
        selected ? "text-builder-600" : "text-charcoal-800"
      )}>
        {name}
      </span>
    </button>
  );
}
