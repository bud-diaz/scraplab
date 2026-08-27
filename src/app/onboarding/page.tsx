'use client'
import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { Sparkles, Wrench, Cog, ArrowRight } from 'lucide-react'
import { cn } from '@/lib/utils'
import { useAuth } from '@/lib/auth-context'
import { Button } from '@/components/ui/Button'

const AGE_BANDS = [
  {
    id: 'little-builder',
    label: 'Little Builder',
    ageRange: '3–5',
    age: 4,
    description: 'Big, simple projects with lots of hands-on help.',
    icon: Sparkles,
  },
  {
    id: 'junior-maker',
    label: 'Junior Maker',
    ageRange: '6–8',
    age: 7,
    description: 'Multi-step builds with a check-in here and there.',
    icon: Wrench,
  },
  {
    id: 'master-crafter',
    label: 'Master Crafter',
    ageRange: '9–10',
    age: 10,
    description: 'Independent builds that take some real focus.',
    icon: Cog,
  },
]

export default function OnboardingPage() {
  const [selected, setSelected] = useState(0)
  const [saving, setSaving] = useState(false)
  const { session } = useAuth()
  const router = useRouter()

  const handleContinue = async () => {
    if (saving) return
    setSaving(true)
    try {
      if (session) {
        await fetch('/api/child-profiles', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${session.access_token}`,
          },
          body: JSON.stringify({ age: AGE_BANDS[selected].age }),
        })
      }
    } finally {
      router.replace('/')
    }
  }

  return (
    <div className="min-h-screen bg-scraplab-blue flex flex-col">
      <div className="pt-14 pb-10 px-6 text-center text-white">
        <div className="mx-auto w-16 h-16 rounded-full bg-white/15 flex items-center justify-center mb-4">
          <Sparkles size={28} />
        </div>
        <h1 className="font-heading font-bold text-2xl mb-2">Who&apos;s building today?</h1>
        <p className="text-white/80 text-sm max-w-xs mx-auto">
          Pick an age band so we can match safe, age-appropriate builds.
        </p>
      </div>

      <div className="flex-1 bg-cream-50 rounded-t-[32px] px-5 pt-8 pb-8 flex flex-col">
        <div className="flex gap-4 overflow-x-auto pb-4 px-1 snap-x snap-mandatory">
          {AGE_BANDS.map((band, i) => {
            const Icon = band.icon
            const active = i === selected
            return (
              <button
                key={band.id}
                onClick={() => setSelected(i)}
                className={cn(
                  "shrink-0 snap-center flex flex-col items-center text-center rounded-3xl transition-all duration-200",
                  active
                    ? "w-40 py-6 px-4 bg-orange-500 text-white shadow-card-lg scale-100"
                    : "w-32 py-5 px-3 bg-white text-charcoal-900 shadow-card scale-95 opacity-80"
                )}
              >
                <span className={cn(
                  "w-12 h-12 rounded-full flex items-center justify-center mb-3",
                  active ? "bg-white/20" : "bg-cream-100"
                )}>
                  <Icon size={22} className={active ? "text-white" : "text-orange-500"} />
                </span>
                <span className="font-heading font-semibold text-sm mb-1">{band.label}</span>
                <span className={cn("text-xs font-body", active ? "text-white/85" : "text-walnut-600")}>
                  Ages {band.ageRange}
                </span>
              </button>
            )
          })}
        </div>

        <p className="text-sm text-walnut-600 font-body text-center mt-6 mb-8 px-4">
          {AGE_BANDS[selected].description}
        </p>

        <div className="mt-auto">
          <Button
            variant="primary"
            size="lg"
            className="w-full justify-center gap-2"
            onClick={handleContinue}
            disabled={saving}
          >
            {saving ? "Setting up…" : "Let's Build"}
            <ArrowRight size={17} />
          </Button>
        </div>
      </div>
    </div>
  )
}
