import { createRouter, createWebHistory } from 'vue-router'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/',
      component: () => import('@/layouts/AppLayout.vue'),
      children: [
        {
          path: '',
          name: 'Dashboard',
          component: () => import('@/views/DashBoard.vue'),
        },
        {
          path: 'logs',
          name: 'LogViewer',
          component: () => import('@/views/LogViewer.vue'),
        },
        {
          path: 'history',
          name: 'HistoryAnalysis',
          component: () => import('@/views/HistoryAnalysis.vue'),
        },
      ],
    },
    {
      path: '/restarting',
      name: 'Restarting',
      component: () => import('@/views/Restarting.vue'),
    },
  ],
})

export default router
