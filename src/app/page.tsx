import { AppShell } from "@/components/layout/AppShell";
import { HeroActionCard } from "@/components/cards/HeroActionCard";
import { ProjectCard } from "@/components/cards/ProjectCard";
import { QuickActions } from "@/components/cards/QuickActions";
import { SignInNudge } from "@/components/cards/SignInNudge";
import { projects } from "@/lib/mock-data";
import Link from "next/link";
import { ArrowRight } from "lucide-react";

export default function Home() {
  return (
    <AppShell>
      <div className="max-w-2xl mx-auto">
        <div className="px-4 pt-6 pb-3">
          <p className="text-walnut-600 text-sm font-body">Good morning 👋</p>
          <h1 className="font-heading font-bold text-2xl text-charcoal-900">Let&apos;s build something.</h1>
        </div>

        <SignInNudge />
        <HeroActionCard />

        <div className="px-4 mt-6">
          <h2 className="font-heading font-semibold text-base text-charcoal-900 mb-3">How do you want to start?</h2>
          <QuickActions />
        </div>

        <div className="px-4 mt-8">
          <div className="flex items-center justify-between mb-3">
            <h2 className="font-heading font-semibold text-base text-charcoal-900">Popular Builds</h2>
            <Link href="/library" className="text-sm text-builder-500 font-heading font-medium flex items-center gap-0.5">
              See all <ArrowRight size={13} />
            </Link>
          </div>
          <div className="grid grid-cols-2 gap-3">
            {projects.slice(0, 4).map(project => (
              <ProjectCard key={project.id} project={project} />
            ))}
          </div>
        </div>

        <div className="mx-4 mt-6 bg-white rounded-3xl shadow-card p-5 border border-kraft-300">
          <div className="flex items-start gap-3">
            <span className="text-2xl">🏆</span>
            <div>
              <p className="text-xs font-heading font-semibold text-orange-500 uppercase tracking-wide mb-0.5">This Week</p>
              <h3 className="font-heading font-semibold text-base text-charcoal-900 mb-1">Weekend Build Challenge</h3>
              <p className="text-sm text-walnut-600 mb-3">Build something that can carry 5 things using only recyclables.</p>
              <Link href="/challenges" className="text-sm text-builder-500 font-heading font-semibold flex items-center gap-1">
                See challenge <ArrowRight size={13} />
              </Link>
            </div>
          </div>
        </div>

        <div className="h-8" />
      </div>
    </AppShell>
  );
}
