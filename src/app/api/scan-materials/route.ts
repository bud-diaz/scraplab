import { NextRequest, NextResponse } from 'next/server'
import { createServiceClient } from '@/lib/db/client'
import { requireAuth } from '@/lib/db/auth'
import { getUserPlan, canUsePhotoScan } from '@/lib/access'
import type { DetectedMaterial } from '@/types'

// Stubbed detection — swap body for OpenAI Vision call when ready
async function detectMaterialsFromImage(
  _imageUrl: string,
  availableMaterials: Array<{ id: string; name: string; aliases: string[] }>
): Promise<DetectedMaterial[]> {
  // Mock response using the first few materials from the DB
  // Replace this function body with Vision API call
  return availableMaterials.slice(0, 3).map((m, i) => ({
    materialId: m.id,
    label: m.name,
    confidence: parseFloat((0.95 - i * 0.08).toFixed(2)),
  }))
}

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

  let imageUrl: string | null = null

  const contentType = request.headers.get('content-type') ?? ''
  if (contentType.includes('application/json')) {
    try {
      const body = await request.json()
      imageUrl = body?.imageUrl ?? null
    } catch {
      return NextResponse.json({ error: 'Invalid JSON' }, { status: 400 })
    }
  } else if (contentType.includes('multipart/form-data')) {
    // Image upload path — store to Supabase Storage then get URL
    // Stubbed: return placeholder URL
    imageUrl = 'uploaded://stub'
  }

  if (!imageUrl) {
    return NextResponse.json(
      { error: 'Provide imageUrl in JSON body or upload an image file' },
      { status: 400 }
    )
  }

  const { data: materials } = await db
    .from('materials')
    .select('id, name, aliases')
    .order('name')

  const detectedMaterials = await detectMaterialsFromImage(imageUrl, materials ?? [])

  return NextResponse.json({
    detectedMaterials,
    requiresConfirmation: true,
  })
}
