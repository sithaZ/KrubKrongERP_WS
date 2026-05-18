export const API_BASE = 'http://localhost:3000/api'

export class ApiError extends Error {
  status: number

  constructor(message: string, status = 500) {
    super(message)
    this.status = status
  }
}

export const authHeaders = (includeJson = true) => {
  const token = localStorage.getItem('token')
  return {
    ...(includeJson ? { 'Content-Type': 'application/json' } : {}),
    ...(token ? { Authorization: `Bearer ${token}` } : {}),
  }
}

export const readApiError = async (response: Response) => {
  try {
    const data = await response.json()
    if (typeof data?.message === 'string' && data.message.trim()) {
      return data.message
    }

    if (Array.isArray(data?.message) && data.message.length > 0) {
      return String(data.message[0])
    }
  } catch {
    // Ignore parse failures and fall back to status text.
  }

  return response.statusText || 'Request failed'
}

export const apiFetch = async <T>(path: string, init?: RequestInit): Promise<T> => {
  const response = await fetch(`${API_BASE}${path}`, {
    ...init,
    headers: {
      ...authHeaders(!(init?.body instanceof FormData)),
      ...(init?.headers || {}),
    },
  })

  if (!response.ok) {
    throw new ApiError(await readApiError(response), response.status)
  }

  if (response.status === 204) {
    return undefined as T
  }

  return response.json() as Promise<T>
}
