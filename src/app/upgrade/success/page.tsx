import { AppShell } from "@/components/layout/AppShell";
import Link from "next/link";
import { Sparkles, Check } from "lucide-react";

const perks = [
  "Unlimited builds every day",
  "Photo material scanner",
  "Up to 10 child profiles",
  "Challenge mode & mystery builds",
  "Unlimited saved projects",
];

export default function UpgradeSuccessPage() {
  return (
    <AppShell>
      <div className="max-w-md mx-auto px-4 pt-12 pb-10 flex flex-col items-center text-center">
        <div className="w-20 h-20 rounded-full bg-orange-500 flex items-center justify-center mb-6 shadow-card-lg">
          <Sparkles size={36} className="text-white" />
        </div>

        <h1 className="font-heading font-bold text-3xl text-charcoal-900 mb-2">
          Welcome to Plus!
        </h1>
        <p className="text-walnut-600 font-body text-sm mb-8 max-w-xs">
          Your subscription is active. Everything&apos;s unlocked — go build something great.
        </p>

        <div className="w-full bg-white rounded-3xl shadow-card p-5 mb-8">
          <p className="text-xs font-heading font-semibold text-walnut-500 uppercase tracking-widest mb-4">
            What&apos;s unlocked
          </p>
          <div className="space-y-2.5">
            {perks.map(perk => (
              <div key={perk} className="flex items-center gap-3">
                <div className="w-5 h-5 rounded-full bg-orange-100 flex items-center justify-center shrink-0">
                  <Check size={11} className="text-orange-500" />
                </div>
                <span className="text-sm font-body text-charcoal-800">{perk}</span>
              </div>
            ))}
          </div>
        </div>

        <Link
          href="/"
          className="w-full bg-orange-500 hover:bg-orange-600 text-white font-heading font-semibold text-base rounded-full px-8 py-4 transition-colors text-center block"
        >
          Start building
        </Link>
      </div>
    </AppShell>
  );
}
