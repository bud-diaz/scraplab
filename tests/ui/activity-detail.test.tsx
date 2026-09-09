// @vitest-environment jsdom
import '@testing-library/jest-dom/vitest'
import { render, screen, cleanup } from '@testing-library/react'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

const mocks = vi.hoisted(() => ({ single: vi.fn() }))
vi.mock('@/lib/db/client', () => ({
  createServiceClient: () => ({
    from: () => ({ select: () => ({ or: () => ({ single: mocks.single }) }) }),
  }),
}))

import ActivityDetailPage from '@/app/explore/[slug]/page'

const baseActivity = {
  id: 'SL-001',
  title: 'Cardboard Fort',
  slug: 'cardboard-fort',
  category: 'engineering',
  one_liner: null,
  description: 'Build a fort.',
  age_ranges: ['6-8'],
  difficulty: 'easy',
  time_minutes: 30,
  estimated_cleanup_minutes: 10,
  attention_span_fit: 'short',
  energy_level: 'moderate',
  solo_or_group: 'group',
  supervision_level: 'some-help',
  environment: ['indoor'],
  materials_required: ['cardboard'],
  materials_optional: [],
  scrap_tags: [],
  theme_tags: [],
  skill_tags: [],
  prompt_type: 'guided',
  learning_angle: null,
  expansion_prompts: [],
  safety_notes: [],
  hero_image_prompt: null,
  premium: false,
  featured: false,
  seasonal: null,
  inventory_friendly: true,
  remixable: false,
  created_at: '2026-01-01T00:00:00Z',
  project_id: null as string | null,
}

beforeEach(() => {
  vi.resetAllMocks()
})

afterEach(() => {
  cleanup()
})

describe('Activity detail page — build CTA', () => {
  it('links to the build flow when a curated project is linked', async () => {
    mocks.single.mockResolvedValue({ data: { ...baseActivity, project_id: '10000000-0000-0000-0000-000000000001' }, error: null })
    const jsx = await ActivityDetailPage({ params: Promise.resolve({ slug: 'cardboard-fort' }) })
    render(jsx)

    const link = screen.getByRole('link', { name: /Let's build it!/i })
    expect(link).toHaveAttribute('href', '/projects/10000000-0000-0000-0000-000000000001')
  })

  it('shows an honest non-guided message when no project is linked', async () => {
    mocks.single.mockResolvedValue({ data: { ...baseActivity, project_id: null }, error: null })
    const jsx = await ActivityDetailPage({ params: Promise.resolve({ slug: 'cardboard-fort' }) })
    render(jsx)

    expect(screen.queryByRole('link', { name: /Let's build it!/i })).not.toBeInTheDocument()
    expect(screen.getByText(/open-ended activity/i)).toBeInTheDocument()
  })

  it('normalizes a known non-canonical supervision label instead of hiding the badge', async () => {
    mocks.single.mockResolvedValue({ data: { ...baseActivity, supervision_level: 'some-help' }, error: null })
    const jsx = await ActivityDetailPage({ params: Promise.resolve({ slug: 'cardboard-fort' }) })
    render(jsx)

    expect(screen.getByText('Adult Assist')).toBeInTheDocument()
  })

  it('renders a safe "unknown" badge instead of silently omitting the safety label', async () => {
    mocks.single.mockResolvedValue({ data: { ...baseActivity, supervision_level: 'literally-anything-else' }, error: null })
    const jsx = await ActivityDetailPage({ params: Promise.resolve({ slug: 'cardboard-fort' }) })
    render(jsx)

    expect(screen.getByText(/supervision level unknown/i)).toBeInTheDocument()
  })
})
