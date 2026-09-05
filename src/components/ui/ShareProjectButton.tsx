'use client'
import { useEffect, useState } from 'react'
import { Share } from '@capacitor/share'
import { Haptics, ImpactStyle } from '@capacitor/haptics'
import { Capacitor } from '@capacitor/core'
import { Share2 } from 'lucide-react'

interface ShareProjectButtonProps {
  title: string
  text: string
  className?: string
}

export function ShareProjectButton({ title, text, className }: ShareProjectButtonProps) {
  const [canShare, setCanShare] = useState(false)

  useEffect(() => {
    Share.canShare().then(r => setCanShare(r.value)).catch(() => setCanShare(false))
  }, [])

  if (!canShare) return null

  const handleShare = async () => {
    try {
      await Share.share({ title, text, url: window.location.href })
      if (Capacitor.isNativePlatform()) Haptics.impact({ style: ImpactStyle.Light }).catch(() => {})
    } catch {
      // user cancelled the share sheet — nothing to do
    }
  }

  return (
    <button
      onClick={handleShare}
      aria-label="Share this project"
      className={className ?? "w-9 h-9 bg-white/80 rounded-2xl flex items-center justify-center"}
    >
      <Share2 size={16} className="text-charcoal-900" />
    </button>
  )
}
