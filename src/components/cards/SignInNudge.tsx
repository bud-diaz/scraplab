"use client";
import Link from "next/link";
import { useAuth } from "@/lib/auth-context";

export function SignInNudge() {
  const { user, loading } = useAuth();
  if (loading || user) return null;

  return (
    <div className="mx-4 mt-4 bg-builder-500/10 border border-builder-500/20 rounded-2xl px-4 py-3 flex items-center justify-between gap-3">
      <p className="text-sm text-charcoal-800 font-body leading-snug">
        Sign in for personalized recommendations and saved builds.
      </p>
      <Link
        href="/auth"
        className="text-sm text-builder-500 font-heading font-semibold whitespace-nowrap hover:text-builder-600 transition-colors"
      >
        Sign in →
      </Link>
    </div>
  );
}
