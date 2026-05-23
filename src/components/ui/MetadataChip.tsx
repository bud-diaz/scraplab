import { cn } from "@/lib/utils";

interface MetadataChipProps {
  icon?: React.ReactNode;
  label: string;
  className?: string;
}

export function MetadataChip({ icon, label, className }: MetadataChipProps) {
  return (
    <span className={cn(
      "inline-flex items-center gap-1 px-2.5 py-1 bg-cream-100 text-walnut-700 rounded-full text-xs font-body font-medium",
      className
    )}>
      {icon}
      {label}
    </span>
  );
}
