import Link from "next/link";
import { Lock, Zap } from "lucide-react";

interface UpgradeCardProps {
  feature: string;
  description: string;
}

export function UpgradeCard({ feature, description }: UpgradeCardProps) {
  return (
    <div className="bg-gradient-to-br from-orange-500 to-orange-700 rounded-3xl p-5 text-white relative overflow-hidden">
      <div className="absolute top-0 right-0 w-24 h-24 bg-white/10 rounded-full -translate-y-8 translate-x-8" />
      <div className="flex items-start gap-3 relative">
        <div className="w-10 h-10 bg-white/20 rounded-xl flex items-center justify-center shrink-0">
          <Lock size={16} />
        </div>
        <div>
          <h3 className="font-heading font-semibold text-base mb-1">{feature}</h3>
          <p className="text-sm text-white/80 mb-4">{description}</p>
          <Link
            href="/upgrade"
            className="inline-flex items-center gap-1.5 bg-white text-orange-600 px-4 py-2 rounded-full text-sm font-heading font-semibold hover:bg-white/90 transition-colors"
          >
            <Zap size={13} />
            Unlock with Plus
          </Link>
        </div>
      </div>
    </div>
  );
}
