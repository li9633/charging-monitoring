<script setup lang="ts">
import { ref, watch, onMounted, onUnmounted, nextTick } from 'vue'
import { fetchLogs } from '@/api/modules/logs'
import type { LogEntry } from '@/api/modules/logs'

const REFRESH_INTERVAL = 3000
const levels = ['', 'DEBUG', 'INFO', 'WARNING', 'ERROR'] as const

const logs = ref<LogEntry[]>([])
const currentLevel = ref('')
const autoRefresh = ref(true)
const logContainer = ref<HTMLElement | null>(null)
let timer: ReturnType<typeof setInterval> | null = null

async function fetchNow() {
  try {
    const res = await fetchLogs(currentLevel.value || undefined)
    logs.value = res.logs
    await nextTick()
    scrollToBottom()
  } catch (e) {
    console.error('获取日志失败:', e)
  }
}

function scrollToBottom() {
  if (logContainer.value) {
    logContainer.value.scrollTop = logContainer.value.scrollHeight
  }
}

function clearLogs() {
  logs.value = []
}

function startAutoRefresh() {
  stopAutoRefresh()
  timer = setInterval(fetchNow, REFRESH_INTERVAL)
}

function stopAutoRefresh() {
  if (timer) {
    clearInterval(timer)
    timer = null
  }
}

watch(currentLevel, () => fetchNow())

watch(autoRefresh, (val) => {
  val ? startAutoRefresh() : stopAutoRefresh()
})

onMounted(() => {
  fetchNow()
  if (autoRefresh.value) startAutoRefresh()
})

onUnmounted(() => stopAutoRefresh())
</script>

<template>
  <div v-cloak>
    <div class="page-header">
      <h1>
        <font-awesome-icon icon="terminal" />
        系统日志
      </h1>
      <p class="page-desc">实时查看系统运行日志，支持按级别筛选，3秒自动刷新</p>
    </div>

    <div class="toolbar">
      <div class="filter-group">
        <span class="filter-label">
          <font-awesome-icon icon="filter" />
          级别筛选
        </span>
        <el-radio-group v-model="currentLevel" size="small">
          <el-radio-button value="">全部</el-radio-button>
          <el-radio-button value="DEBUG">DEBUG</el-radio-button>
          <el-radio-button value="INFO">INFO</el-radio-button>
          <el-radio-button value="WARNING">WARNING</el-radio-button>
          <el-radio-button value="ERROR">ERROR</el-radio-button>
        </el-radio-group>
      </div>
      <div class="controls">
        <el-checkbox v-model="autoRefresh" size="small">自动刷新（3s）</el-checkbox>
        <el-button size="small" @click="fetchNow">
          <font-awesome-icon icon="arrows-rotate" />
          手动刷新
        </el-button>
        <el-button size="small" @click="clearLogs">
          <font-awesome-icon icon="trash" />
          清空
        </el-button>
        <span class="count">共 {{ logs.length }} 条</span>
      </div>
    </div>

    <div ref="logContainer" class="log-list">
      <div v-for="(log, i) in logs" :key="i" :class="['log-line', log.level.toLowerCase()]">
        <span class="time">{{ log.time }}</span>
        <span :class="['level', log.level.toLowerCase()]">{{ log.level }}</span>
        <span class="message">{{ log.message }}</span>
      </div>
      <div v-if="logs.length === 0" class="empty">暂无日志</div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
@use '../styles/variables' as *;

.page-header {
  background: $color-surface;
  padding: 28px 32px;
  border-radius: $radius-xl;
  margin-bottom: 16px;
  box-shadow: $shadow-md;
  border: 1px solid $color-border;

  h1 {
    font-size: 24px;
    font-weight: $font-weight-bold;
    color: $color-text-primary;
    margin: 0 0 6px;
    letter-spacing: -0.3px;
  }

  .page-desc {
    font-size: 14px;
    color: $color-text-secondary;
    margin: 0;
    line-height: 1.5;
  }
}

.toolbar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 12px 20px;
  background: $color-surface;
  border-radius: $radius-lg;
  margin-bottom: 16px;
  box-shadow: $shadow-sm;
  border: 1px solid $color-border;
  flex-wrap: wrap;
  gap: 12px;

  .filter-group {
    display: flex;
    align-items: center;
    gap: 10px;
  }

  .filter-label {
    font-size: 13px;
    font-weight: $font-weight-semibold;
    color: $color-text-secondary;
    display: flex;
    align-items: center;
    gap: 6px;
    flex-shrink: 0;
  }

  .controls {
    display: flex;
    align-items: center;
    gap: 10px;
  }

  .count {
    font-size: 12px;
    color: $color-text-secondary;
    margin-left: 4px;
  }
}

.log-list {
  background: $color-surface;
  border-radius: $radius-lg;
  overflow: hidden;
  max-height: calc(100vh - 320px);
  min-height: 400px;
  overflow-y: auto;
  font-family: 'SF Mono', 'Consolas', 'Courier New', monospace;
  font-size: 13px;
  border: 1px solid $color-border;
  box-shadow: $shadow-sm;

  &::-webkit-scrollbar {
    width: 6px;
  }

  &::-webkit-scrollbar-thumb {
    background: #d0d5dd;
    border-radius: 3px;
  }

  &::-webkit-scrollbar-track {
    background: $color-bg;
  }
}

.log-line {
  display: flex;
  gap: 10px;
  padding: 3px 16px;
  line-height: 1.7;
  border-bottom: 1px solid $color-border;

  &:hover {
    background: $color-bg;
  }

  .time {
    color: #6b7280;
    white-space: nowrap;
    min-width: 170px;
    flex-shrink: 0;
  }

  .level {
    min-width: 64px;
    font-weight: 700;
    text-align: center;
    border-radius: 3px;
    padding: 0 6px;
    font-size: 11px;
    flex-shrink: 0;
    line-height: 1.8;

    &.debug {
      color: #6b7280;
      background: #f3f4f6;
    }

    &.info {
      color: #2563eb;
      background: #dbeafe;
    }

    &.warning {
      color: #d97706;
      background: #fef3c7;
    }

    &.error {
      color: #dc2626;
      background: #fecaca;
    }
  }

  .message {
    color: $color-text-primary;
    word-break: break-all;
  }
}

.empty {
  text-align: center;
  padding: 60px 40px;
  color: $color-text-secondary;
  font-size: 14px;
}
</style>
