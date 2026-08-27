"use client";
import { useEffect, useState } from "react";
import Link from "next/link";
import { useAuth } from "@/lib/auth-context";

interface InventoryRow {
  material_id: string;
  staple_flag: boolean;
  material?: { id?: string; name?: string; icon?: string } | null;
}

/**
 * "Household Staples" — new_scraplab-design-spec.md §4.2.
 *
 * Quick-access chips for the materials already flagged as staples, so the
 * inventory-first flow starts from the dashboard. Same source the material
 * picker reads (/api/household-inventory, staple_flag).
 */
export function HouseholdStaples() {
  const { session } = useAuth();
  const [staples, setStaples] = useState<InventoryRow[]>([]);

  useEffect(() => {
    if (!session) return;
    let cancelled = false;
    fetch("/api/household-inventory", {
      headers: { Authorization: `Bearer ${session.access_token}` },
    })
      .then((r) => (r.ok ? r.json() : null))
      .then((data) => {
        if (cancelled || !data) return;
        const rows: InventoryRow[] = data.inventory ?? [];
        setStaples(rows.filter((i) => i.staple_flag).slice(0, 8));
      })
      .catch(() => {});
    return () => {
      cancelled = true;
    };
  }, [session]);

  if (staples.length === 0) return null;

  const query = staples.map((s) => `materials=${encodeURIComponent(s.material_id)}`).join("&");

  return (
    <section className="mt-8 px-4">
      <div className="mb-3 flex items-center justify-between gap-3">
        <h2 className="font-heading text-base font-semibold text-charcoal-900">
          Household Staples
        </h2>
        <Link
          href="/create/manual"
          className="font-heading text-sm font-medium text-builder-500 hover:text-builder-600"
        >
          Edit
        </Link>
      </div>

      <ul className="flex flex-wrap gap-2">
        {staples.map((s) => (
          <li
            key={s.material_id}
            className="rounded-full bg-white px-3.5 py-1.5 font-body text-sm text-walnut-700 shadow-card"
          >
            {s.material?.icon ? `${s.material.icon} ` : ""}
            {s.material?.name ?? "Material"}
          </li>
        ))}
      </ul>

      <Link
        href={`/create/results?${query}`}
        className="mt-3 inline-block font-heading text-sm font-semibold text-builder-500 hover:text-builder-600"
      >
        Find builds with these →
      </Link>
    </section>
  );
}
