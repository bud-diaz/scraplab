import { AppShell } from "@/components/layout/AppShell";
import { Button } from "@/components/ui/Button";
import { projects } from "@/lib/mock-data";
import { notFound } from "next/navigation";
import Link from "next/link";

export function generateStaticParams() {
  return projects.map(p => ({ id: p.id }));
}

export default async function CompletePage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const project = projects.find(p => p.id === id);
  if (!project) return notFound();

  return (
    <AppShell>
      <div className="max-w-2xl mx-auto flex flex-col items-center justify-center min-h-[80vh] px-4 text-center">
        <div className="w-24 h-24 bg-gradient-to-br from-orange-400 to-orange-500 rounded-full flex items-center justify-center text-4xl mb-6 shadow-card-lg">
          {project.emoji}
        </div>
        <h1 className="font-heading font-bold text-3xl text-charcoal-900 mb-2">Built it. Nice.</h1>
        <p className="text-base text-walnut-600 mb-2 font-body">{project.title}</p>
        <p className="text-sm text-walnut-500 mb-8 max-w-xs font-body">
          Great work! You just built something awesome from household materials.
        </p>

        <div className="bg-cream-100 rounded-3xl p-4 mb-8 w-full max-w-xs">
          <p className="text-sm font-heading font-medium text-charcoal-800 mb-3">How was it?</p>
          <div className="flex gap-2 justify-center">
            {["😅 Too Hard", "👍 Just Right", "⚡ Too Easy"].map(label => (
              <button
                key={label}
                className="flex-1 text-xs bg-white border border-kraft-300 rounded-xl py-2 font-heading font-medium text-walnut-700 hover:border-builder-500 hover:text-builder-500 transition-colors"
              >
                {label}
              </button>
            ))}
          </div>
        </div>

        <div className="flex flex-col gap-3 w-full max-w-xs">
          <Link href="/library" className="block">
            <Button variant="primary" className="w-full" size="lg">Save to Library</Button>
          </Link>
          <Link href="/create/manual" className="block">
            <Button variant="secondary" className="w-full" size="lg">Build Something Else</Button>
          </Link>
        </div>
      </div>
    </AppShell>
  );
}
