"use client";
import { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import { useAuth } from "@/lib/auth-context";
import { cn } from "@/lib/utils";

export default function AuthPage() {
  const { user, loading, signIn, signUp } = useAuth();
  const router = useRouter();
  const [mode, setMode] = useState<"signin" | "signup">("signin");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [confirmed, setConfirmed] = useState(false);

  // Already signed in — send home
  useEffect(() => {
    if (!loading && user) router.replace("/");
  }, [user, loading, router]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSubmitting(true);
    setError(null);

    if (mode === "signin") {
      const { error } = await signIn(email, password);
      if (error) {
        setError(error.message);
        setSubmitting(false);
      } else {
        router.replace("/");
      }
    } else {
      const { error, needsConfirmation } = await signUp(email, password);
      if (error) {
        setError(error.message);
        setSubmitting(false);
      } else if (needsConfirmation) {
        setConfirmed(true);
        setSubmitting(false);
      } else {
        router.replace("/");
      }
    }
  };

  if (loading) return null;

  return (
    <div className="min-h-screen bg-cream-50 flex flex-col items-center justify-center px-4">
      <div className="w-full max-w-sm">
        {/* Logo */}
        <div className="flex flex-col items-center mb-8">
          <div className="w-14 h-14 bg-builder-500 rounded-2xl flex items-center justify-center mb-3 shadow-card">
            <span className="text-white font-heading font-bold text-xl">SL</span>
          </div>
          <h1 className="font-heading font-bold text-2xl text-charcoal-900">ScrapLab</h1>
          <p className="text-sm text-walnut-600 font-body mt-0.5">Build More. Buy Less.</p>
        </div>

        {confirmed ? (
          <div className="bg-white rounded-3xl shadow-card p-8 text-center">
            <div className="text-4xl mb-4">📬</div>
            <h2 className="font-heading font-bold text-lg text-charcoal-900 mb-2">Check your email</h2>
            <p className="text-sm text-walnut-600 font-body">
              We sent a confirmation link to <span className="font-medium text-charcoal-900">{email}</span>.
              Click it to activate your account.
            </p>
            <button
              onClick={() => { setConfirmed(false); setMode("signin"); }}
              className="mt-6 text-sm text-builder-500 font-heading font-semibold hover:underline"
            >
              Back to sign in
            </button>
          </div>
        ) : (
          <div className="bg-white rounded-3xl shadow-card p-6">
            {/* Mode tabs */}
            <div className="flex bg-cream-100 rounded-2xl p-1 mb-6">
              {(["signin", "signup"] as const).map(m => (
                <button
                  key={m}
                  onClick={() => { setMode(m); setError(null); }}
                  className={cn(
                    "flex-1 py-2 text-sm font-heading font-semibold rounded-xl transition-all",
                    mode === m
                      ? "bg-white text-charcoal-900 shadow-card"
                      : "text-walnut-600 hover:text-charcoal-900"
                  )}
                >
                  {m === "signin" ? "Sign In" : "Sign Up"}
                </button>
              ))}
            </div>

            <form onSubmit={handleSubmit} className="space-y-4">
              <div>
                <label className="block text-xs font-heading font-semibold text-charcoal-900 mb-1.5">
                  Email
                </label>
                <input
                  type="email"
                  required
                  autoComplete="email"
                  value={email}
                  onChange={e => setEmail(e.target.value)}
                  placeholder="you@example.com"
                  className="w-full px-4 py-3 bg-cream-50 border border-kraft-300 rounded-2xl text-sm font-body text-charcoal-900 placeholder-walnut-400 focus:outline-none focus:border-builder-500 transition-colors"
                />
              </div>

              <div>
                <label className="block text-xs font-heading font-semibold text-charcoal-900 mb-1.5">
                  Password
                </label>
                <input
                  type="password"
                  required
                  autoComplete={mode === "signin" ? "current-password" : "new-password"}
                  value={password}
                  onChange={e => setPassword(e.target.value)}
                  placeholder="••••••••"
                  minLength={6}
                  className="w-full px-4 py-3 bg-cream-50 border border-kraft-300 rounded-2xl text-sm font-body text-charcoal-900 placeholder-walnut-400 focus:outline-none focus:border-builder-500 transition-colors"
                />
                {mode === "signup" && (
                  <p className="text-xs text-walnut-500 mt-1 ml-1">Minimum 6 characters</p>
                )}
              </div>

              {error && (
                <div className="bg-red-50 border border-red-200 rounded-2xl px-4 py-3 text-sm text-red-600">
                  {error}
                </div>
              )}

              <button
                type="submit"
                disabled={submitting}
                className="w-full bg-builder-500 hover:bg-builder-600 disabled:opacity-50 disabled:cursor-not-allowed text-white font-heading font-semibold text-sm py-3 rounded-2xl transition-colors"
              >
                {submitting
                  ? (mode === "signin" ? "Signing in…" : "Creating account…")
                  : (mode === "signin" ? "Sign In" : "Create Account")}
              </button>
            </form>
          </div>
        )}

        <p className="text-center text-xs text-walnut-500 mt-6 font-body">
          By signing up you agree to our terms of service.
        </p>
      </div>
    </div>
  );
}
