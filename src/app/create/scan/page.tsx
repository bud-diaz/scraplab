import { AppShell } from "@/components/layout/AppShell";
import { PageHeader } from "@/components/layout/PageHeader";
import { UpgradeCard } from "@/components/ui/UpgradeCard";
import { Camera } from "lucide-react";

export default function ScanPage() {
  return (
    <AppShell>
      <div className="max-w-2xl mx-auto">
        <PageHeader title="Scan Materials" subtitle="Take a photo to detect what you have" />
        <div className="px-4 space-y-4 pb-8">
          <div className="bg-walnut-700/10 border-2 border-dashed border-walnut-600/30 rounded-3xl h-56 flex flex-col items-center justify-center gap-3">
            <div className="w-16 h-16 bg-walnut-700/20 rounded-2xl flex items-center justify-center">
              <Camera size={28} className="text-walnut-600" />
            </div>
            <p className="font-heading font-medium text-walnut-600">Camera access required</p>
            <p className="text-xs text-walnut-500 text-center max-w-xs">Plus members can scan their materials instantly</p>
          </div>
          <UpgradeCard
            feature="Material Scanner"
            description="Point your camera at your materials and ScrapLab will detect them instantly. No tapping required."
          />
        </div>
      </div>
    </AppShell>
  );
}
