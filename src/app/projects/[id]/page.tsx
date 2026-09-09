import { notFound } from "next/navigation";
import { AppShell } from "@/components/layout/AppShell";
import { MaterialsChecklist } from "@/components/ui/MaterialsChecklist";
import { ShareProjectButton } from "@/components/ui/ShareProjectButton";
import { MetadataChip } from "@/components/ui/MetadataChip";
import { SupervisionBadge } from "@/components/ui/SupervisionBadge";
import { Button } from "@/components/ui/Button";
import { projects as mockProjects } from "@/lib/mock-data";
import { Clock, Trash2, Users, BarChart2, ArrowLeft } from "lucide-react";
import Link from "next/link";
import { cn } from "@/lib/utils";
import { createServiceClient } from "@/lib/db/client";
import { resolveProject } from "@/lib/projects/resolve";
import { toDisplayProject } from "@/lib/display";
import type { DisplayProject } from "@/lib/display";

export function generateStaticParams() {
  return mockProjects.map(p => ({ id: p.id }));
}

interface DBProjectData {
  projectId: string
  display: DisplayProject
  required: string[]
  optional: string[]
  allMaterials: Array<{ id: string; name: string; icon: string | null }>
  substitutions: Record<string, string>
  instructions: Array<{ step: number; instruction: string }>
}

async function fetchDBProject(id: string): Promise<DBProjectData | null> {
  const db = createServiceClient();
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  let project: any;
  try {
    project = await resolveProject(
      db,
      id,
      '*, project_materials(material_id, required, quantity_note, material:materials(id, name, icon))'
    );
  } catch (err) {
    // A malformed identifier (never a valid id/slug shape) is effectively
    // "not found"; any other error is a real DB/config failure that should
    // surface via the nearest error boundary rather than render as 404.
    if (err instanceof Error && err.message.startsWith('Invalid project identifier')) return null;
    throw err;
  }

  if (!project) return null;

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const pm = project.project_materials as Array<{ material_id: string; required: boolean; material: any }>;
  const materialIds = pm.map(p => p.material_id);

  const { data: subs } = await db
    .from('material_substitutions')
    .select('source_material_id, substitution_notes')
    .in('source_material_id', materialIds);

  return {
    projectId: project.id,
    display: toDisplayProject(project),
    required: pm.filter(p => p.required).map(p => p.material_id),
    optional: pm.filter(p => !p.required).map(p => p.material_id),
    allMaterials: pm.map(p => p.material).filter(Boolean),
    substitutions: Object.fromEntries(
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      (subs ?? []).map((s: any) => [s.source_material_id, s.substitution_notes ?? ''])
    ),
    instructions: (project.instructions ?? []) as Array<{ step: number; instruction: string }>,
  }
}

