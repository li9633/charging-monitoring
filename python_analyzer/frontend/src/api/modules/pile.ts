import api from '@/api/request'

export interface TagsResponse {
  all_tags: string[]
}

export function getReport(params: {
  tag?: string
  pile_no?: string
  start_date?: string
  end_date?: string
}) {
  return api.get('/pile/report', { params })
}

export function getHistory(params: { tag?: string; pile_no?: string }) {
  return api.get('/pile/history', { params })
}

export function getTags() {
  return api.get('/pile/tags')
}