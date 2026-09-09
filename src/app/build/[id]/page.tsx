"use client";
import { useState, useEffect, useRef } from "react";
import { notFound, useRouter } from "next/navigation";
import Link from "next/link";
import { AppShell } from "@/components/layout/AppShell";
import { StepCard } from "@/components/cards/StepCard";
import { ProgressStepper } from "@/components/ui/ProgressStepper";
import { Button } from "@/components/ui/Button";
import { projects as mockProjects } from "@/lib/mock-data";
import type { BuildStep } from "@/lib/mock-data";
import { useAuth } from "@/lib/auth-context";
import { ArrowLeft, Pause } from "lucide-react";
import { use } from "react";

export default function BuildPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  return <BuildPageContent projectId={id} />;
}

function BuildPageContent({ projectId }: { projectId: string }) {
  const mockProject = mockProjects.find(p => p.id === projectId);
  const { session, loading: authLoading } = useAuth();
  const router = useRouter();

  const [steps, setSteps] = useState<BuildStep[]>(mockProject?.steps ?? []);
  const [projectTitle, setProjectTitle] = useState(mockProject?.title ?? "");
  const [loading, setLoading] = useState(!mockProject);
  const [missing, setMissing] = useState(false);
  const [currentStep, setCurrentStep] = useState(0);
  const [completing, setCompleting] = useState(false);
  const [completeError, setCompleteError] = useState<string | null>(null);
  const fetched = useRef(false);

  // Real (persistable) project id once resolved from the DB — null for
  // mock/offline sample projects, which were never saved as a real
  // projects.id UUID and so can't have build_history persistence.
  const [persistProjectId, setPersistProjectId] = useState<string | null>(null);
  const [buildId, setBuildId] = useState<string | null>(null);
  const startedRef = useRef(false);

  useEffect(() => {
    // Wait for auth to resolve so a signed-in Plus user's request carries
    // their token — fetching before then would hit the API unauthenticated
    // and get back a redacted (preview-only) premium project.
    if (mockProject || fetched.current || authLoading) return;
    fetched.current = true;

    fetch(`/api/projects/${projectId}`, {
      headers: session ? { Authorization: `Bearer ${session.access_token}` } : {},
    })
      .then(r => r.ok ? r.json() : Promise.reject(new Error(`HTTP ${r.status}`)))
      .then(({ project: p }) => {
        if (!p?.instructions?.length) { setMissing(true); return; }
        setProjectTitle(p.title);
        setPersistProjectId(p.id);
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
  }, [authLoading]); // eslint-disable-line react-hooks/exhaustive-deps

  // Start-or-resume the persisted build once we know a real project id and
  // the user is signed in. Guests keep working in local-only state.
  useEffect(() => {
    if (!persistProjectId || !session || startedRef.current) return;
    startedRef.current = true;

    fetch('/api/build-history', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${session.access_token}`,
      },
      body: JSON.stringify({ projectId: persistProjectId }),
    })
      .then(r => (r.ok ? r.json() : null))
      .then(data => {
        if (!data?.buildEntry) return;
        setBuildId(data.buildEntry.id);
        if (typeof data.buildEntry.current_step === 'number') {
          setCurrentStep(Math.min(data.buildEntry.current_step, Math.max(steps.length - 1, 0)));
        }
      })
      .catch(() => {});
    // steps.length is intentionally omitted: this should only ever fire once
    // per resolved project, using whatever step count is loaded by then.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [persistProjectId, session]);

  const patchProgress = (patch: { currentStep?: number; completionStatus?: 'abandoned' | 'completed' }) => {
    if (!buildId || !session) return Promise.resolve(false);
    return fetch(`/api/build-history/${buildId}`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${session.access_token}`,
      },
      body: JSON.stringify(patch),
    }).then(r => r.ok).catch(() => false);
  };

  const goToStep = (next: number) => {
    setCurrentStep(next);
    patchProgress({ currentStep: next });
  };

  const handlePause = () => {
    patchProgress({ completionStatus: 'abandoned' });
  };

  const handleComplete = async () => {
    if (!buildId || !session) {
      router.push(`/build/${projectId}/complete`);
      return;
    }
    setCompleting(true);
    setCompleteError(null);
    const ok = await patchProgress({ currentStep, completionStatus: 'completed' });
    setCompleting(false);
    if (ok) {
      router.push(`/build/${projectId}/complete`);
    } else {
      setCompleteError("Couldn't save your completion — try again.");
    }
  };

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

        {completeError && (
          <p className="px-4 pb-2 text-center text-xs text-coral-text font-body">{completeError}</p>
        )}

        <div className="px-4 flex gap-3 pb-8">
          <Button
            variant="secondary"
            className="flex-1"
            disabled={currentStep === 0}
            onClick={() => goToStep(currentStep - 1)}
          >
            Back
          </Button>
          {isLast ? (
            <Button variant="primary" className="flex-1" onClick={handleComplete} disabled={completing}>
              {completing ? 'Saving…' : 'Complete Build 🎉'}
            </Button>
          ) : (
            <Button variant="primary" className="flex-1" onClick={() => goToStep(currentStep + 1)}>
              Next Step →
            </Button>
          )}
        </div>

        <div className="px-4 flex justify-center">
          <Link
            href={`/projects/${projectId}`}
            onClick={handlePause}
            className="inline-flex items-center gap-1.5 text-sm text-walnut-600 hover:text-walnut-800"
          >
            <Pause size={13} />
            Pause Build
          </Link>
        </div>
      </div>
    </AppShell>
  );
}
