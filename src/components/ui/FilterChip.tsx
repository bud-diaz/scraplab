"use client";
import { cn } from "@/lib/utils";

interface FilterChipProps {
  label: string;
  active?: boolean;
  onClick?: () => void;
}

export function FilterChip({ label, active = false, onClick }: FilterChipProps) {
  return (
    <button
      onClick={onClick}
      className={cn(
        "px-3.5 py-1.5 rounded-full text-sm font-heading font-medium transition-all whitespace-nowrap",
        active
          ? "bg-builder-500 text-white shadow-card"
          : "bg-white border border-kraft-400 text-walnut-700 hover:border-builder-500 hover:text-builder-500"
      )}
    >
      {label}
    </button>
  );
}
