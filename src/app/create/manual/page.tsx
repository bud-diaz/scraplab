"use client";
import { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import { AppShell } from "@/components/layout/AppShell";
import { MaterialCard } from "@/components/ui/MaterialCard";
import { MaterialSelectionTray } from "@/components/ui/MaterialSelectionTray";
import { FilterChip } from "@/components/ui/FilterChip";
import { Button } from "@/components/ui/Button";
import { materials as mockMaterials, materialCategories } from "@/lib/mock-data";
import { Search } from "lucide-react";

interface UIMaterial {
  id: string;
  name: string;
  category: string;
  icon: string | null;
}

const fallbackMaterials: UIMaterial[] = mockMaterials.map(m => ({
  id: m.id,
  name: m.name,
  category: m.category,
  icon: m.icon,
}));

const AGE_OPTIONS = [3, 4, 5, 6, 7, 8, 9, 10, 11, 12];

export default function ManualPickerPage() {
  const router = useRouter();
  const [materials, setMaterials] = useState<UIMaterial[]>(fallbackMaterials);
  const [selected, setSelected] = useState<string[]>([]);
  const [activeCategory, setActiveCategory] = useState("all");
  const [search, setSearch] = useState("");
  const [childAge, setChildAge] = useState(7);

  useEffect(() => {
    fetch('/api/materials')
      .then(r => r.ok ? r.json() : null)
      .then(data => {
        if (data?.materials?.length) setMaterials(data.materials);
      })
      .catch(() => { /* silently keep fallback */ });
  }, []);

  const toggle = (id: string) => {
    setSelected(prev => prev.includes(id) ? prev.filter(x => x !== id) : [...prev, id]);
  };

  const remove = (id: string) => setSelected(prev => prev.filter(x => x !== id));

  const categories = [
    { id: "all", label: "All" },
    ...Array.from(new Set(materials.map(m => m.category))).map(cat => ({
      id: cat,
      label: materialCategories.find(c => c.id === cat)?.label ?? cat,
    })),
  ];

  const filtered = materials.filter(m => {
    const matchCat = activeCategory === "all" || m.category === activeCategory;
    const matchSearch = m.name.toLowerCase().includes(search.toLowerCase());
    return matchCat && matchSearch;
  });

  const handleFindBuilds = () => {
    const params = new URLSearchParams();
    selected.forEach(id => params.append("materials", id));
    params.set("age", childAge.toString());
    router.push(`/create/results?${params.toString()}`);
  };

  return (
    <AppShell>
      <div className="max-w-2xl mx-auto">
        <div className="px-4 pt-6 pb-3">
          <h1 className="font-heading font-bold text-2xl text-charcoal-900 mb-1">What do you have?</h1>
          <p className="text-sm text-walnut-600">Tap to add materials from your stash.</p>
        </div>

        <div className="px-4 mb-4">
          <div className="relative">
            <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-walnut-600" />
            <input
              type="text"
              placeholder="Search materials..."
              value={search}
              onChange={e => setSearch(e.target.value)}
              className="w-full pl-9 pr-4 py-2.5 bg-white border border-kraft-300 rounded-2xl text-sm font-body text-charcoal-900 placeholder-walnut-500 focus:outline-none focus:border-builder-500 transition-colors"
            />
          </div>
        </div>

        {selected.length > 0 && (
          <div className="px-4 mb-4">
            <MaterialSelectionTray selected={selected} materials={materials} onRemove={remove} />
          </div>
        )}

        <div className="px-4 mb-4 overflow-x-auto">
          <div className="flex gap-2 pb-1">
            {categories.map(cat => (
              <FilterChip
                key={cat.id}
                label={cat.label}
                active={activeCategory === cat.id}
                onClick={() => setActiveCategory(cat.id)}
              />
            ))}
          </div>
        </div>

        <div className="px-4 grid grid-cols-4 gap-2.5 pb-28">
          {filtered.map(mat => (
            <MaterialCard
              key={mat.id}
              id={mat.id}
              name={mat.name}
              icon={mat.icon ?? "📦"}
              selected={selected.includes(mat.id)}
              onToggle={toggle}
            />
          ))}
        </div>

        <div className="fixed bottom-16 md:bottom-0 left-0 right-0 bg-cream-50/90 backdrop-blur-sm border-t border-kraft-300 p-4 z-40">
          <div className="max-w-2xl mx-auto space-y-2">
            <div className="flex items-center gap-2">
              <span className="text-xs font-body text-walnut-600 whitespace-nowrap">Child&apos;s age:</span>
              <select
                value={childAge}
                onChange={e => setChildAge(Number(e.target.value))}
                className="text-sm font-body text-charcoal-900 bg-white border border-kraft-300 rounded-xl px-2 py-1 focus:outline-none focus:border-builder-500"
              >
                {AGE_OPTIONS.map(age => (
                  <option key={age} value={age}>{age} yrs</option>
                ))}
              </select>
            </div>
            <div className="flex items-center gap-3">
              <div className="flex-1">
                <p className="text-xs font-body text-walnut-600">
                  {selected.length === 0
                    ? "Select at least 1 material"
                    : `${selected.length} material${selected.length !== 1 ? "s" : ""} selected`}
                </p>
              </div>
              <Button
                variant="primary"
                size="md"
                disabled={selected.length === 0}
                onClick={handleFindBuilds}
                className="disabled:opacity-40 disabled:cursor-not-allowed"
              >
                Find Builds
              </Button>
            </div>
          </div>
        </div>
      </div>
    </AppShell>
  );
}