export default async function ProjectDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;

  // Try mock data first (covers home page and library links)
  const mockProject = mockProjects.find(p => p.id === id);
  if (mockProject) {
    return (
      <AppShell>
        <div className="max-w-2xl mx-auto">
          <div className={cn("relative h-48 flex items-center justify-center", mockProject.bgColor)}>
            <Link href="/create/results" className="absolute top-4 left-4 w-9 h-9 bg-white/80 rounded-2xl flex items-center justify-center">
              <ArrowLeft size={16} className="text-charcoal-900" />
            </Link>
            <ShareProjectButton
              title={mockProject.title}
              text={`Check out this build on ScrapLab: ${mockProject.title}`}
              className="absolute top-4 right-4 w-9 h-9 bg-white/80 rounded-2xl flex items-center justify-center"
            />
            <span className="text-7xl">{mockProject.emoji}</span>
          </div>
          <div className="px-4 py-5">
            <h1 className="font-heading font-bold text-2xl text-charcoal-900 mb-1">{mockProject.title}</h1>
            <p className="text-sm text-walnut-600 mb-4 font-body">{mockProject.description}</p>
            <div className="flex flex-wrap gap-2 mb-6">
              <MetadataChip icon={<Clock size={11} />} label={mockProject.timeEstimate} />
              <MetadataChip icon={<Trash2 size={11} />} label={mockProject.cleanupLevel + " mess"} />
              <MetadataChip icon={<Users size={11} />} label={"Ages " + mockProject.ageRange} />
              <SupervisionBadge level={mockProject.supervisionLevel} />
              <MetadataChip icon={<BarChart2 size={11} />} label={mockProject.difficulty} />
            </div>
            <div className="bg-white rounded-3xl shadow-card p-5 mb-4">
              <h2 className="font-heading font-semibold text-base text-charcoal-900 mb-4">Materials Needed</h2>
              <MaterialsChecklist
                requiredMaterials={mockProject.requiredMaterials}
                optionalMaterials={mockProject.optionalMaterials}
                substitutions={mockProject.substitutions}
              />
            </div>
            <div className="bg-white rounded-3xl shadow-card p-5 mb-6">
              <h2 className="font-heading font-semibold text-base text-charcoal-900 mb-3">
                Build Steps <span className="text-walnut-500 font-body font-normal text-sm">({mockProject.steps.length} steps)</span>
              </h2>
              <div className="space-y-3">
                {mockProject.steps.slice(0, 3).map((step, i) => (
                  <div key={step.id} className="flex items-start gap-3">
                    <div className="w-6 h-6 bg-builder-500 rounded-full flex items-center justify-center text-white text-xs font-heading font-bold shrink-0 mt-0.5">
                      {i + 1}
                    </div>
                    <p className="text-sm font-body text-charcoal-800 leading-relaxed">{step.title}</p>
                  </div>
                ))}
                {mockProject.steps.length > 3 && (
                  <p className="text-xs text-walnut-500 ml-9">+ {mockProject.steps.length - 3} more steps</p>
                )}
              </div>
            </div>
            <Link href={`/build/${mockProject.id}`} className="block">
              <Button variant="primary" size="lg" className="w-full">Start Build →</Button>
            </Link>
          </div>
        </div>
      </AppShell>
    );
  }

  // DB fallback: handles UUIDs and DB slugs from recommendation results.
  // A real DB/config failure here throws and hits the nearest error
  // boundary instead of masquerading as notFound() (see F7 in the
  // endpoint audit) — only a genuinely missing row renders 404.
  const data = await fetchDBProject(id);

  if (!data) return notFound();

  const { projectId, display, required, optional, allMaterials, substitutions, instructions } = data;

  return (
    <AppShell>
      <div className="max-w-2xl mx-auto">
        <div className={cn("relative h-48 flex items-center justify-center", display.bgColor)}>
          <Link href="/create/results" className="absolute top-4 left-4 w-9 h-9 bg-white/80 rounded-2xl flex items-center justify-center">
            <ArrowLeft size={16} className="text-charcoal-900" />
          </Link>
          <ShareProjectButton
            title={display.title}
            text={`Check out this build on ScrapLab: ${display.title}`}
            className="absolute top-4 right-4 w-9 h-9 bg-white/80 rounded-2xl flex items-center justify-center"
          />
          <span className="text-7xl">{display.emoji}</span>
        </div>
        <div className="px-4 py-5">
          <h1 className="font-heading font-bold text-2xl text-charcoal-900 mb-1">{display.title}</h1>
          <p className="text-sm text-walnut-600 mb-4 font-body">{display.description}</p>
          <div className="flex flex-wrap gap-2 mb-6">
            <MetadataChip icon={<Clock size={11} />} label={display.timeEstimate} />
            <MetadataChip icon={<Trash2 size={11} />} label={display.cleanupLevel + " mess"} />
            <MetadataChip icon={<Users size={11} />} label={"Ages " + display.ageRange} />
            <SupervisionBadge level={display.supervisionLevelRaw} />
            <MetadataChip icon={<BarChart2 size={11} />} label={display.difficulty} />
          </div>
          <div className="bg-white rounded-3xl shadow-card p-5 mb-4">
            <h2 className="font-heading font-semibold text-base text-charcoal-900 mb-4">Materials Needed</h2>
            <MaterialsChecklist
              requiredMaterials={required}
              optionalMaterials={optional}
              substitutions={substitutions}
              allMaterials={allMaterials}
            />
          </div>
          <div className="bg-white rounded-3xl shadow-card p-5 mb-6">
            <h2 className="font-heading font-semibold text-base text-charcoal-900 mb-3">
              Build Steps <span className="text-walnut-500 font-body font-normal text-sm">({instructions.length} steps)</span>
            </h2>
            <div className="space-y-3">
              {instructions.slice(0, 3).map((step, i) => (
                <div key={step.step} className="flex items-start gap-3">
                  <div className="w-6 h-6 bg-builder-500 rounded-full flex items-center justify-center text-white text-xs font-heading font-bold shrink-0 mt-0.5">
                    {i + 1}
                  </div>
                  <p className="text-sm font-body text-charcoal-800 leading-relaxed">{step.instruction}</p>
                </div>
              ))}
              {instructions.length > 3 && (
                <p className="text-xs text-walnut-500 ml-9">+ {instructions.length - 3} more steps</p>
              )}
            </div>
          </div>
          <Link href={`/build/${projectId}`} className="block">
            <Button variant="primary" size="lg" className="w-full">Start Build →</Button>
          </Link>
        </div>
      </div>
    </AppShell>
  );
}
