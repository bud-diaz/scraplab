"use client";
import { useRouter } from "next/navigation";
import { AppShell } from "@/components/layout/AppShell";
import Link from "next/link";
import { User, LogOut } from "lucide-react";
import { ProfileMenu } from "@/components/cards/ProfileMenu";
import { useAuth } from "@/lib/auth-context";

const mockChildren = [
  { name: "Alex", age: 6, emoji: "🧒" },
  { name: "Sam", age: 4, emoji: "👦" },
];

export default function ProfilePage() {
  const { user, signOut } = useAuth();
  const router = useRouter();

  const handleSignOut = async () => {
    await signOut();
    router.replace("/auth");
  };

  return (
    <AppShell>
      <div className="max-w-2xl mx-auto">
        <div className="px-4 pt-6 pb-4 flex items-center gap-4">
          <div className="w-14 h-14 bg-gradient-to-br from-kraft-400 to-walnut-700 rounded-full flex items-center justify-center">
            <User size={24} className="text-white" />
          </div>
          <div>
            <h1 className="font-heading font-bold text-xl text-charcoal-900">Your Household</h1>
            <p className="text-sm text-walnut-600 font-body">
              {user ? user.email : (
                <Link href="/auth" className="text-builder-500 font-semibold">Sign in to save your progress</Link>
              )}
            </p>
          </div>
          <Link href="/upgrade" className="ml-auto text-xs bg-orange-500 text-white px-3 py-1.5 rounded-full font-heading font-semibold">
            Upgrade
          </Link>
        </div>

        <div className="px-4 mb-6">
          <h2 className="font-heading font-semibold text-sm text-charcoal-900 mb-2">Kids</h2>
          <div className="flex gap-2">
            {mockChildren.map(child => (
              <div key={child.name} className="bg-white rounded-2xl shadow-card px-4 py-3 flex items-center gap-2">
                <span className="text-xl">{child.emoji}</span>
                <div>
                  <p className="font-heading font-semibold text-sm text-charcoal-900">{child.name}</p>
                  <p className="text-xs text-walnut-500">Age {child.age}</p>
                </div>
              </div>
            ))}
            <button className="bg-cream-100 border-2 border-dashed border-kraft-400 rounded-2xl px-4 py-3 text-walnut-600 text-sm font-heading font-medium">
              + Add
            </button>
          </div>
        </div>

        <ProfileMenu />

        <div className="px-4 mb-8">
          {user ? (
            <button
              onClick={handleSignOut}
              className="flex items-center gap-2 text-sm text-red-500 hover:text-red-600 font-heading font-medium"
            >
              <LogOut size={15} />
              Sign Out
            </button>
          ) : (
            <Link
              href="/auth"
              className="flex items-center gap-2 text-sm text-builder-500 hover:text-builder-600 font-heading font-medium"
            >
              <User size={15} />
              Sign In
            </Link>
          )}
        </div>
      </div>
    </AppShell>
  );
}
