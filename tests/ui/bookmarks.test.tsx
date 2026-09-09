// @vitest-environment jsdom
import '@testing-library/jest-dom/vitest'
import { render, screen, fireEvent, waitFor, cleanup } from '@testing-library/react'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

vi.mock('@/lib/auth-context', () => ({
  useAuth: () => ({ session: { access_token: 'test-token' }, user: { id: 'user-1' }, loading: false }),
}))

import { ProjectCard, type ProjectCardProject } from '@/components/cards/ProjectCard'

const baseProject: ProjectCardProject = {
  id: '10000000-0000-0000-0000-000000000001',
  title: 'Cardboard Rocket',
  emoji: '🚀',
  bgColor: 'bg-builder-100',
  timeEstimate: '30 min',
  cleanupLevel: 'low',
  ageRange: '5-8',
}

beforeEach(() => {
  vi.stubGlobal('fetch', vi.fn())
})

afterEach(() => {
  cleanup()
})

describe('ProjectCard bookmark lifecycle', () => {
  it('saves a project and reflects the saved state', async () => {
    ;(fetch as ReturnType<typeof vi.fn>).mockResolvedValue(
      new Response(JSON.stringify({ savedProject: { id: 'saved-1' } }), { status: 201 }),
    )

    render(<ProjectCard project={baseProject} />)
    const button = screen.getByRole('button', { name: 'Save project' })
    fireEvent.click(button)

    await waitFor(() => expect(screen.getByRole('button', { name: 'Remove from saved' })).toBeInTheDocument())
    expect(fetch).toHaveBeenCalledWith(
      '/api/saved-projects',
      expect.objectContaining({ method: 'POST', body: JSON.stringify({ projectId: baseProject.id }) }),
    )
  })

  it('unsaves via the saved-projects row id, not the project id', async () => {
    ;(fetch as ReturnType<typeof vi.fn>).mockResolvedValue(new Response(null, { status: 204 }))

    render(<ProjectCard project={baseProject} initialSaved savedProjectId="saved-42" />)
    const button = screen.getByRole('button', { name: 'Remove from saved' })
    fireEvent.click(button);

    await waitFor(() => expect(screen.getByRole('button', { name: 'Save project' })).toBeInTheDocument())
    expect(fetch).toHaveBeenCalledWith('/api/saved-projects/saved-42', expect.objectContaining({ method: 'DELETE' }))
  })

  it('disables bookmarking for a sample project whose id is not a persisted UUID', () => {
    render(<ProjectCard project={{ ...baseProject, id: 'cardboard-rocket' }} />)
    const button = screen.getByRole('button', { name: 'Save project' })
    expect(button).toBeDisabled()

    fireEvent.click(button)
    expect(fetch).not.toHaveBeenCalled()
  })

  it('surfaces a save failure instead of silently staying unsaved', async () => {
    ;(fetch as ReturnType<typeof vi.fn>).mockResolvedValue(new Response(JSON.stringify({ error: 'boom' }), { status: 500 }))

    render(<ProjectCard project={baseProject} />)
    fireEvent.click(screen.getByRole('button', { name: 'Save project' }))

    await waitFor(() => expect(screen.getByRole('status')).toHaveTextContent('Could not save'))
    // Still shows as unsaved — no false-positive success state.
    expect(screen.getByRole('button', { name: 'Save project' })).toBeInTheDocument()
  })

  it('surfaces the plan-limit error on a 429', async () => {
    ;(fetch as ReturnType<typeof vi.fn>).mockResolvedValue(
      new Response(JSON.stringify({ error: 'Saved project limit reached', upgradeRequired: true }), { status: 429 }),
    )

    render(<ProjectCard project={baseProject} />)
    fireEvent.click(screen.getByRole('button', { name: 'Save project' }))

    await waitFor(() => expect(screen.getByRole('status')).toHaveTextContent(/limit reached/i))
  })
})
