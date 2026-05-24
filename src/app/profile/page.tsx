"use client";
import { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import { AppShell } from "@/components/layout/AppShell";
import Link from "next/link";
import { User, LogOut, Pencil, Trash2, Check, X, Plus } from "lucide-react";
import { ProfileMenu } from "@/components/cards/ProfileMenu";
import { UpgradeCard } from "@/components/ui/UpgradeCard";
import { useAuth } from "@/lib/auth-context";
import { usePlanAccess } from "@/lib/hooks/usePlanAccess";

interface ChildProfile {
  id: string;
  name: string | null;
  age: number;
}

interface InventoryItem {
  material_id: string;
  staple_flag: boolean;
  material: {
    id: string;
    name: string;
    icon: string | null;
  };
}

interface UIMaterial {
  id: string;
  name: string;
  icon: string | null;
}

function KidsSection({ session }: { session: { access_token: string } }) {
  const access = usePlanAccess();
  const [children, setChildren] = useState<ChildProfile[]>([]);
  const [loading, setLoading] = useState(true);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [editName, setEditName] = useState("");
  const [editAge, setEditAge] = useState(7);
  const [showAdd, setShowAdd] = useState(false);
  const [newName, setNewName] = useState("");
  const [newAge, setNewAge] = useState(7);
  const [saving, setSaving] = useState(false);
  const [confirmDeleteId, setConfirmDeleteId] = useState<string | null>(null);

  const headers = {
    "Content-Type": "application/json",
    Authorization: `Bearer ${session.access_token}`,
  };

  useEffect(() => {
    fetch('/api/child-profiles', { headers: { Authorization: `Bearer ${session.access_token}` } })
      .then(r => r.ok ? r.json() : { childProfiles: [] })
      .then(data => setChildren(data.childProfiles ?? []))
      .catch(() => {})
      .finally(() => setLoading(false));
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const childLimit = access?.limits.childProfiles ?? 1;
  const atLimit = children.length >= childLimit;

  const handleAdd = async () => {
    if (!newName.trim()) return;
    setSaving(true);
    try {
      const res = await fetch('/api/child-profiles', {
        method: 'POST',
        headers,
        body: JSON.stringify({ name: newName.trim(), age: newAge }),
      });
      const data = await res.json();
      if (res.ok) {
        setChildren(prev => [...prev, data.childProfile]);
        setShowAdd(false);
        setNewName("");
        setNewAge(7);
      }
    } finally {
      setSaving(false);
    }
  };

  const handleEdit = async (id: string) => {
    setSaving(true);
    try {
      const res = await fetch(`/api/child-profiles/${id}`, {
        method: 'PATCH',
        headers,
        body: JSON.stringify({ name: editName.trim() || null, age: editAge }),
      });
      const data = await res.json();
      if (res.ok) {
        setChildren(prev => prev.map(c => c.id === id ? data.childProfile : c));
        setEditingId(null);
      }
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async (id: string) => {
    setSaving(true);
    try {
      const res = await fetch(`/api/child-profiles/${id}`, {
        method: 'DELETE',
        headers,
      });
      if (res.ok || res.status === 204) {
        setChildren(prev => prev.filter(c => c.id !== id));
        setConfirmDeleteId(null);
        setEditingId(null);
      }
    } finally {
      setSaving(false);
    }
  };

  const startEdit = (child: ChildProfile) => {
    setEditingId(child.id);
    setEditName(child.name ?? "");
    setEditAge(child.age);
    setConfirmDeleteId(null);
  };

  if (loading) {
    return <div className="flex gap-2">{[0,1].map(i => <div key={i} className="w-28 h-20 bg-cream-100 rounded-2xl animate-pulse" />)}</div>;
  }

  return (
    <div>
      <div className="flex flex-wrap gap-2">
        {children.map(child => (
          <div key={child.id} className="bg-white rounded-2xl shadow-card overflow-hidden">
            {editingId === child.id ? (
              <div className="px-3 py-2 space-y-2 min-w-[140px]">
                <input
                  value={editName}
                  onChange={e => setEditName(e.target.value)}
                  placeholder="Name"
                  className="w-full text-sm border border-kraft-300 rounded-xl px-2 py-1 font-body focus:outline-none focus:border-builder-500"
                />
                <div className="flex items-center gap-1">
                  <span className="text-xs text-walnut-600 font-body">Age</span>
                  <select
                    value={editAge}
                    onChange={e => setEditAge(Number(e.target.value))}
                    className="text-sm font-body bg-white border border-kraft-300 rounded-xl px-1 py-0.5 focus:outline-none"
                  >
                    {Array.from({length: 16}, (_, i) => i + 3).map(a => (
                      <option key={a} value={a}>{a}</option>
                    ))}
                  </select>
                </div>
                {confirmDeleteId === child.id ? (
                  <div className="space-y-1">
                    <p className="text-xs text-red-600 font-body">Remove {child.name ?? 'this kid'}?</p>
                    <div className="flex gap-1">
                      <button
                        onClick={() => handleDelete(child.id)}
                        disabled={saving}
                        className="flex-1 text-xs bg-red-500 text-white rounded-xl py-1 font-heading font-semibold"
                      >Yes</button>
                      <button
                        onClick={() => setConfirmDeleteId(null)}
                        className="flex-1 text-xs bg-cream-100 text-walnut-700 rounded-xl py-1 font-heading font-semibold"
                      >No</button>
                    </div>
                  </div>
                ) : (
                  <div className="flex gap-1">
                    <button
                      onClick={() => handleEdit(child.id)}
                      disabled={saving}
                      className="flex-1 flex items-center justify-center bg-builder-500 text-white rounded-xl py-1"
                    ><Check size={13} /></button>
                    <button
                      onClick={() => setConfirmDeleteId(child.id)}
                      className="flex items-center justify-center bg-red-50 text-red-500 rounded-xl px-2 py-1"
                    ><Trash2 size={13} /></button>
                    <button
                      onClick={() => setEditingId(null)}
                      className="flex items-center justify-center bg-cream-100 text-walnut-600 rounded-xl px-2 py-1"
                    ><X size={13} /></button>
                  </div>
                )}
              </div>
            ) : (
              <button
                onClick={() => startEdit(child)}
                className="px-4 py-3 flex items-center gap-2 group w-full text-left"
              >
                <span className="text-xl">🧒</span>
                <div>
                  <p className="font-heading font-semibold text-sm text-charcoal-900">{child.name ?? 'Kid'}</p>
                  <p className="text-xs text-walnut-500">Age {child.age}</p>
                </div>
                <Pencil size={11} className="ml-1 text-walnut-400 opacity-0 group-hover:opacity-100 transition-opacity" />
              </button>
            )}
          </div>
        ))}

        {/* Add button */}
        {!showAdd && (
          atLimit ? (
            access?.plan === 'free' ? (
              <Link
                href="/upgrade"
                className="bg-cream-100 border-2 border-dashed border-orange-300 rounded-2xl px-4 py-3 text-orange-600 text-xs font-heading font-medium flex items-center gap-1"
              >
                <Plus size={12} /> Upgrade for more
              </Link>
            ) : null
          ) : (
            <button
              onClick={() => setShowAdd(true)}
              className="bg-cream-100 border-2 border-dashed border-kraft-400 rounded-2xl px-4 py-3 text-walnut-600 text-sm font-heading font-medium flex items-center gap-1"
            >
              <Plus size={14} /> Add
            </button>
          )
        )}

        {showAdd && (
          <div className="bg-white rounded-2xl shadow-card px-3 py-2 space-y-2 min-w-[140px]">
            <input
              value={newName}
              onChange={e => setNewName(e.target.value)}
              placeholder="Name"
              autoFocus
              className="w-full text-sm border border-kraft-300 rounded-xl px-2 py-1 font-body focus:outline-none focus:border-builder-500"
            />
            <div className="flex items-center gap-1">
              <span className="text-xs text-walnut-600 font-body">Age</span>
              <select
                value={newAge}
                onChange={e => setNewAge(Number(e.target.value))}
                className="text-sm font-body bg-white border border-kraft-300 rounded-xl px-1 py-0.5 focus:outline-none"
              >
                {Array.from({length: 16}, (_, i) => i + 3).map(a => (
                  <option key={a} value={a}>{a}</option>
                ))}
              </select>
            </div>
            <div className="flex gap-1">
              <button
                onClick={handleAdd}
                disabled={saving || !newName.trim()}
                className="flex-1 flex items-center justify-center bg-builder-500 disabled:opacity-40 text-white rounded-xl py-1"
              ><Check size={13} /></button>
              <button
                onClick={() => { setShowAdd(false); setNewName(""); }}
                className="flex items-center justify-center bg-cream-100 text-walnut-600 rounded-xl px-2 py-1"
              ><X size={13} /></button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

function StaplesSection({ session }: { session: { access_token: string } }) {
  const access = usePlanAccess();
  // null = not yet fetched; [] = fetched but empty
  const [inventory, setInventory] = useState<InventoryItem[] | null>(null);
  const [allMaterials, setAllMaterials] = useState<UIMaterial[] | null>(null);
  const [showPicker, setShowPicker] = useState(false);
  const [toggling, setToggling] = useState<string | null>(null);

  // Derive loading: only when Plus and data hasn't arrived yet
  const loading = access?.plan === 'plus' && (inventory === null || allMaterials === null);

  const authHeader = { Authorization: `Bearer ${session.access_token}` };

  useEffect(() => {
    if (access?.plan !== 'plus') return;

    Promise.all([
      fetch('/api/household-inventory', { headers: authHeader }).then(r => r.ok ? r.json() : { inventory: [] }),
      fetch('/api/materials', { headers: authHeader }).then(r => r.ok ? r.json() : { materials: [] }),
    ])
      .then(([invData, matData]) => {
        setInventory(invData.inventory ?? []);
        setAllMaterials(matData.materials ?? []);
      })
      .catch(() => {
        setInventory([]);
        setAllMaterials([]);
      });
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [access?.plan]);

  if (!access) return null;

  if (access.plan !== 'plus') {
    return (
      <UpgradeCard
        feature="Household Staples"
        description="Save your go-to materials so they're always pre-selected when you build."
      />
    );
  }

  const toggleStaple = async (materialId: string, currentlyStaple: boolean) => {
    setToggling(materialId);
    try {
      const res = await fetch('/api/household-inventory', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', ...authHeader },
        body: JSON.stringify({ materialId, stapleFlag: !currentlyStaple, source: 'saved' }),
      });
      if (res.ok) {
        const data = await res.json();
        setInventory(prev => {
          const cur = prev ?? [];
          const exists = cur.find(i => i.material_id === materialId);
          if (exists) return cur.map(i => i.material_id === materialId ? data.item : i);
          return [...cur, data.item];
        });
      }
    } finally {
      setToggling(null);
    }
  };

  const staples = (inventory ?? []).filter(i => i.staple_flag);
  const stapleIds = new Set(staples.map(i => i.material_id));

  if (loading) {
    return <div className="flex gap-2 flex-wrap">{[0,1,2].map(i => <div key={i} className="w-20 h-8 bg-cream-100 rounded-xl animate-pulse" />)}</div>;
  }

  return (
    <div>
      {staples.length === 0 && !showPicker && (
        <p className="text-xs text-walnut-500 font-body mb-3">No staples yet. Add materials you always have on hand.</p>
      )}

      {staples.length > 0 && (
        <div className="flex flex-wrap gap-2 mb-3">
          {staples.map(item => (
            <button
              key={item.material_id}
              onClick={() => toggleStaple(item.material_id, true)}
              disabled={toggling === item.material_id}
              className="flex items-center gap-1.5 bg-builder-500/10 text-builder-600 rounded-xl px-3 py-1.5 text-xs font-heading font-semibold hover:bg-red-50 hover:text-red-600 transition-colors group"
            >
              <span>{item.material?.icon ?? '📦'}</span>
              {item.material?.name}
              <X size={10} className="opacity-0 group-hover:opacity-100" />
            </button>
          ))}
        </div>
      )}

      {showPicker ? (
        <div className="bg-white rounded-2xl shadow-card p-3 space-y-2">
          <p className="text-xs font-heading font-semibold text-charcoal-800 mb-2">Tap to add as staple:</p>
          <div className="flex flex-wrap gap-2 max-h-40 overflow-y-auto">
            {(allMaterials ?? [])
              .filter(m => !stapleIds.has(m.id))
              .map(m => (
                <button
                  key={m.id}
                  onClick={() => toggleStaple(m.id, false)}
                  disabled={toggling === m.id}
                  className="flex items-center gap-1 bg-cream-100 hover:bg-builder-500/10 text-walnut-700 hover:text-builder-600 rounded-xl px-2.5 py-1.5 text-xs font-heading font-medium transition-colors"
                >
                  <span>{m.icon ?? '📦'}</span>
                  {m.name}
                </button>
              ))}
          </div>
          <button onClick={() => setShowPicker(false)} className="text-xs text-walnut-500 font-body mt-1">Done</button>
        </div>
      ) : (
        <button
          onClick={() => setShowPicker(true)}
          className="flex items-center gap-1.5 text-xs text-builder-500 font-heading font-semibold hover:text-builder-600 transition-colors"
        >
          <Plus size={13} /> Add staple
        </button>
      )}
    </div>
  );
}

export default function ProfilePage() {
  const { user, session, signOut } = useAuth();
  const router = useRouter();
  const access = usePlanAccess();

  const handleSignOut = async () => {
    await signOut();
    router.replace("/auth");
  };

  return (
    <AppShell>
      <div className="max-w-2xl mx-auto">
        {/* Header */}
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
          {(!access || access.plan === 'free') && (
            <Link href="/upgrade" className="ml-auto text-xs bg-orange-500 text-white px-3 py-1.5 rounded-full font-heading font-semibold">
              Upgrade
            </Link>
          )}
          {access?.plan === 'plus' && (
            <span className="ml-auto text-xs bg-walnut-700 text-white px-3 py-1.5 rounded-full font-heading font-semibold">
              Plus ✓
            </span>
          )}
        </div>

        {/* Kids */}
        <div className="px-4 mb-6">
          <h2 className="font-heading font-semibold text-sm text-charcoal-900 mb-2">Kids</h2>
          {session ? (
            <KidsSection session={session} />
          ) : (
            <p className="text-xs text-walnut-500 font-body">Sign in to manage kid profiles.</p>
          )}
        </div>

        {/* Household Staples */}
        <div className="px-4 mb-6">
          <h2 className="font-heading font-semibold text-sm text-charcoal-900 mb-2">Household Staples</h2>
          {session ? (
            <StaplesSection session={session} />
          ) : (
            <p className="text-xs text-walnut-500 font-body">Sign in to manage your staples.</p>
          )}
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
