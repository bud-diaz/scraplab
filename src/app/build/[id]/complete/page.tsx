import { projects as mockProjects } from "@/lib/mock-data";
import { notFound } from "next/navigation";
import { createServiceClient } from "@/lib/db/client";
import { resolveProject } from "@/lib/projects/resolve";
import { getProjectDisplay } from "@/lib/display";
import { CompleteBuildActions } from "@/components/build/CompleteBuildActions";

export function generateStaticParams() {
  return mockProjects.map(p => ({ id: p.id }));
}

export default async function CompletePage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const mockProject = mockProjects.find(p => p.id === id);

  let emoji = "🎉";
  let title = "Your Build";
  // Mock/offline sample builds were never persisted as a real projects.id
  // UUID, so there's nothing a "Save to Library" call could reference.
  let persistedProjectId: string | null = null;

  if (mockProject) {
    emoji = mockProject.emoji;
    title = mockProject.title;
  } else {
    // DB fallback for UUID or slug project identifiers. A malformed
    // identifier is treated as not-found; a genuine DB/config failure
    // propagates instead of silently rendering 404 (see F7).
    let project: { id: string; title: string; slug: string } | null;
    try {
      const db = createServiceClient();
      project = await resolveProject<{ id: string; title: string; slug: string }>(db, id, 'id, title, slug');
    } catch (err) {
      if (err instanceof Error && err.message.startsWith('Invalid project identifier')) return notFound();
      throw err;
    }

    if (!project) return notFound();
    title = project.title;
    emoji = getProjectDisplay(project.slug).emoji;
    persistedProjectId = project.id;
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
        <CompleteBuildActions projectId={persistedProjectId} />
      </div>
    </div>
  );
}
