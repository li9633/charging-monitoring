import axios from 'axios'

const api = axios.create({
  baseURL: '/api',
  timeout: 10000,
})

api.interceptors.response.use(
  (response) => response,
  (error) => {
    console.error('请求失败:', error.config?.url, error.message)
    ElMessage.error(error.message || '请求失败')
    return Promise.reject(error)
  },
)

export default api
