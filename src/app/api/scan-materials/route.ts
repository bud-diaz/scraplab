import { NextRequest, NextResponse } from 'next/server'
import { createServiceClient } from '@/lib/db/client'
import { requireAuth } from '@/lib/db/auth'
import { getUserPlan, canUsePhotoScan } from '@/lib/access'
import { detectMaterialsFromImage } from '@/lib/ai/vision'

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

  const { data: materials } = await db
    .from('materials')
    .select('id, name, aliases')
    .order('name')

  const knownMaterials = materials ?? []

  const contentType = request.headers.get('content-type') ?? ''

  if (contentType.includes('multipart/form-data')) {
    let formData: FormData
    try {
      formData = await request.formData()
    } catch {
      return NextResponse.json({ error: 'Invalid form data' }, { status: 400 })
    }

    const file = formData.get('image') as File | null
    if (!file) {
      return NextResponse.json({ error: 'No image file provided (field name: image)' }, { status: 400 })
    }

    const buffer = await file.arrayBuffer()
    const base64 = Buffer.from(buffer).toString('base64')
    const mimeType = file.type || 'image/jpeg'

    const detectedMaterials = await detectMaterialsFromImage(base64, mimeType, knownMaterials)
    return NextResponse.json({ detectedMaterials, requiresConfirmation: true })
  }

  if (contentType.includes('application/json')) {
    let imageUrl: string | null = null
    try {
      const body = await request.json()
      imageUrl = body?.imageUrl ?? null
    } catch {
      return NextResponse.json({ error: 'Invalid JSON' }, { status: 400 })
    }

    if (!imageUrl) {
      return NextResponse.json(
        { error: 'Provide imageUrl in JSON body or upload an image file' },
        { status: 400 }
      )
    }

    let base64: string
    let mimeType: string
    try {
      const imageRes = await fetch(imageUrl)
      if (!imageRes.ok) throw new Error('Failed to fetch image')
      mimeType = imageRes.headers.get('content-type') || 'image/jpeg'
      const buffer = await imageRes.arrayBuffer()
      base64 = Buffer.from(buffer).toString('base64')
    } catch {
      return NextResponse.json({ error: 'Could not fetch image from URL' }, { status: 400 })
    }

    const detectedMaterials = await detectMaterialsFromImage(base64, mimeType, knownMaterials)
    return NextResponse.json({ detectedMaterials, requiresConfirmation: true })
  }

  return NextResponse.json(
    { error: 'Provide imageUrl in JSON body or upload an image file' },
    { status: 400 }
  )
}
