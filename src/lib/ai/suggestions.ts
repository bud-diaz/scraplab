import { GoogleGenAI } from '@google/genai'

export interface AiSuggestion {
  title: string
  description: string
  timeMinutes: number
  cleanupLevel: string
  supervisionLevel: string
  difficulty: string
  steps: string[]
  materialsNeeded: string[]
}

const RESPONSE_SCHEMA = {
  type: 'object',
  properties: {
    activities: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          title:             { type: 'string' },
          description:       { type: 'string' },
          timeMinutes:       { type: 'number' },
          cleanupLevel:      { type: 'string', enum: ['low', 'medium', 'high'] },
          supervisionLevel:  { type: 'string', enum: ['full_supervision', 'adult_assist', 'check_in', 'independent'] },
          difficulty:        { type: 'string', enum: ['easy', 'medium', 'advanced'] },
          steps:             { type: 'array', items: { type: 'string' } },
          materialsNeeded:   { type: 'array', items: { type: 'string' } },
        },
        required: ['title', 'description', 'timeMinutes', 'cleanupLevel',
                   'supervisionLevel', 'difficulty', 'steps', 'materialsNeeded'],
      },
    },
  },
  required: ['activities'],
}

export interface AiSuggestionPreferences {
  maxTimeMinutes?: number
  cleanupLevel?: string
  supervisionLevel?: string
}

export async function generateAiSuggestions(
  materialNames: string[],
  childAge: number,
  count = 3,
  preferences?: AiSuggestionPreferences
): Promise<AiSuggestion[]> {
  const apiKey = process.env.GOOGLE_AI_API_KEY
  if (!apiKey) return []

  const maxTime = preferences?.maxTimeMinutes ?? 60
  const extraConstraints = [
    preferences?.cleanupLevel ? `- Keep cleanup effort at "${preferences.cleanupLevel}" or lower` : null,
    preferences?.supervisionLevel ? `- Match a supervisionLevel of "${preferences.supervisionLevel}"` : null,
  ].filter(Boolean).join('\n')

  try {
    const ai = new GoogleGenAI({ apiKey })
    const response = await ai.models.generateContent({
      model: 'gemini-2.0-flash',
      contents: `You help parents find creative craft projects for kids using household materials.

The child is ${childAge} years old. Available materials: ${materialNames.join(', ')}.

Suggest ${count} different craft projects this child can make RIGHT NOW using only those materials. Each must:
- Use ONLY materials from the list above (list which ones in materialsNeeded)
- Be completable in under ${maxTime} minutes
- Be safe and age-appropriate for a ${childAge}-year-old
- Have 4-6 clear, concise step-by-step instructions in the steps array
${extraConstraints}`,
      config: {
        responseMimeType: 'application/json',
        responseSchema: RESPONSE_SCHEMA,
      },
    })

    const parsed: { activities?: AiSuggestion[] } = JSON.parse(response.text ?? '{}')
    return (parsed.activities ?? []).slice(0, count)
  } catch {
    return []
  }
}
