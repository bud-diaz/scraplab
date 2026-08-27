import { Lightbulb, AlertTriangle } from "lucide-react";
import { BuildStep } from "@/lib/mock-data";
import { StepIllustration } from "@/components/ui/StepIllustration";

interface StepCardProps {
  step: BuildStep;
}

export function StepCard({ step }: StepCardProps) {
  return (
    <div className="bg-white rounded-3xl shadow-card p-6 space-y-4">
      <h2 className="font-heading font-bold text-2xl text-charcoal-900">{step.title}</h2>
      <StepIllustration title={step.title} />
      <p className="text-base font-body text-charcoal-800 leading-relaxed">{step.instruction}</p>
      {step.tip && (
        <div className="flex items-start gap-2 bg-builder-500/10 rounded-2xl px-4 py-3">
          <Lightbulb size={15} className="text-builder-500 mt-0.5 shrink-0" />
          <p className="text-sm font-body text-builder-600">{step.tip}</p>
        </div>
      )}
      {step.safetyNote && (
        <div className="flex items-start gap-2 bg-caution/15 rounded-2xl px-4 py-3">
          <AlertTriangle size={15} className="text-caution-text mt-0.5 shrink-0" />
          <p className="text-sm font-body text-caution-text">{step.safetyNote}</p>
        </div>
      )}
    </div>
  );
}
