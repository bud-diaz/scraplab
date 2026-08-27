import { Button } from "@/components/ui/Button";
import { projects as mockProjects } from "@/lib/mock-data";
import { notFound } from "next/navigation";
import Link from "next/link";
import { createServiceClient } from "@/lib/db/client";
import { getProjectDisplay } from "@/lib/display";

export function generateStaticParams() {
  return mockProjects.map(p => ({ id: p.id }));
}

export default async function CompletePage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const mockProject = mockProjects.find(p => p.id === id);

  let emoji = "🎉";
  let title = "Your Build";

  if (mockProject) {
    emoji = mockProject.emoji;
    title = mockProject.title;
  } else {
    // DB fallback for UUID project IDs
    try {
      const db = createServiceClient();
      const { data: project } = await db
        .from('projects')
        .select('title, slug')
        .or(`id.eq.${id},slug.eq.${id}`)
        .single();

      if (!project) return notFound();
      title = project.title;
      emoji = getProjectDisplay(project.slug).emoji;
    } catch {
      return notFound();
    }
  }

  const confettiDots = [
    "top-6 left-10", "top-10 right-14", "top-20 left-1/4", "top-8 right-1/3",
    "top-16 left-1/2", "top-24 right-10", "top-4 left-2/3", "top-28 left-12",
  ];

  return (
    <div className="min-h-screen bg-scraplab-blue flex flex-col">
      <div className="relative flex-1 flex flex-col items-center justify-center px-6 pt-14 pb-16 text-center overflow-hidden">
        {confettiDots.map((pos, i) => (
          <span
            key={i}
            className={`absolute w-2.5 h-2.5 rounded-full bg-sunshine ${pos}`}
            style={{ opacity: 0.6 + (i % 3) * 0.15 }}
          />
        ))}
        <div className="relative w-24 h-24 bg-white rounded-full flex items-center justify-center text-4xl mb-6 shadow-card-lg">
          {emoji}
        </div>
        <h1 className="relative font-heading font-bold text-3xl text-white mb-2">Built it. Nice.</h1>
        <p className="relative text-base text-white/85 mb-1 font-body">{title}</p>
        <p className="relative text-sm text-white/70 max-w-xs font-body">
          Great work! You just built something awesome from household materials.
        </p>
      </div>

      <div className="bg-cream-50 rounded-t-[32px] px-4 pt-8 pb-8 flex flex-col items-center">
        <div className="bg-white rounded-3xl shadow-card p-4 mb-6 w-full max-w-xs">
          <p className="text-sm font-heading font-medium text-charcoal-800 mb-3 text-center">How was it?</p>
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
    </div>
  );
}
