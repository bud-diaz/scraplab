// @vitest-environment jsdom
import '@testing-library/jest-dom/vitest'
import { render, screen, fireEvent, waitFor, cleanup } from '@testing-library/react'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

const mocks = vi.hoisted(() => ({ replace: vi.fn(), push: vi.fn() }))
vi.mock('next/navigation', () => ({
  useRouter: () => ({ replace: mocks.replace, push: mocks.push }),
  usePathname: () => '/library',
}))

afterEach(() => {
  cleanup()
  vi.unstubAllGlobals()
})

describe('Library — backend failure vs empty state', () => {
  beforeEach(() => {
    vi.resetModules()
    vi.doMock('@/lib/auth-context', () => ({
      useAuth: () => ({ session: { access_token: 'tok', user: { id: 'user-1' } }, user: { id: 'user-1' }, loading: false }),
    }))
  })

  it('shows a retryable error instead of an empty library on fetch failure, then loads on retry', async () => {
    let libraryShouldFail = true
    const fetchMock = vi.fn((input: RequestInfo | URL) => {
      const url = String(input)
      if (url.includes('/api/saved-projects') || url.includes('/api/build-history')) {
        if (libraryShouldFail) return Promise.resolve(new Response('down', { status: 500 }))
        return Promise.resolve(
          new Response(JSON.stringify({ savedProjects: [], buildHistory: [] }), { status: 200 }),
        )
      }
      // Unrelated dashboard chrome (e.g. PlanUsageIndicator) — not under test here.
      return Promise.resolve(
        new Response(JSON.stringify({ plan: 'free', limits: {}, usage: { recommendationsToday: 0 } }), { status: 200 }),
      )
    })
    vi.stubGlobal('fetch', fetchMock)

    const { default: LibraryPage } = await import('@/app/library/page')
    render(<LibraryPage />)

    await waitFor(() => expect(screen.getByText(/couldn't load your library/i)).toBeInTheDocument())
    // Must not fall through to the "empty" state, which would look like lost data.
    expect(screen.queryByText(/workshop shelf is empty/i)).not.toBeInTheDocument()

    libraryShouldFail = false
    fireEvent.click(screen.getByRole('button', { name: /retry/i }))

    await waitFor(() => expect(screen.getByText(/workshop shelf is empty/i)).toBeInTheDocument())
  })
})

describe('Onboarding — surfaces save failures instead of navigating away', () => {
  beforeEach(() => {
    vi.resetModules()
    vi.doMock('@/lib/auth-context', () => ({
      useAuth: () => ({ session: { access_token: 'tok', user: { id: 'user-1' } }, user: { id: 'user-1' }, loading: false }),
    }))
  })

  it('shows an error and stays on the page when the child-profile POST fails', async () => {
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue(new Response('down', { status: 500 })))

    const { default: OnboardingPage } = await import('@/app/onboarding/page')
    render(<OnboardingPage />)

    fireEvent.click(screen.getByRole('button', { name: /let's build/i }))

    await waitFor(() => expect(screen.getByText(/couldn't save that/i)).toBeInTheDocument())
    expect(mocks.replace).not.toHaveBeenCalled()
  })

  it('navigates home once the save succeeds', async () => {
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue(new Response('{}', { status: 201 })))

    const { default: OnboardingPage } = await import('@/app/onboarding/page')
    render(<OnboardingPage />)

    fireEvent.click(screen.getByRole('button', { name: /let's build/i }))

    await waitFor(() => expect(mocks.replace).toHaveBeenCalledWith('/'))
  })
})
