import { notFound } from "next/navigation";
import { AppShell } from "@/components/layout/AppShell";
import { MaterialsChecklist } from "@/components/ui/MaterialsChecklist";
import { MetadataChip } from "@/components/ui/MetadataChip";
import { Button } from "@/components/ui/Button";
import { projects } from "@/lib/mock-data";
import { Clock, Trash2, Users, Shield, BarChart2, ArrowLeft } from "lucide-react";
import Link from "next/link";
import { cn } from "@/lib/utils";

export function generateStaticParams() {
  return projects.map(p => ({ id: p.id }));
}

export default async function ProjectDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const project = projects.find(p => p.id === id);
  if (!project) return notFound();

  return (
    <AppShell>
      <div className="max-w-2xl mx-auto">
        <div className={cn("relative h-48 flex items-center justify-center", project.bgColor)}>
          <Link href="/create/results" className="absolute top-4 left-4 w-9 h-9 bg-white/80 rounded-2xl flex items-center justify-center">
            <ArrowLeft size={16} className="text-charcoal-900" />
          </Link>
          <span className="text-7xl">{project.emoji}</span>
        </div>

        <div className="px-4 py-5">
          <h1 className="font-heading font-bold text-2xl text-charcoal-900 mb-1">{project.title}</h1>
          <p className="text-sm text-walnut-600 mb-4 font-body">{project.description}</p>

          <div className="flex flex-wrap gap-2 mb-6">
            <MetadataChip icon={<Clock size={11} />} label={project.timeEstimate} />
            <MetadataChip icon={<Trash2 size={11} />} label={project.cleanupLevel + " mess"} />
            <MetadataChip icon={<Users size={11} />} label={"Ages " + project.ageRange} />
            <MetadataChip icon={<Shield size={11} />} label={project.supervisionLevel} />
            <MetadataChip icon={<BarChart2 size={11} />} label={project.difficulty} />
          </div>

          <div className="bg-white rounded-3xl shadow-card p-5 mb-4">
            <h2 className="font-heading font-semibold text-base text-charcoal-900 mb-4">Materials Needed</h2>
            <MaterialsChecklist
              requiredMaterials={project.requiredMaterials}
              optionalMaterials={project.optionalMaterials}
              substitutions={project.substitutions}
            />
          </div>

          <div className="bg-white rounded-3xl shadow-card p-5 mb-6">
            <h2 className="font-heading font-semibold text-base text-charcoal-900 mb-3">
              Build Steps <span className="text-walnut-500 font-body font-normal text-sm">({project.steps.length} steps)</span>
            </h2>
            <div className="space-y-3">
              {project.steps.slice(0, 3).map((step, i) => (
                <div key={step.id} className="flex items-start gap-3">
                  <div className="w-6 h-6 bg-builder-500 rounded-full flex items-center justify-center text-white text-xs font-heading font-bold shrink-0 mt-0.5">
                    {i + 1}
                  </div>
                  <p className="text-sm font-body text-charcoal-800 leading-relaxed">{step.title}</p>
                </div>
              ))}
              {project.steps.length > 3 && (
                <p className="text-xs text-walnut-500 ml-9">+ {project.steps.length - 3} more steps</p>
              )}
            </div>
          </div>

          <Link href={`/build/${project.id}`} className="block">
            <Button variant="primary" size="lg" className="w-full">
              Start Build →
            </Button>
          </Link>
        </div>
      </div>
    </AppShell>
  );
}
