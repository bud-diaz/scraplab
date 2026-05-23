"use client";
import Link from "next/link";
import Image from "next/image";
import { usePathname } from "next/navigation";
import { cn } from "@/lib/utils";
import { Zap } from "lucide-react";
import { useAuth } from "@/lib/auth-context";

const navLinks = [
  { href: "/", label: "Home" },
  { href: "/create", label: "Create" },
  { href: "/library", label: "Library" },
  { href: "/challenges", label: "Challenges" },
  { href: "/profile", label: "Profile" },
];

export function TopNav() {
  const pathname = usePathname();
  const { user } = useAuth();

  return (
    <header className="hidden md:flex fixed top-0 left-0 right-0 z-50 h-16 bg-white border-b border-kraft-300 shadow-card px-6 items-center justify-between">
      <Link href="/" className="flex items-center">
        <Image src="/logo.png" alt="ScrapLab" height={44} width={132} className="object-contain" priority />
      </Link>
      <nav className="flex items-center gap-1">
        {navLinks.map((link) => (
          <Link
            key={link.href}
            href={link.href}
            className={cn(
              "px-4 py-2 rounded-xl text-sm font-heading font-medium transition-colors",
              pathname === link.href
                ? "bg-cream-100 text-builder-500"
                : "text-charcoal-800 hover:text-charcoal-900 hover:bg-cream-50"
            )}
          >
            {link.label}
          </Link>
        ))}
      </nav>
      <div className="flex items-center gap-2">
        {!user && (
          <Link
            href="/auth"
            className="px-4 py-2 rounded-2xl text-sm font-heading font-semibold text-charcoal-800 hover:bg-cream-100 transition-colors"
          >
            Sign In
          </Link>
        )}
        <Link
          href="/upgrade"
          className="flex items-center gap-1.5 bg-orange-500 text-white px-4 py-2 rounded-2xl text-sm font-heading font-semibold hover:bg-orange-600 transition-colors"
        >
          <Zap size={14} />
          Upgrade
        </Link>
      </div>
    </header>
  );
}
