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

export function getLogs(params: { level?: string; limit?: number }) {
  return api.get('/system/logs', { params })
}

export function healthCheck() {
  return api.get('/system/health', { skipErrorHandler: true } as any)
}

export function getVersion() {
  return api.get('/system/version')
}

export function restartServer() {
  return api.post('/system/restart', undefined, { skipErrorHandler: true } as any)
}