import { Capacitor } from '@capacitor/core'
import { Camera, CameraResultType, CameraSource } from '@capacitor/camera'

export function isNative() {
  return Capacitor.isNativePlatform()
}

/**
 * Captures a photo via the native camera and returns it as a File compatible
 * with the existing FormData upload flow. Returns null if the user cancelled
 * the native camera sheet (mirrors the web file-input cancel behavior).
 */
export async function captureNativePhoto(): Promise<File | null> {
  let photo
  try {
    photo = await Camera.getPhoto({
      resultType: CameraResultType.Uri,
      source: CameraSource.Camera,
      quality: 80,
      allowEditing: false,
    })
  } catch {
    // User cancelled, or permission was denied — either way there's no
    // photo to hand back.
    return null
  }

  if (!photo.webPath) return null
  const blob = await fetch(photo.webPath).then(r => r.blob())
  return new File([blob], `scan-${Date.now()}.jpg`, { type: blob.type || 'image/jpeg' })
}
