import Link from "next/link";
import { Boxes, Compass, ClipboardList, Trophy, Bookmark } from "lucide-react";

/**
 * Icon quick-nav row — new_scraplab-design-spec.md §4.2.
 *
 * The five circular badges the spec names, in its order and with its labels:
 * Materials · Browse · Build Log · Challenges · Saved.
 */
const ITEMS = [
  { href: "/create/manual", label: "Materials", icon: Boxes },
  { href: "/explore", label: "Browse", icon: Compass },
  { href: "/library", label: "Build Log", icon: ClipboardList },
  { href: "/challenges", label: "Challenges", icon: Trophy },
  { href: "/library?tab=saved", label: "Saved", icon: Bookmark },
];

export function QuickNavRow() {
  return (
    <nav aria-label="Quick navigation" className="px-4">
      <ul className="flex items-start justify-between gap-1">
        {ITEMS.map(({ href, label, icon: Icon }) => (
          <li key={label} className="min-w-0 flex-1">
            <Link
              href={href}
              className="flex flex-col items-center gap-1.5 text-center"
            >
              <span className="flex h-12 w-12 items-center justify-center rounded-full bg-white shadow-card transition-colors hover:bg-cream-100">
                <Icon size={19} className="text-builder-500" aria-hidden />
              </span>
              <span className="font-heading text-[11px] font-medium leading-tight text-charcoal-800">
                {label}
              </span>
            </Link>
          </li>
        ))}
      </ul>
    </nav>
  );
}
