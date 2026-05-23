"use client";
import { useState, useEffect, useRef } from "react";
import { notFound } from "next/navigation";
import Link from "next/link";
import { AppShell } from "@/components/layout/AppShell";
import { StepCard } from "@/components/cards/StepCard";
import { ProgressStepper } from "@/components/ui/ProgressStepper";
import { Button } from "@/components/ui/Button";
import { projects as mockProjects } from "@/lib/mock-data";
import type { BuildStep } from "@/lib/mock-data";
import { ArrowLeft, Pause } from "lucide-react";
import { use } from "react";

export default function BuildPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  return <BuildPageContent projectId={id} />;
}

function BuildPageContent({ projectId }: { projectId: string }) {
  const mockProject = mockProjects.find(p => p.id === projectId);

  const [steps, setSteps] = useState<BuildStep[]>(mockProject?.steps ?? []);
  const [projectTitle, setProjectTitle] = useState(mockProject?.title ?? "");
  const [loading, setLoading] = useState(!mockProject);
  const [missing, setMissing] = useState(false);
  const [currentStep, setCurrentStep] = useState(0);
  const fetched = useRef(false);

  useEffect(() => {
    if (mockProject || fetched.current) return;
    fetched.current = true;

    fetch(`/api/projects/${projectId}`)
      .then(r => r.ok ? r.json() : Promise.reject(new Error(`HTTP ${r.status}`)))
      .then(({ project: p }) => {
        if (!p?.instructions?.length) { setMissing(true); return; }
        setProjectTitle(p.title);
        setSteps(
          // eslint-disable-next-line @typescript-eslint/no-explicit-any
          p.instructions.map((s: any) => ({
            id: s.step,
            title: `Step ${s.step}`,
            instruction: s.instruction,
            tip: s.tip,
            safetyNote: s.safety_note,
          }))
        );
      })
      .catch(() => setMissing(true))
      .finally(() => setLoading(false));
  }, []); // eslint-disable-line react-hooks/exhaustive-deps

  if (loading) {
    return (
      <AppShell>
        <div className="p-8 text-center text-walnut-600">Loading build…</div>
      </AppShell>
    );
  }

  if (missing || steps.length === 0) return notFound();

  const step = steps[currentStep];
  const isLast = currentStep === steps.length - 1;

  return (
    <AppShell>
      <div className="max-w-2xl mx-auto">
        <div className="px-4 pt-6 pb-4 flex items-center gap-3">
          <Link href={`/projects/${projectId}`} className="w-9 h-9 bg-white rounded-2xl shadow-card flex items-center justify-center">
            <ArrowLeft size={16} className="text-charcoal-900" />
          </Link>
          <div className="flex-1">
            <p className="text-xs text-walnut-600 font-body">{projectTitle}</p>
            <ProgressStepper current={currentStep + 1} total={steps.length} />
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
            <Link href={`/build/${projectId}/complete`} className="flex-1">
              <Button variant="primary" className="w-full">Complete Build 🎉</Button>
            </Link>
          ) : (
            <Button variant="primary" className="flex-1" onClick={() => setCurrentStep(s => s + 1)}>
              Next Step →
            </Button>
          )}
        </div>

        <div className="px-4 flex justify-center">
          <Link href={`/projects/${projectId}`} className="inline-flex items-center gap-1.5 text-sm text-walnut-600 hover:text-walnut-800">
            <Pause size={13} />
            Pause Build
          </Link>
        </div>
      </div>
    </AppShell>
  );
}
