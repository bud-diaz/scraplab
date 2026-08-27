"use client";
import { useState, useRef } from "react";
import { useRouter } from "next/navigation";
import { AppShell } from "@/components/layout/AppShell";
import { PageHeader } from "@/components/layout/PageHeader";
import { UpgradeCard } from "@/components/ui/UpgradeCard";
import { Button } from "@/components/ui/Button";
import { useAuth } from "@/lib/auth-context";
import { Camera, Upload, Loader2, CheckCircle2 } from "lucide-react";
import type { DetectedMaterial } from "@/types";

export default function ScanPage() {
  const { session } = useAuth();
  const router = useRouter();
  const fileRef = useRef<HTMLInputElement>(null);

  const [scanning, setScanning] = useState(false);
  const [detected, setDetected] = useState<DetectedMaterial[] | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [upgradeRequired, setUpgradeRequired] = useState(false);
  const [preview, setPreview] = useState<string | null>(null);

  const handleFile = async (file: File) => {
    if (!session) return;
    setError(null);
    setDetected(null);
    setPreview(URL.createObjectURL(file));
    setScanning(true);

    try {
      const formData = new FormData();
      formData.append('image', file);

      const res = await fetch('/api/scan-materials', {
        method: 'POST',
        headers: { Authorization: `Bearer ${session.access_token}` },
        body: formData,
      });

      const data = await res.json();

      if (res.status === 403) {
        setUpgradeRequired(true);
        return;
      }
      if (!res.ok) {
        setError(data.error ?? 'Scan failed. Try again.');
        return;
      }

      setDetected(data.detectedMaterials ?? []);
    } catch {
      setError('Scan failed. Check your connection and try again.');
    } finally {
      setScanning(false);
    }
  };

  const handleFileInput = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) handleFile(file);
  };

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault();
    const file = e.dataTransfer.files?.[0];
    if (file?.type.startsWith('image/')) handleFile(file);
  };

  const handleConfirm = () => {
    if (!detected?.length) return;
    const params = new URLSearchParams();
    detected.forEach(m => params.append('materials', m.materialId));
    params.set('age', '7');
    router.push(`/create/results?${params.toString()}`);
  };

  if (upgradeRequired) {
    return (
      <AppShell>
        <div className="max-w-2xl mx-auto px-4 pb-8">
          <PageHeader title="Scan Materials" subtitle="Take a photo to detect what you have" />
          <UpgradeCard
            feature="Material Scanner"
            description="Point your camera at your materials and ScrapLab will detect them instantly. No tapping required."
          />
        </div>
      </AppShell>
    );
  }

  return (
    <AppShell>
      <div className="max-w-2xl mx-auto">
        <PageHeader title="Scan Materials" subtitle="Take a photo to detect what you have" />
        <div className="px-4 space-y-4 pb-8">

          {/* Upload area */}
          {!detected && (
            <div
              onDrop={handleDrop}
              onDragOver={e => e.preventDefault()}
              className="relative bg-walnut-700/10 border-2 border-dashed border-walnut-600/30 rounded-3xl overflow-hidden"
            >
              {preview ? (
                <div className="relative h-56">
                  {/* eslint-disable-next-line @next/next/no-img-element */}
                  <img src={preview} alt="Preview" className="w-full h-full object-cover" />
                  {scanning && (
                    <div className="absolute inset-0 bg-black/40 flex flex-col items-center justify-center gap-2">
                      <Loader2 size={32} className="text-white animate-spin" />
                      <p className="text-white text-sm font-heading font-medium">Scanning...</p>
                    </div>
                  )}
                </div>
              ) : (
                <div className="h-56 flex flex-col items-center justify-center gap-3">
                  <div className="w-16 h-16 bg-walnut-700/20 rounded-2xl flex items-center justify-center">
                    <Camera size={28} className="text-walnut-600" />
                  </div>
                  <p className="font-heading font-medium text-walnut-600">Drop a photo here</p>
                  <p className="text-xs text-walnut-500 text-center max-w-xs">or use the button below to upload</p>
                </div>
              )}
            </div>
          )}

          {/* Detected materials */}
          {detected && (
            <div className="bg-white rounded-3xl shadow-card p-4 space-y-3">
              <div className="flex items-center gap-2">
                <CheckCircle2 size={18} className="text-builder-500" />
                <h3 className="font-heading font-semibold text-sm text-charcoal-900">
                  {detected.length > 0 ? `Found ${detected.length} material${detected.length !== 1 ? 's' : ''}` : 'No materials detected'}
                </h3>
              </div>
              {detected.length > 0 ? (
                <ul className="space-y-2">
                  {detected.map(m => (
                    <li key={m.materialId} className="flex items-center justify-between">
                      <span className="text-sm font-body text-charcoal-800">{m.label}</span>
                      <span className="text-xs text-walnut-500">{Math.round(m.confidence * 100)}% sure</span>
                    </li>
                  ))}
                </ul>
              ) : (
                <p className="text-sm text-walnut-600 font-body">Try a clearer photo with better lighting.</p>
              )}
            </div>
          )}

          {error && (
            <p className="text-sm text-coral-text font-body text-center">{error}</p>
          )}

          {/* Actions */}
          <input
            ref={fileRef}
            type="file"
            accept="image/*"
            capture="environment"
            className="hidden"
            onChange={handleFileInput}
          />

          {!scanning && (
            <div className="flex gap-3">
              <Button
                variant="secondary"
                size="md"
                className="flex-1 flex items-center justify-center gap-2"
                onClick={() => { setDetected(null); setPreview(null); setError(null); fileRef.current?.click(); }}
              >
                <Upload size={15} />
                {detected || preview ? 'Try Another' : 'Upload Photo'}
              </Button>
              {detected && detected.length > 0 && (
                <Button variant="primary" size="md" className="flex-1" onClick={handleConfirm}>
                  Find Builds →
                </Button>
              )}
            </div>
          )}

          {!session && (
            <UpgradeCard
              feature="Material Scanner"
              description="Sign in and upgrade to Plus to scan your materials instantly."
            />
          )}
        </div>
      </div>
    </AppShell>
  );
}
