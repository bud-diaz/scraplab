"use client";
import Link from "next/link";
import { ChevronRight, Package, CreditCard, Bell, HelpCircle, Shield } from "lucide-react";

type MenuItem = {
  iconType: "package" | "credit-card" | "bell" | "help" | "shield";
  label: string;
  href: string;
  badge?: string;
};

type Section = {
  title: string;
  items: MenuItem[];
};

const menuSections: Section[] = [
  {
    title: "Household",
    items: [
      { iconType: "package", label: "Household Staples", href: "#", badge: "Coming Soon" },
    ],
  },
  {
    title: "Account",
    items: [
      { iconType: "credit-card", label: "Subscription", href: "/upgrade" },
      { iconType: "bell", label: "Notifications", href: "#" },
      { iconType: "help", label: "Help & Support", href: "#" },
    ],
  },
  {
    title: "Legal",
    items: [
      { iconType: "shield", label: "Privacy Policy", href: "/privacy" },
    ],
  },
];

function MenuIcon({ type }: { type: MenuItem["iconType"] }) {
  if (type === "package") return <Package size={16} />;
  if (type === "credit-card") return <CreditCard size={16} />;
  if (type === "bell") return <Bell size={16} />;
  if (type === "shield") return <Shield size={16} />;
  return <HelpCircle size={16} />;
}

export function ProfileMenu() {
  return (
    <>
      {menuSections.map(section => (
        <div key={section.title} className="px-4 mb-5">
          <h2 className="font-heading font-semibold text-xs text-walnut-600 uppercase tracking-wide mb-2">{section.title}</h2>
          <div className="bg-white rounded-3xl shadow-card divide-y divide-cream-100">
            {section.items.map(item => (
              <Link
                key={item.label}
                href={item.href}
                className="flex items-center gap-3 px-4 py-3.5 hover:bg-cream-50 transition-colors"
              >
                <span className="text-walnut-600">
                  <MenuIcon type={item.iconType} />
                </span>
                <span className="flex-1 font-body text-sm text-charcoal-900">{item.label}</span>
                {item.badge && (
                  <span className="text-[10px] bg-cream-100 text-walnut-600 px-2 py-0.5 rounded-full font-heading font-medium">{item.badge}</span>
                )}
                <ChevronRight size={14} className="text-walnut-500" />
              </Link>
            ))}
          </div>
        </div>
      ))}
    </>
  );
}
