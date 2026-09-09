import { AppShell } from "@/components/layout/AppShell";
import { UpgradeCard } from "@/components/ui/UpgradeCard";
import { ChallengesList } from "@/components/cards/ChallengesList";

export default function ChallengesPage() {
  return (
    <AppShell>
      <div className="max-w-2xl mx-auto">
        <div className="px-4 py-5 bg-scraplab-blue m-4 rounded-3xl text-white">
          <p className="text-sunshine font-heading font-semibold text-xs uppercase tracking-widest mb-1">Weekly</p>
          <h1 className="font-heading font-bold text-2xl mb-1">ScrapLab Challenges</h1>
          <p className="text-white/80 text-sm font-body">Push your builds further.</p>
        </div>

        <div className="px-4 space-y-3 pb-4">
          <ChallengesList />
        </div>

        <div className="px-4 pb-8">
          <UpgradeCard
            feature="Unlock Mystery Builds"
            description="Get Mystery Builds and more challenge modes as they launch, with ScrapLab Plus."
          />
        </div>
      </div>
    </AppShell>
  );
}
