"use client";
import { useEffect, useState } from "react";
import Link from "next/link";
import { ArrowRight } from "lucide-react";
import { useAuth } from "@/lib/auth-context";
import { getProjectDisplay } from "@/lib/display";

interface BuildRow {
  id: string;
  completion_status?: string;
  project?: { id?: string; title?: string; slug?: string } | null;
}

/**
 * "Continue Building" — new_scraplab-design-spec.md §4.2.
 *
 * In-progress builds with their step progress. Renders nothing at all when
 * there is nothing in progress: an empty shelf on the dashboard is noise, and
 * the spec's §6 warning about a visually loud everyday screen applies.
 */
export function ContinueBuilding() {
  const { session } = useAuth();
  const [rows, setRows] = useState<BuildRow[]>([]);

  useEffect(() => {
    if (!session) return;
    let cancelled = false;
    fetch("/api/build-history", {
      headers: { Authorization: `Bearer ${session.access_token}` },
    })
      .then((r) => (r.ok ? r.json() : null))
      .then((data) => {
        if (cancelled || !data) return;
        const all: BuildRow[] = data.buildHistory ?? [];
        setRows(all.filter((b) => b.completion_status === "started").slice(0, 3));
      })
      .catch(() => {});
    return () => {
      cancelled = true;
    };
  }, [session]);

  if (rows.length === 0) return null;

  return (
    <section className="mt-8 px-4">
      <h2 className="mb-3 font-heading text-base font-semibold text-charcoal-900">
        Continue Building
      </h2>
      <ul className="space-y-2.5">
        {rows.map((b) => {
          const title = b.project?.title ?? "Your build";
          const display = getProjectDisplay(b.project?.slug ?? "");
          return (
            <li key={b.id}>
              <Link
                href={`/build/${b.project?.id ?? b.id}`}
                className="flex items-center gap-3 rounded-3xl border border-kraft-300 bg-white p-3 shadow-card transition-shadow hover:shadow-card-hover"
              >
                <span className="flex h-12 w-12 shrink-0 items-center justify-center rounded-2xl bg-cream-100 text-2xl">
                  {display.emoji}
                </span>
                <span className="min-w-0 flex-1">
                  <span className="block truncate font-heading text-sm font-semibold text-charcoal-900">
                    {title}
                  </span>
                  <span className="block font-body text-xs text-walnut-600">
                    In progress
                  </span>
                </span>
                <ArrowRight size={15} className="shrink-0 text-builder-500" aria-hidden />
              </Link>
            </li>
          );
        })}
      </ul>
    </section>
  );
}
