"use client";
import { useState } from "react";
import { Check } from "lucide-react";
import { cn } from "@/lib/utils";
import { materials } from "@/lib/mock-data";

interface MaterialsChecklistProps {
  requiredMaterials: string[];
  optionalMaterials: string[];
  substitutions: Record<string, string>;
}

export function MaterialsChecklist({ requiredMaterials, optionalMaterials, substitutions }: MaterialsChecklistProps) {
  const [checked, setChecked] = useState<Set<string>>(new Set());

  const toggle = (id: string) => {
    setChecked(prev => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  };

  const getMaterialName = (id: string) =>
    materials.find(m => m.id === id)?.name ?? id;
  const getMaterialIcon = (id: string) =>
    materials.find(m => m.id === id)?.icon ?? "📦";

  return (
    <div className="space-y-4">
      <div>
        <h4 className="font-heading font-semibold text-sm text-charcoal-900 mb-2">Required</h4>
        <div className="space-y-2">
          {requiredMaterials.map(id => (
            <button
              key={id}
              onClick={() => toggle(id)}
              className="flex items-center gap-3 w-full text-left"
            >
              <div className={cn(
                "w-5 h-5 rounded-md border-2 flex items-center justify-center transition-all shrink-0",
                checked.has(id) ? "bg-builder-500 border-builder-500" : "border-kraft-400 bg-white"
              )}>
                {checked.has(id) && <Check size={11} className="text-white" strokeWidth={3} />}
              </div>
              <span className="text-sm font-body text-charcoal-800">
                {getMaterialIcon(id)} {getMaterialName(id)}
              </span>
            </button>
          ))}
        </div>
      </div>
      {optionalMaterials.length > 0 && (
        <div>
          <h4 className="font-heading font-semibold text-sm text-charcoal-900 mb-2">Optional</h4>
          <div className="space-y-2">
            {optionalMaterials.map(id => (
              <div key={id} className="flex flex-col gap-0.5">
                <div className="flex items-center gap-3">
                  <div className="w-5 h-5 rounded-md border-2 border-dashed border-kraft-400 shrink-0" />
                  <span className="text-sm font-body text-walnut-600">
                    {getMaterialIcon(id)} {getMaterialName(id)}
                  </span>
                </div>
                {substitutions[id] && (
                  <p className="text-xs text-walnut-500 ml-8 italic">↳ {substitutions[id]}</p>
                )}
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
