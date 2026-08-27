"use client";
import Link from "next/link";
import { Bell } from "lucide-react";
import { useAuth } from "@/lib/auth-context";

/**
 * Dashboard greeting row — new_scraplab-design-spec.md §4.2:
 * avatar, "Hello, [Name]", and the notification bell.
 */
export function GreetingRow() {
  const { user } = useAuth();

  const email = user?.email ?? "";
  const name = email ? email.split("@")[0] : null;
  const initial = (name ?? "S").charAt(0).toUpperCase();

  return (
    <div className="flex items-center gap-3 px-4 pb-3 pt-6">
      <Link
        href="/profile"
        aria-label="Your profile"
        className="flex h-11 w-11 shrink-0 items-center justify-center rounded-full bg-scraplab-blue font-heading text-base font-bold text-white"
      >
        {initial}
      </Link>

      <div className="min-w-0 flex-1">
        <p className="font-body text-sm text-walnut-600">
          {name ? `Hello, ${name}` : "Hello"}
        </p>
        <h1 className="font-heading text-2xl font-bold leading-tight text-charcoal-900">
          Let&apos;s build something.
        </h1>
      </div>

      <Link
        href="/challenges"
        aria-label="Notifications"
        className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-white shadow-card"
      >
        <Bell size={17} className="text-walnut-700" aria-hidden />
      </Link>
    </div>
  );
}
