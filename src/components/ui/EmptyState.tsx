import { cn } from "@/lib/utils";
import { Button } from "./Button";

interface EmptyStateProps {
  emoji?: string;
  title: string;
  description?: string;
  ctaLabel?: string;
  ctaHref?: string;
  className?: string;
}

export function EmptyState({ emoji = "🔍", title, description, ctaLabel, ctaHref, className }: EmptyStateProps) {
  return (
    <div className={cn("flex flex-col items-center justify-center text-center py-16 px-6", className)}>
      <span className="text-5xl mb-4">{emoji}</span>
      <h3 className="font-heading font-semibold text-lg text-charcoal-900 mb-2">{title}</h3>
      {description && <p className="text-sm text-walnut-600 mb-6 max-w-xs">{description}</p>}
      {ctaLabel && ctaHref && (
        <a href={ctaHref}>
          <Button variant="primary">{ctaLabel}</Button>
        </a>
      )}
    </div>
  );
}
