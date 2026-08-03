import api from '@/api/request'

export interface HourData {
  hour: number
  label: string
  checks: number
  offline: number
  rate: number
  css_class: string
}

export interface PileData {
  pile_no: string
  location: string
  loc_display: string
  total_checks: number
  total_offline: number
  online: number
  offline_rate: number
  status: string
  status_color: string
  suspicious_ranges: string
  hours: HourData[]
}

export interface ReportResponse {
  min_time: string
  max_time: string
  total: number
  last_check: string
  piles: PileData[]
}

export interface TagsResponse {
  all_tags: string[]
}

export function getReport(params: {
  tag?: string
  pile_no?: string
  start_date?: string
  end_date?: string
}): Promise<ReportResponse> {
  return api.get('/pile/report', { params }) as Promise<ReportResponse>
}

export function getHistory(params: { tag?: string; pile_no?: string }): Promise<ReportResponse> {
  return api.get('/pile/history', { params }) as Promise<ReportResponse>
}

export function getTags(): Promise<TagsResponse> {
  return api.get('/pile/tags') as Promise<TagsResponse>
}
