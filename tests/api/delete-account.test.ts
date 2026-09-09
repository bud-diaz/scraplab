import { beforeEach, expect, it, vi } from 'vitest'
import { NextRequest } from 'next/server'
const m = vi.hoisted(() => ({ auth: vi.fn(), single: vi.fn(), deleteUser: vi.fn(), list: vi.fn(), cancel: vi.fn() }))
vi.mock('@/lib/db/auth', () => ({ requireAuth: m.auth }))
vi.mock('@/lib/db/client', () => ({ createServiceClient: () => ({ from: () => ({ select: () => ({ eq: () => ({ single: m.single }) }) }), auth: { admin: { deleteUser: m.deleteUser } } }) }))
vi.mock('@/lib/stripe', () => ({ getStripe: () => ({ subscriptions: { list: m.list, cancel: m.cancel } }) }))
import { DELETE } from '@/app/api/me/delete-account/route'
const request = () => new NextRequest('http://localhost/api/me/delete-account', { method: 'DELETE' })
beforeEach(() => {
  vi.resetAllMocks()
  m.auth.mockResolvedValue({ user: { id: 'user-1' } })
  m.single.mockResolvedValue({ data: { stripe_customer_id: 'cus_test' }, error: null })
  m.deleteUser.mockResolvedValue({ error: null })
  m.cancel.mockResolvedValue({})
})
it('paginates all statuses and cancels every nonterminal subscription', async () => {
  m.list.mockResolvedValueOnce({ data: [{ id: 's1', status: 'trialing' }, { id: 's2', status: 'canceled' }], has_more: true }).mockResolvedValueOnce({ data: [{ id: 's3', status: 'past_due' }], has_more: false })
  expect((await DELETE(request())).status).toBe(204)
  expect(m.list).toHaveBeenNthCalledWith(1, { customer: 'cus_test', status: 'all', limit: 100 })
  expect(m.list).toHaveBeenNthCalledWith(2, { customer: 'cus_test', status: 'all', limit: 100, starting_after: 's2' })
  expect(m.cancel.mock.calls.map(c => c[0])).toEqual(['s1', 's3'])
})

it('skips Stripe entirely when the profile has no stripe_customer_id', async () => {
  m.single.mockResolvedValue({ data: { stripe_customer_id: null }, error: null })
  expect((await DELETE(request())).status).toBe(204)
  expect(m.list).not.toHaveBeenCalled()
  expect(m.deleteUser).toHaveBeenCalledWith('user-1')
})

it('still deletes the account when Stripe cancellation fails', async () => {
  m.list.mockRejectedValue(new Error('stripe down'))
  const res = await DELETE(request())
  expect(res.status).toBe(204)
  expect(m.deleteUser).toHaveBeenCalledWith('user-1')
})

it('returns 500 and does not delete the account if auth admin deleteUser fails', async () => {
  m.list.mockResolvedValue({ data: [], has_more: false })
  m.deleteUser.mockResolvedValue({ error: { message: 'boom' } })
  const res = await DELETE(request())
  expect(res.status).toBe(500)
})
