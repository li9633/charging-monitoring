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

export function getLogs(params: { level?: string; limit?: number }): Promise<LogsResponse> {
  return api.get('/system/logs', { params }) as any
}

export function healthCheck(): Promise<any> {
  return api.get('/system/health', { skipErrorHandler: true } as any) as any
}

export function getVersion(): Promise<{ version: number }> {
  return api.get('/system/version') as any
}

export function restartServer(): Promise<any> {
  return api.post('/system/restart', undefined, { skipErrorHandler: true } as any) as any
}