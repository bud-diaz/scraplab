import { NextRequest, NextResponse } from 'next/server'
import { createServiceClient } from '@/lib/db/client'
import { requireAuth } from '@/lib/db/auth'
import { getUserPlan, canUsePhotoScan } from '@/lib/access'
import { detectMaterialsFromImage } from '@/lib/ai/vision'

const MAX_IMAGE_BYTES = 5 * 1024 * 1024
const ALLOWED_MIME_TYPES = new Set(['image/jpeg', 'image/png', 'image/webp', 'image/heic', 'image/heif'])

export async function POST(request: NextRequest) {
  const { user, error } = await requireAuth(request)
  if (error) return error

  const db = createServiceClient()
  const plan = await getUserPlan(db, user.id)

  if (!canUsePhotoScan(plan)) {
    return NextResponse.json(
      { error: 'Photo scan requires ScrapLab Plus', upgradeRequired: true },
      { status: 403 }
    )
  }

  const contentType = request.headers.get('content-type') ?? ''
  if (!contentType.includes('multipart/form-data')) {
    return NextResponse.json(
      { error: 'Upload an image as multipart/form-data (field name: image)' },
      { status: 415 }
    )
  }

  let formData: FormData
  try {
    formData = await request.formData()
  } catch {
    return NextResponse.json({ error: 'Invalid form data' }, { status: 400 })
  }

  const file = formData.get('image')
  if (!(file instanceof File)) {
    return NextResponse.json({ error: 'No image file provided (field name: image)' }, { status: 400 })
  }

  if (file.size === 0) {
    return NextResponse.json({ error: 'Image file is empty' }, { status: 400 })
  }

  if (file.size > MAX_IMAGE_BYTES) {
    return NextResponse.json({ error: 'Image exceeds the 5 MB limit' }, { status: 413 })
  }

  if (!ALLOWED_MIME_TYPES.has(file.type)) {
    return NextResponse.json({ error: `Unsupported image type: ${file.type || 'unknown'}` }, { status: 415 })
  }

  const { data: materials } = await db
    .from('materials')
    .select('id, name, aliases')
    .order('name')

  const buffer = await file.arrayBuffer()
  const base64 = Buffer.from(buffer).toString('base64')

  const detectedMaterials = await detectMaterialsFromImage(base64, file.type, materials ?? [])
  return NextResponse.json({ detectedMaterials, requiresConfirmation: true })
}
