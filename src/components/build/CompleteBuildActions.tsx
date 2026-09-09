"use client";
import { useState } from "react";
import Link from "next/link";
import { Button } from "@/components/ui/Button";
import { useAuth } from "@/lib/auth-context";
import { isUuid } from "@/lib/validation/identifiers";

interface CompleteBuildActionsProps {
  /** Real projects.id UUID, or null for a mock/offline sample project that
   * was never persisted and so can't be saved to the library. */
  projectId: string | null;
}

export function CompleteBuildActions({ projectId }: CompleteBuildActionsProps) {
  const { session } = useAuth();
  const [saved, setSaved] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const savable = !!projectId && isUuid(projectId) && !!session;

  const handleSave = async () => {
    if (!savable || saving || saved) return;
    setSaving(true);
    setError(null);
    try {
      const res = await fetch("/api/saved-projects", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${session!.access_token}`,
        },
        body: JSON.stringify({ projectId }),
      });
      if (res.ok || res.status === 409) {
        setSaved(true);
      } else if (res.status === 429) {
        setError("Save limit reached — upgrade to Plus for unlimited saves");
      } else if (res.status === 401) {
        setError("Sign in to save to your library");
      } else {
        setError("Could not save — try again");
      }
    } catch {
      setError("Network error — try again");
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="flex flex-col gap-3 w-full max-w-xs">
      {savable ? (
        <Button variant="primary" className="w-full" size="lg" onClick={handleSave} disabled={saving || saved}>
          {saved ? "Saved to Library ✓" : saving ? "Saving…" : "Save to Library"}
        </Button>
      ) : (
        <Link href="/library" className="block">
          <Button variant="primary" className="w-full" size="lg">Go to Library</Button>
        </Link>
      )}
      {error && <p className="text-center text-xs text-coral-text font-body">{error}</p>}
      <Link href="/create/manual" className="block">
        <Button variant="secondary" className="w-full" size="lg">Build Something Else</Button>
      </Link>
    </div>
  );
}
