import { cn } from "@/lib/utils";

interface ProgressStepperProps {
  current: number;
  total: number;
}

export function ProgressStepper({ current, total }: ProgressStepperProps) {
  const progress = (current / total) * 100;
  return (
    <div className="space-y-2">
      <div className="flex justify-between items-center">
        <span className="text-sm font-heading font-medium text-walnut-700">
          Step {current} of {total}
        </span>
        <span className="text-sm font-heading font-medium text-walnut-600">
          {Math.round(progress)}%
        </span>
      </div>
      <div className="h-2 bg-cream-200 rounded-full overflow-hidden">
        <div
          className="h-full bg-builder-500 rounded-full transition-all duration-500"
          style={{ width: `${progress}%` }}
        />
      </div>
    </div>
  );
}
