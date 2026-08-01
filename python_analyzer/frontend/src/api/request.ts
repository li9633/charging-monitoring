import axios from 'axios'

const api = axios.create({
  baseURL: '/api',
  timeout: 10000,
})


api.interceptors.response.use(
  (response) => {
    const body = response.data
    if (body && typeof body.code === 'number') {
      if (body.code !== 200) {
        const err: any = new Error(body.message || '请求失败')
        err.response = { status: body.code, data: body }
        return Promise.reject(err)
      }
      return body.data ?? null
    }
    return body
  },
  (error) => {
    if (error.config?.skipErrorHandler) {
      return Promise.reject(error)
    }
    console.error('请求失败:', error.config?.url, error.message)
    ElMessage.error(error.message || '请求失败')
    return Promise.reject(error)
  },
)

export default api