// Activity category presentation, shared by the browse card and the detail page
// so the two can't drift apart.
//
// The spec's palette (§2) defines no decorative category colours, and it
// reserves the ones that would otherwise be reaching for: Leaf/Amber/Coral are
// supervision-safety indicators, and deep blue and Craft Orange belong to
// hero/onboarding/CTA moments. A per-category rainbow would both invent a
// palette the system doesn't have and make green mean two things on the same
// screen. So the tile is one Soft Lavender for every category and the emoji
// carries the identity — which also keeps everyday browse screens calm, per §6.

export const CATEGORY_TILE = "bg-cream-100";

export const CATEGORY_EMOJI: Record<string, string> = {
  engineering: "🔧",
  science: "🔬",
  art: "🎨",
  storytelling: "📖",
  "pretend-play": "🎭",
  cooperative: "🤝",
  puzzle: "🧩",
  seasonal: "🍂",
};

export function categoryEmoji(category: string): string {
  return CATEGORY_EMOJI[category] ?? "🧰";
}
