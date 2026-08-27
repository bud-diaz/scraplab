"use client";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { Home, PlusCircle, BookOpen, Compass, User } from "lucide-react";
import { cn } from "@/lib/utils";
import { usePlanAccess } from "@/lib/hooks/usePlanAccess";

const navItems = [
  { href: "/", label: "Home", icon: Home },
  { href: "/create", label: "Create", icon: PlusCircle },
  { href: "/library", label: "Library", icon: BookOpen },
  { href: "/explore", label: "Explore", icon: Compass },
  { href: "/profile", label: "Profile", icon: User },
];

export function BottomNav() {
  const pathname = usePathname();
  const access = usePlanAccess();

  const atLimit = access?.plan === 'free' &&
    access.usage.recommendationsToday >= (access.limits.dailyRecommendations ?? 3);

  return (
    <nav className="md:hidden fixed bottom-0 left-0 right-0 z-50 mx-3 mb-3 bg-white rounded-full shadow-card-lg overflow-hidden">
      {atLimit && (
        <div className="h-0.5 bg-gradient-to-r from-orange-400 to-red-500" />
      )}
      <div className="flex items-center justify-around px-1.5 py-2">
        {navItems.map(({ href, label, icon: Icon }) => {
          const active = pathname === href || (href !== "/" && pathname.startsWith(href));
          const showBadge = href === '/profile' && atLimit;
          return (
            <Link
              key={href}
              href={href}
              className="relative flex flex-col items-center gap-0.5 px-2.5 py-1 rounded-2xl transition-colors min-w-0"
            >
              <span className={cn(
                "flex items-center justify-center w-8 h-8 rounded-full transition-colors",
                active ? "bg-builder-500" : "bg-transparent"
              )}>
                <Icon size={18} strokeWidth={active ? 2.5 : 1.8} className={active ? "text-white" : "text-kraft-600"} />
              </span>
              {showBadge && (
                <span className="absolute top-0 right-1 w-2 h-2 bg-coral rounded-full" />
              )}
              <span className={cn("text-[10px] font-heading font-medium", active ? "text-builder-500" : "text-kraft-600")}>
                {label}
              </span>
            </Link>
          );
        })}
      </div>
    </nav>
  );
}
