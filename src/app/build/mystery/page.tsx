"use client";
import { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import { AppShell } from "@/components/layout/AppShell";
import { Button } from "@/components/ui/Button";
import { UpgradeCard } from "@/components/ui/UpgradeCard";
import { useAuth } from "@/lib/auth-context";
import { Shuffle, Loader2 } from "lucide-react";

interface Material {
  id: string;
  name: string;
  icon: string | null;
}

export default function MysteryBuildPage() {
  const { session } = useAuth();
  const router = useRouter();

  // null = not yet fetched; [] = fetched but empty
  const [materials, setMaterials] = useState<Material[] | null>(null);
  const [upgradeRequired, setUpgradeRequired] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [childAge, setChildAge] = useState(7);

  // Derive loading: authed, no error, no upgrade gate, data not yet arrived
  const loading = !!session && !upgradeRequired && !error && materials === null;

  const doFetch = async () => {
    if (!session) return;
    try {
      const res = await fetch('/api/mystery-materials', {
        headers: { Authorization: `Bearer ${session.access_token}` },
      });
      const data = await res.json();
      if (res.status === 403) { setUpgradeRequired(true); return; }
      if (!res.ok) { setError(data.error ?? 'Something went wrong. Try again.'); return; }
      setMaterials(data.materials ?? []);
    } catch {
      setError('Could not load mystery materials. Check your connection.');
    }
  };

  // Re-roll: reset then fetch (called from button, not effect)
  const fetchMystery = () => {
    setMaterials(null);
    setError(null);
    doFetch();
  };

  // Auto-fetch on mount — deferred so setState calls happen outside sync effect body
  useEffect(() => {
    if (session) {
      // eslint-disable-next-line react-hooks/set-state-in-effect
      void doFetch();
    }
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [session]);

  const handleBuild = () => {
    if (!materials?.length) return;
    const params = new URLSearchParams();
    materials.forEach(m => params.append('materials', m.id));
    params.set('age', childAge.toString());
    router.push(`/create/results?${params.toString()}`);
  };

  if (upgradeRequired) {
    return (
      <AppShell>
        <div className="max-w-2xl mx-auto px-4 pb-8 pt-6">
          <UpgradeCard
            feature="Mystery Build"
            description="We pick 3 random materials from your stash. You build something amazing. Plus only."
          />
        </div>
      </AppShell>
    );
  }

  return (
    <AppShell>
      <div className="max-w-2xl mx-auto">
        <div className="px-4 pt-6 pb-4 bg-gradient-to-br from-orange-500 to-orange-700 m-4 rounded-3xl text-white">
          <p className="text-sunshine font-heading font-semibold text-xs uppercase tracking-widest mb-1">Plus Challenge</p>
          <h1 className="font-heading font-bold text-2xl mb-1">Mystery Build</h1>
          <p className="text-white/80 text-sm font-body">3 random materials. You figure it out.</p>
        </div>

        <div className="px-4 space-y-4 pb-8">
          {loading && (
            <div className="flex flex-col items-center justify-center py-16 gap-4">
              <div className="w-16 h-16 bg-orange-100 rounded-full flex items-center justify-center">
                <Loader2 size={28} className="text-orange-500 animate-spin" />
              </div>
              <p className="font-heading font-medium text-walnut-600">Picking your mystery materials…</p>
            </div>
          )}

          {!loading && materials !== null && materials.length > 0 && (
            <>
              <div className="bg-white rounded-3xl shadow-card p-5 space-y-4">
                <p className="text-sm font-heading font-semibold text-charcoal-900">Your mystery materials:</p>
                <div className="flex gap-3 justify-center">
                  {materials.map(m => (
                    <div key={m.id} className="flex-1 bg-cream-100 rounded-2xl p-3 flex flex-col items-center gap-1.5">
                      <span className="text-3xl">{m.icon ?? '📦'}</span>
                      <span className="text-xs font-heading font-semibold text-charcoal-800 text-center leading-tight">{m.name}</span>
                    </div>
                  ))}
                </div>
              </div>

              <div className="flex items-center gap-3">
                <span className="text-xs font-body text-walnut-600 whitespace-nowrap">Child&apos;s age:</span>
                <select
                  value={childAge}
                  onChange={e => setChildAge(Number(e.target.value))}
                  className="text-sm font-body text-charcoal-900 bg-white border border-kraft-300 rounded-xl px-2 py-1 focus:outline-none focus:border-builder-500"
                >
                  {[3,4,5,6,7,8,9,10,11,12].map(age => (
                    <option key={age} value={age}>{age} yrs</option>
                  ))}
                </select>
              </div>

              <div className="flex gap-3">
                <Button variant="secondary" size="md" className="flex items-center gap-2" onClick={fetchMystery}>
                  <Shuffle size={15} />
                  Re-roll
                </Button>
                <Button variant="primary" size="md" className="flex-1" onClick={handleBuild}>
                  Find Builds →
                </Button>
              </div>
            </>
          )}

          {!loading && error && (
            <div className="text-center py-8">
              <p className="text-sm text-red-600 font-body mb-4">{error}</p>
              <Button variant="secondary" size="md" onClick={fetchMystery}>Try Again</Button>
            </div>
          )}

          {!session && (
            <div className="text-center py-8">
              <p className="text-sm text-walnut-600 font-body mb-4">Sign in to try Mystery Build.</p>
            </div>
          )}
        </div>
      </div>
    </AppShell>
  );
}
