"use client";
import { useState } from "react";
import { notFound } from "next/navigation";
import Link from "next/link";
import { AppShell } from "@/components/layout/AppShell";
import { StepCard } from "@/components/cards/StepCard";
import { ProgressStepper } from "@/components/ui/ProgressStepper";
import { Button } from "@/components/ui/Button";
import { projects } from "@/lib/mock-data";
import { ArrowLeft, Pause } from "lucide-react";
import { use } from "react";

export default function BuildPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  const project = projects.find(p => p.id === id);
  if (!project) return notFound();

  return <BuildPageContent projectId={id} />;
}

function BuildPageContent({ projectId }: { projectId: string }) {
  const project = projects.find(p => p.id === projectId)!;
  const [currentStep, setCurrentStep] = useState(0);
  const step = project.steps[currentStep];
  const isLast = currentStep === project.steps.length - 1;

  return (
    <AppShell>
      <div className="max-w-2xl mx-auto">
        <div className="px-4 pt-6 pb-4 flex items-center gap-3">
          <Link href={`/projects/${project.id}`} className="w-9 h-9 bg-white rounded-2xl shadow-card flex items-center justify-center">
            <ArrowLeft size={16} className="text-charcoal-900" />
          </Link>
          <div className="flex-1">
            <p className="text-xs text-walnut-600 font-body">{project.title}</p>
            <ProgressStepper current={currentStep + 1} total={project.steps.length} />
          </div>
        </div>

        <div className="px-4 pb-4">
          <StepCard step={step} />
        </div>

        <div className="px-4 flex gap-3 pb-8">
          <Button
            variant="secondary"
            className="flex-1"
            disabled={currentStep === 0}
            onClick={() => setCurrentStep(s => s - 1)}
          >
            Back
          </Button>
          {isLast ? (
            <Link href={`/build/${project.id}/complete`} className="flex-1">
              <Button variant="primary" className="w-full">
                Complete Build 🎉
              </Button>
            </Link>
          ) : (
            <Button
              variant="primary"
              className="flex-1"
              onClick={() => setCurrentStep(s => s + 1)}
            >
              Next Step →
            </Button>
          )}
        </div>

        <div className="px-4 flex justify-center">
          <Link href={`/projects/${project.id}`} className="inline-flex items-center gap-1.5 text-sm text-walnut-600 hover:text-walnut-800">
            <Pause size={13} />
            Pause Build
          </Link>
        </div>
      </div>
    </AppShell>
  );
}
