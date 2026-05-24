import { GoogleGenAI } from '@google/genai'
import type { DetectedMaterial } from '@/types'

const VISION_SCHEMA = {
  type: 'object',
  properties: {
    detected: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          name:       { type: 'string' },
          confidence: { type: 'number' },
        },
        required: ['name', 'confidence'],
      },
    },
  },
  required: ['detected'],
}

export async function detectMaterialsFromImage(
  base64Image: string,
  mimeType: string,
  knownMaterials: Array<{ id: string; name: string; aliases: string[] }>
): Promise<DetectedMaterial[]> {
  const apiKey = process.env.GOOGLE_AI_API_KEY
  if (!apiKey) return []

  const materialList = knownMaterials.map(m => m.name).join(', ')

  try {
    const ai = new GoogleGenAI({ apiKey })
    const response = await ai.models.generateContent({
      model: 'gemini-2.0-flash',
      contents: [
        {
          role: 'user',
          parts: [
            { inlineData: { mimeType, data: base64Image } },
            {
              text: `You are helping identify household craft materials in a photo for a kids' craft app.

Look at this image and identify which of the following materials are clearly visible:
${materialList}

Only include materials from the list above that you can clearly see. Assign a confidence score between 0.5 and 1.0 (1.0 = very certain).`,
            },
          ],
        },
      ],
      config: {
        responseMimeType: 'application/json',
        responseSchema: VISION_SCHEMA,
      },
    })

    const parsed: { detected?: Array<{ name: string; confidence: number }> } =
      JSON.parse(response.text ?? '{}')

    return (parsed.detected ?? []).flatMap(({ name, confidence }) => {
      const lower = name.toLowerCase()
      const match = knownMaterials.find(
        m =>
          m.name.toLowerCase() === lower ||
          m.aliases.some(a => a.toLowerCase() === lower)
      )
      if (!match) return []
      return [{ materialId: match.id, label: match.name, confidence }]
    })
  } catch {
    return []
  }
}
