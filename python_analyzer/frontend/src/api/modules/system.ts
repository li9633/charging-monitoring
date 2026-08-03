import type { AxiosRequestConfig } from 'axios'
import api from '@/api/request'

export interface LogEntry {
  time: string
  level: 'DEBUG' | 'INFO' | 'WARNING' | 'ERROR'
  message: string
}

export interface LogsResponse {
  logs: LogEntry[]
  total: number
}

export interface HealthResponse {
  status: string
}

export interface RestartResponse {
  message: string
}

function noErrorHandler(): AxiosRequestConfig {
  return { skipErrorHandler: true } as AxiosRequestConfig
}

export function getLogs(params: { level?: string; limit?: number }): Promise<LogsResponse> {
  return api.get('/system/logs', { params }) as Promise<LogsResponse>
}

export function healthCheck(): Promise<HealthResponse> {
  return api.get('/system/health', noErrorHandler()) as Promise<HealthResponse>
}

export function getVersion(): Promise<{ version: number }> {
  return api.get('/system/version') as Promise<{ version: number }>
}

export function restartServer(): Promise<RestartResponse> {
  return api.post('/system/restart', undefined, noErrorHandler()) as Promise<RestartResponse>
}
