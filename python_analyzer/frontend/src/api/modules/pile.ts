import api from '@/api/request'

export interface TagsResponse {
  all_tags: string[]
}

export function getReport(params: {
  tag?: string
  pile_no?: string
  start_date?: string
  end_date?: string
}): Promise<any> {
  return api.get('/pile/report', { params }) as any
}

export function getHistory(params: { tag?: string; pile_no?: string }): Promise<any> {
  return api.get('/pile/history', { params }) as any
}

export function getTags(): Promise<TagsResponse> {
  return api.get('/pile/tags') as any
}