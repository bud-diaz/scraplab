"use client";
import { useEffect, useState } from "react";
import { useAuth } from "@/lib/auth-context";

const WEEKLY_GOAL = 5;

interface BuildRow {
  completion_status?: string;
  completed_at?: string | null;
}

/**
 * Weekly progress module — new_scraplab-design-spec.md §4.2.
 *
 * The spec is explicit that this panel is the blue/purple one, not orange:
 * Craft Orange is reserved for CTAs and active states (§2), so an orange panel
 * on the everyday dashboard is exactly the visual fatigue §6 warns about.
 */
export function WeeklyProgress() {
  const { session } = useAuth();
  const [count, setCount] = useState<number | null>(null);

  useEffect(() => {
    if (!session) return;
    let cancelled = false;
    fetch("/api/build-history", {
      headers: { Authorization: `Bearer ${session.access_token}` },
    })
      .then((r) => (r.ok ? r.json() : null))
      .then((data) => {
        if (cancelled || !data) return;
        const since = Date.now() - 7 * 24 * 60 * 60 * 1000;
        const rows: BuildRow[] = data.buildHistory ?? [];
        setCount(
          rows.filter(
            (b) =>
              b.completion_status === "completed" &&
              b.completed_at &&
              new Date(b.completed_at).getTime() >= since
          ).length
        );
      })
      .catch(() => {
        // Leave the count null: the module shows its zero state rather than
        // an invented number.
      });
    return () => {
      cancelled = true;
    };
  }, [session]);

  // Rendered unconditionally rather than gated on auth loading: the panel is
  // part of the dashboard's structure and reads correctly at zero, so a slow
  // or failed session lookup must not make it vanish.
  const done = count ?? 0;
  const pct = Math.min(100, Math.round((done / WEEKLY_GOAL) * 100));

  return (
    <div className="mx-4 rounded-3xl bg-scraplab-blue p-5 text-white shadow-card-lg">
      <div className="flex items-baseline justify-between gap-3">
        <p className="font-heading text-sm font-semibold text-white/80">This week</p>
        <p className="font-body text-xs tabular text-white/70">
          Goal {WEEKLY_GOAL}
        </p>
      </div>

      <p className="mt-1 font-heading text-2xl font-bold">
        <span className="tabular">{done}</span>{" "}
        {done === 1 ? "build" : "builds"} completed
      </p>

      <div
        className="mt-4 h-2 w-full overflow-hidden rounded-full bg-white/20"
        role="progressbar"
        aria-valuenow={done}
        aria-valuemin={0}
        aria-valuemax={WEEKLY_GOAL}
        aria-label="Builds completed this week"
      >
        <div
          className="h-full rounded-full bg-sunshine transition-all duration-500"
          style={{ width: `${pct}%` }}
        />
      </div>

      <p className="mt-3 font-body text-xs text-white/75">
        {!session
          ? "Sign in to track your weekly builds."
          : done === 0
            ? "Nothing built yet this week — pick a project to get started."
            : done >= WEEKLY_GOAL
              ? "Weekly goal reached. Nice work."
              : `${WEEKLY_GOAL - done} to go this week.`}
      </p>
    </div>
  );
}
