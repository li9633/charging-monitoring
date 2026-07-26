<script setup lang="ts">
import { ref, computed } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { restartServer } from '@/api/modules/system'

const router = useRouter()
const route = useRoute()

const activeMenu = computed(() => route.path)
const restarting = ref(false)
const isDev = import.meta.env.DEV

function navigate(path: string) {
  router.push(path)
}

async function handleRestart() {
  try {
    await ElMessageBox.confirm('重启后服务需要 3-5 秒恢复，确定要重启吗？', '确认重启进程', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning',
    })
  } catch {
    return
  }

  restarting.value = true
  try {
    await restartServer()
  } catch (e: any) {
    if (e?.response?.status === 403) {
      ElMessage.warning(e.response.data?.message || '仅开发模式可用')
      restarting.value = false
      return
    }
    // 服务可能在响应前已关闭，忽略错误，继续跳转
  }
  router.push({ name: 'Restarting', query: { from: route.fullPath } })
}
</script>

<template>
  <div class="app-shell">
    <header class="top-nav">
      <div class="nav-brand">
        <font-awesome-icon icon="bolt" class="brand-icon" />
        <span class="brand-text">充电桩监控系统</span>
      </div>
      <el-menu :default-active="activeMenu" mode="horizontal" @select="navigate" class="nav-menu">
        <el-menu-item index="/">
          <font-awesome-icon icon="chart-pie" />
          <span>仪表盘</span>
        </el-menu-item>
        <el-menu-item index="/history">
          <font-awesome-icon icon="chart-line" />
          <span>历史分析</span>
        </el-menu-item>
        <el-menu-item index="/logs">
          <font-awesome-icon icon="terminal" />
          <span>系统日志</span>
        </el-menu-item>
      </el-menu>
      <div class="nav-actions">
        <el-tooltip v-if="isDev" content="重启后端服务" placement="bottom">
          <el-button
            size="small"
            circle
            :loading="restarting"
            @click="handleRestart"
            class="restart-btn"
          >
            <font-awesome-icon v-if="!restarting" icon="arrows-rotate" />
          </el-button>
        </el-tooltip>
      </div>
    </header>

    <main class="main-content">
      <router-view />
    </main>
  </div>
</template>

<style lang="scss">
@use '../styles/variables' as *;

[v-cloak] {
  display: none;
}

body {
  font-family: $font-family;
  background: $color-bg;
  color: $color-text-primary;
  padding: 0;
  margin: 0;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}

.app-shell {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
}

.top-nav {
  display: flex;
  align-items: center;
  background: rgba(255, 255, 255, 0.72);
  backdrop-filter: saturate(180%) blur(20px);
  -webkit-backdrop-filter: saturate(180%) blur(20px);
  padding: 0 28px;
  height: 52px;
  position: sticky;
  top: 0;
  z-index: 100;
  border-bottom: 1px solid rgba(0, 0, 0, 0.08);
}

.nav-brand {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-right: 36px;
  white-space: nowrap;

  .brand-icon {
    font-size: 20px;
    color: $color-blue;
  }

  .brand-text {
    font-size: 16px;
    font-weight: $font-weight-semibold;
    color: $color-text-primary;
    letter-spacing: -0.2px;
  }
}

.nav-menu {
  flex: 1;
  background: transparent !important;
  border-bottom: none !important;

  :deep(.el-menu-item) {
    color: $color-text-secondary !important;
    border-bottom: 2px solid transparent !important;
    font-size: 13px;
    font-weight: 500;
    gap: 5px;
    height: 52px;
    line-height: 52px;
    transition:
      color $transition-fast,
      border-color $transition-fast;

    &:hover {
      color: $color-text-primary !important;
      background: transparent !important;
    }

    &.is-active {
      color: $color-blue !important;
      border-bottom-color: $color-blue !important;
      font-weight: $font-weight-semibold;
    }
  }
}

.nav-actions {
  margin-left: auto;
  display: flex;
  align-items: center;

  .restart-btn {
    color: $color-text-secondary;
    border-color: $color-border;
    transition: all $transition-fast;

    &:hover {
      color: $color-red;
      border-color: $color-red;
    }
  }
}

.main-content {
  flex: 1;
  padding: 20px;
  max-width: 1280px;
  width: 100%;
  margin: 0 auto;
  box-sizing: border-box;
}
</style>
