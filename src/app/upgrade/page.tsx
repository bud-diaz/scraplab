import { AppShell } from "@/components/layout/AppShell";
import { UpgradeActions } from "@/components/ui/UpgradeActions";
import { Check, X } from "lucide-react";

const features = [
  { label: "Manual material picker", free: true, plus: true },
  { label: "Up to 3 builds/day", free: true, plus: false },
  { label: "Unlimited builds", free: false, plus: true },
  { label: "Save up to 10 projects", free: true, plus: false },
  { label: "Unlimited saves", free: false, plus: true },
  { label: "Photo material scanner", free: false, plus: true },
  { label: "Household staples saved list", free: false, plus: true },
  { label: "1 child profile", free: true, plus: false },
  { label: "Up to 10 child profiles", free: false, plus: true },
  { label: "Challenge mode", free: false, plus: true },
  { label: "Mystery builds", free: false, plus: true },
];

export default function UpgradePage() {
  return (
    <AppShell>
      <div className="max-w-2xl mx-auto">
        <div className="px-4 pt-8 pb-6 text-center">
          <p className="text-orange-500 font-heading font-semibold text-sm uppercase tracking-widest mb-2">ScrapLab Plus</p>
          <h1 className="font-heading font-bold text-3xl text-charcoal-900 mb-3">Unlock faster creativity</h1>
          <p className="text-walnut-600 font-body text-sm max-w-xs mx-auto">
            Everything you need to build more, save more, and never run out of ideas.
          </p>
        </div>

        <div className="px-4 mb-6">
          <div className="grid grid-cols-2 gap-3">
            <div className="bg-cream-100 rounded-3xl p-5">
              <h2 className="font-heading font-bold text-lg text-charcoal-900 mb-1">Free</h2>
              <p className="font-heading font-bold text-2xl text-charcoal-900 mb-4">$0</p>
              <div className="space-y-2">
                {features.filter(f => f.free).slice(0, 4).map(f => (
                  <div key={f.label} className="flex items-center gap-2">
                    <Check size={12} className="text-builder-500 shrink-0" />
                    <span className="text-xs font-body text-charcoal-800">{f.label}</span>
                  </div>
                ))}
              </div>
            </div>
            <div className="bg-scraplab-blue rounded-3xl p-5 text-white relative overflow-hidden">
              <div className="absolute top-0 right-0 w-20 h-20 bg-white/10 rounded-full -translate-y-8 translate-x-8" />
              <span className="inline-block bg-sunshine text-charcoal-900 text-[10px] font-heading font-bold px-2.5 py-1 rounded-full mb-2">BEST VALUE</span>
              <h2 className="font-heading font-bold text-lg mb-1">Plus</h2>
              <div className="flex items-baseline gap-1 mb-4">
                <span className="font-heading font-bold text-2xl">$4.99</span>
                <span className="text-white/80 text-xs">/mo</span>
              </div>
              <div className="space-y-2 relative">
                {features.filter(f => f.plus).slice(0, 5).map(f => (
                  <div key={f.label} className="flex items-center gap-2">
                    <Check size={12} className="text-white shrink-0" />
                    <span className="text-xs font-body text-white/90">{f.label}</span>
                  </div>
                ))}
                <span className="text-white/70 text-xs">+ more</span>
              </div>
            </div>
          </div>
        </div>

        <div className="px-4 mb-6">
          <div className="bg-white rounded-3xl shadow-card overflow-hidden">
            <div className="grid grid-cols-3 bg-cream-100 px-4 py-2.5 text-xs font-heading font-semibold text-walnut-600">
              <span>Feature</span>
              <span className="text-center">Free</span>
              <span className="text-center text-orange-500">Plus</span>
            </div>
            {features.map(f => (
              <div key={f.label} className="grid grid-cols-3 px-4 py-3 border-t border-cream-100 items-center">
                <span className="text-xs font-body text-charcoal-800">{f.label}</span>
                <div className="flex justify-center">
                  {f.free
                    ? <Check size={14} className="text-builder-500" />
                    : <X size={14} className="text-cream-200" />}
                </div>
                <div className="flex justify-center">
                  {f.plus
                    ? <Check size={14} className="text-orange-500" />
                    : <X size={14} className="text-cream-200" />}
                </div>
              </div>
            ))}
          </div>
        </div>

        <div className="px-4 pb-8">
          <UpgradeActions />
        </div>
      </div>
    </AppShell>
  );
}
