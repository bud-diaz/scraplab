"use client";
import { TopNav } from "./TopNav";
import { BottomNav } from "./BottomNav";

interface AppShellProps {
  children: React.ReactNode;
}

export function AppShell({ children }: AppShellProps) {
  return (
    <div className="min-h-screen bg-cream-50">
      <TopNav />
      <main className="pb-20 md:pb-0 md:pt-16">
        {children}
      </main>
      <BottomNav />
    </div>
  );
}
