import { Capacitor } from '@capacitor/core'
import { Purchases, LOG_LEVEL } from '@revenuecat/purchases-capacitor'
import type { PurchasesPackage } from '@revenuecat/purchases-capacitor'

// The entitlement identifier configured in the RevenueCat dashboard for
// ScrapLab Plus. Keep in sync with the RevenueCat project config.
const PLUS_ENTITLEMENT = 'plus'

export function isNativeIOS() {
  return Capacitor.isNativePlatform() && Capacitor.getPlatform() === 'ios'
}

let configured = false

/** Call once per session, after Supabase auth resolves a signed-in user. */
export async function configureRevenueCat(userId: string) {
  if (!isNativeIOS() || configured) return
  const apiKey = process.env.NEXT_PUBLIC_REVENUECAT_IOS_API_KEY
  if (!apiKey) {
    console.warn('NEXT_PUBLIC_REVENUECAT_IOS_API_KEY is not set — skipping RevenueCat configuration.')
    return
  }
  await Purchases.configure({ apiKey, appUserID: userId })
  await Purchases.setLogLevel({ level: LOG_LEVEL.WARN })
  configured = true
}

export async function getPlusPackage(): Promise<PurchasesPackage | null> {
  const offerings = await Purchases.getOfferings()
  return offerings.current?.monthly ?? offerings.current?.availablePackages[0] ?? null
}

export async function purchasePlus(pkg: PurchasesPackage): Promise<boolean> {
  const { customerInfo } = await Purchases.purchasePackage({ aPackage: pkg })
  return customerInfo.entitlements.active[PLUS_ENTITLEMENT] != null
}

export async function restorePurchases(): Promise<boolean> {
  const { customerInfo } = await Purchases.restorePurchases()
  return customerInfo.entitlements.active[PLUS_ENTITLEMENT] != null
}

/** URL to Apple's native "manage subscription" screen for the current user, if any. */
export async function getManagementURL(): Promise<string | null> {
  const { customerInfo } = await Purchases.getCustomerInfo()
  return customerInfo.managementURL
}
