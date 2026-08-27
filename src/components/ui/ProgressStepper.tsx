interface ProgressStepperProps {
  current: number;
  total: number;
}

/**
 * Guided-build step progress — new_scraplab-design-spec.md §4.5, which calls
 * for the counter as a rounded pill ("Step 2/6") rather than inline text.
 * Figures are tabular (§3) so the pill doesn't jump width between steps.
 */
export function ProgressStepper({ current, total }: ProgressStepperProps) {
  const progress = total > 0 ? (current / total) * 100 : 0;

  return (
    <div className="space-y-2">
      <div className="flex items-center justify-between gap-2">
        <span className="font-heading text-sm font-medium text-walnut-700">
          {Math.round(progress)}% done
        </span>
        <span className="tabular rounded-full bg-cream-100 px-2.5 py-0.5 font-heading text-xs font-semibold text-walnut-700">
          Step {current}/{total}
        </span>
      </div>
      <div className="h-2 overflow-hidden rounded-full bg-cream-200">
        <div
          className="h-full rounded-full bg-builder-500 transition-all duration-500"
          style={{ width: `${progress}%` }}
        />
      </div>
    </div>
  );
}
