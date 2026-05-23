"use client";
import { X } from "lucide-react";
import { materials } from "@/lib/mock-data";

interface MaterialSelectionTrayProps {
  selected: string[];
  onRemove: (id: string) => void;
}

export function MaterialSelectionTray({ selected, onRemove }: MaterialSelectionTrayProps) {
  if (selected.length === 0) return null;

  const getMaterial = (id: string) => materials.find(m => m.id === id);

  return (
    <div className="flex flex-wrap gap-2">
      {selected.map(id => {
        const mat = getMaterial(id);
        if (!mat) return null;
        return (
          <span
            key={id}
            className="inline-flex items-center gap-1.5 pl-2.5 pr-1.5 py-1 bg-builder-500 text-white rounded-full text-sm font-heading font-medium"
          >
            {mat.icon} {mat.name}
            <button
              onClick={() => onRemove(id)}
              className="w-4 h-4 bg-white/20 hover:bg-white/40 rounded-full flex items-center justify-center transition-colors"
            >
              <X size={9} />
            </button>
          </span>
        );
      })}
    </div>
  );
}
