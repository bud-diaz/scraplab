import Link from "next/link";
import { ArrowRight } from "lucide-react";

export function HeroActionCard() {
  return (
    <div className="mx-4 bg-gradient-to-br from-walnut-700 to-charcoal-900 rounded-3xl p-6 text-white relative overflow-hidden shadow-card-lg">
      <div className="absolute top-0 right-0 w-40 h-40 bg-white/5 rounded-full -translate-y-16 translate-x-16" />
      <div className="absolute bottom-0 left-0 w-28 h-28 bg-builder-500/20 rounded-full translate-y-12 -translate-x-8" />
      <div className="relative">
        <p className="text-orange-400 font-heading font-semibold text-sm mb-2 uppercase tracking-wide">Ready to build?</p>
        <h2 className="font-heading font-bold text-2xl mb-2 leading-tight">
          What can we make<br />today?
        </h2>
        <p className="text-white/60 text-sm mb-6">Pick your materials. Get a build in seconds.</p>
        <Link
          href="/create/manual"
          className="inline-flex items-center gap-2 bg-builder-500 text-white px-5 py-2.5 rounded-2xl font-heading font-semibold text-sm hover:bg-builder-600 transition-colors"
        >
          Find a Build
          <ArrowRight size={15} />
        </Link>
      </div>
    </div>
  );
}
