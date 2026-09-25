import { http } from '@/lib/http'
import type { ApiResponse, Session, User } from '@/types/api'

export async function login(email: string, password: string): Promise<Session> {
  const { data } = await http.post<ApiResponse<Session>>('/auth/login', { email, password })
  return data.data
}

export async function fetchCurrentUser(): Promise<User> {
  const { data } = await http.get<ApiResponse<User>>('/auth/me')
  return data.data
}
