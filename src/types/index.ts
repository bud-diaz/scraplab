export type Plan = 'free' | 'plus'

export type CleanupLevel = 'low' | 'medium' | 'high'
export type SupervisionLevel = 'independent' | 'check_in' | 'adult_assist' | 'full_supervision'
export type Difficulty = 'easy' | 'medium' | 'advanced'
export type CompletionStatus = 'started' | 'completed' | 'abandoned'
export type InventorySource = 'manual' | 'detected' | 'saved'
export type MatchType = 'exact' | 'close' | 'fallback'

export interface UserProfile {
  id: string
  email: string
  created_at: string
  plan: Plan
}

export interface ChildProfile {
  id: string
  user_id: string
  name: string | null
  age: number
  created_at: string
}

export interface Material {
  id: string
  name: string
  aliases: string[]
  category: string
  icon: string | null
  created_at: string
}

export interface BuildStep {
  step: number
  instruction: string
  tip?: string
  safety_note?: string
}

export interface Project {
  id: string
  title: string
  slug: string
  description: string
  age_min: number
  age_max: number
  time_minutes: number
  cleanup_level: CleanupLevel
  supervision_level: SupervisionLevel
  difficulty: Difficulty
  safety_notes: string[]
  instructions: BuildStep[]
  image_url: string | null
  premium_only: boolean
  created_at: string
}

export interface ProjectMaterial {
  id: string
  project_id: string
  material_id: string
  required: boolean
  quantity_note: string | null
  material?: Material
}

export interface MaterialSubstitution {
  id: string
  source_material_id: string
  replacement_material_id: string
  substitution_notes: string | null
}

export interface ProjectWithMaterials extends Project {
  project_materials: Array<ProjectMaterial & { material: Material }>
}

export interface SavedProject {
  id: string
  user_id: string
  project_id: string
  created_at: string
  project?: Project
}

export interface BuildHistory {
  id: string
  user_id: string
  project_id: string
  child_profile_id: string | null
  completion_status: CompletionStatus
  current_step: number
  started_at: string
  completed_at: string | null
  project?: Project
}

export interface HouseholdInventory {
  id: string
  user_id: string
  material_id: string
  confidence_score: number | null
  source: InventorySource
  staple_flag: boolean
  updated_at: string
  material?: Material
}

export interface RecommendationInput {
  materialIds: string[]
  childAge: number
  preferences?: {
    maxTimeMinutes?: number
    cleanupLevel?: CleanupLevel
    supervisionLevel?: SupervisionLevel
  }
}

export interface SuggestedSubstitution {
  missingMaterialId: string
  replacementMaterialId: string
  notes: string | null
}

export interface ProjectRecommendation {
  projectId: string
  title: string
  matchType: MatchType
  matchScore: number
  missingRequiredMaterials: string[]
  availableMaterialsUsed: string[]
  suggestedSubstitutions: SuggestedSubstitution[]
  reason: string
}

export interface AccessLimits {
  dailyRecommendations: number
  photoScan: boolean
  childProfiles: number
  savedProjects: number
}

export interface AccessInfo {
  plan: Plan
  limits: AccessLimits
  usage: {
    recommendationsToday: number
  }
}

export interface DetectedMaterial {
  materialId: string
  label: string
  confidence: number
}

export interface ScanResult {
  detectedMaterials: DetectedMaterial[]
  requiresConfirmation: boolean
}

export type ActivityCategory = 'cooperative' | 'science' | 'engineering' | 'storytelling' | 'pretend-play' | 'seasonal' | 'puzzle' | 'art'
export type ActivityDifficulty = 'easy' | 'medium' | 'hard' | 'adaptive'
export type ActivityEnergyLevel = 'calm' | 'moderate' | 'active' | 'chaotic-goblin'
export type ActivityAgeRange = '3-5' | '6-8' | '9-12' | '13+' | 'family'

export interface Activity {
  id: string
  title: string
  slug: string
  category: ActivityCategory
  one_liner: string | null
  description: string | null
  age_ranges: ActivityAgeRange[]
  difficulty: ActivityDifficulty
  time_minutes: number
  estimated_cleanup_minutes: number
  attention_span_fit: string
  energy_level: ActivityEnergyLevel
  solo_or_group: string
  supervision_level: string
  environment: string[]
  materials_required: string[]
  materials_optional: string[]
  scrap_tags: string[]
  theme_tags: string[]
  skill_tags: string[]
  prompt_type: string
  learning_angle: string | null
  expansion_prompts: string[]
  safety_notes: string[]
  hero_image_prompt: string | null
  premium: boolean
  featured: boolean
  seasonal: string | null
  inventory_friendly: boolean
  remixable: boolean
  created_at: string
}
