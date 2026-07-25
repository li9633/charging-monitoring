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

export function fetchLogs(level?: string, limit = 200): Promise<LogsResponse> {
  return api.get('/logs', { params: { level, limit } }).then((res) => res.data)
}
