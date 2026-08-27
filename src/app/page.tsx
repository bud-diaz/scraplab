import { AppShell } from "@/components/layout/AppShell";
import { GreetingRow } from "@/components/cards/GreetingRow";
import { WeeklyProgress } from "@/components/cards/WeeklyProgress";
import { QuickNavRow } from "@/components/cards/QuickNavRow";
import { ContinueBuilding } from "@/components/cards/ContinueBuilding";
import { HouseholdStaples } from "@/components/cards/HouseholdStaples";
import { ProjectCard } from "@/components/cards/ProjectCard";
import { SignInNudge } from "@/components/cards/SignInNudge";
import { projects } from "@/lib/mock-data";
import Link from "next/link";
import { ArrowRight } from "lucide-react";

// Home dashboard — new_scraplab-design-spec.md §4.2, in the order the spec
// lays out: greeting, progress module, icon quick-nav, then the content
// shelves. "Continue Building" and "Household Staples" render only when the
// signed-in user actually has something there.
export default function Home() {
  return (
    <AppShell>
      <div className="mx-auto max-w-2xl">
        <GreetingRow />
        <SignInNudge />

        <div className="mt-2">
          <WeeklyProgress />
        </div>

        <div className="mt-6">
          <QuickNavRow />
        </div>

        <section className="mt-8">
          <div className="mb-3 flex items-center justify-between px-4">
            <h2 className="font-heading text-base font-semibold text-charcoal-900">
              Suggested For You
            </h2>
            <Link
              href="/explore"
              className="flex items-center gap-0.5 font-heading text-sm font-medium text-builder-500"
            >
              See all <ArrowRight size={13} aria-hidden />
            </Link>
          </div>

          {/* Horizontal scroll rather than a grid, per §4.2. */}
          <ul className="flex snap-x snap-mandatory gap-3 overflow-x-auto px-4 pb-2">
            {projects.slice(0, 6).map((project) => (
              <li key={project.id} className="w-44 shrink-0 snap-start">
                <ProjectCard project={project} />
              </li>
            ))}
          </ul>
        </section>

        <ContinueBuilding />
        <HouseholdStaples />

        <div className="h-8" />
      </div>
    </AppShell>
  );
}
