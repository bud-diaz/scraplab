'use client'
import { useEffect } from 'react'
import { Capacitor } from '@capacitor/core'
import { StatusBar, Style } from '@capacitor/status-bar'
import { SplashScreen } from '@capacitor/splash-screen'
import { Keyboard, KeyboardResize } from '@capacitor/keyboard'
import { App } from '@capacitor/app'

// Mounted once at the root layout. Runs native-only setup that has no web
// equivalent: status bar style, keyboard resize behavior, hiding the splash
// screen as soon as this client bundle has hydrated (capacitor.config.ts also
// sets launchShowDuration as a backstop, so a page that never loads can't
// leave the splash up forever), and refreshing plan state on foreground so a
// purchase or renewal that happened while backgrounded is reflected without a relaunch
// (see src/app/subscription/page.tsx and UpgradeActions.tsx, which listen
// for the 'scraplab:refresh-plan' event this dispatches).
export function NativeBootstrap() {
  useEffect(() => {
    if (!Capacitor.isNativePlatform()) return

    StatusBar.setStyle({ style: Style.Dark }).catch(() => {})
    Keyboard.setResizeMode({ mode: KeyboardResize.Body }).catch(() => {})
    SplashScreen.hide().catch(() => {})

    let listenerHandle: { remove: () => void } | undefined
    App.addListener('appStateChange', ({ isActive }) => {
      if (isActive) window.dispatchEvent(new Event('scraplab:refresh-plan'))
    }).then(handle => { listenerHandle = handle })

    return () => { listenerHandle?.remove() }
  }, [])

  return null
}
