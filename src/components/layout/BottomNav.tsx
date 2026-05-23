"use client";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { Home, PlusCircle, BookOpen, Trophy, User } from "lucide-react";
import { cn } from "@/lib/utils";

const navItems = [
  { href: "/", label: "Home", icon: Home },
  { href: "/create", label: "Create", icon: PlusCircle },
  { href: "/library", label: "Library", icon: BookOpen },
  { href: "/challenges", label: "Challenges", icon: Trophy },
  { href: "/profile", label: "Profile", icon: User },
];

export function BottomNav() {
  const pathname = usePathname();
  return (
    <nav className="md:hidden fixed bottom-0 left-0 right-0 z-50 bg-white border-t border-kraft-300 shadow-card-lg">
      <div className="flex items-center justify-around px-2 py-2">
        {navItems.map(({ href, label, icon: Icon }) => {
          const active = pathname === href || (href !== "/" && pathname.startsWith(href));
          return (
            <Link
              key={href}
              href={href}
              className={cn(
                "flex flex-col items-center gap-0.5 px-3 py-1.5 rounded-xl transition-colors min-w-0",
                active ? "text-builder-500" : "text-charcoal-800"
              )}
            >
              <Icon size={20} strokeWidth={active ? 2.5 : 1.8} />
              <span className={cn("text-[10px] font-heading font-medium", active ? "text-builder-500" : "text-charcoal-800")}>
                {label}
              </span>
            </Link>
          );
        })}
      </div>
    </nav>
  );
}
