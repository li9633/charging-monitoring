<script setup lang="ts">
import { ref, computed, onMounted, onBeforeUnmount } from 'vue'
import StatCards from '../components/StatCards.vue'
import TodayTimeline from '../components/TodayTimeline.vue'
import PileCard from '../components/PileCard.vue'

interface HourData {
  hour: number
  label: string
  checks: number
  offline: number
  rate: number
  css_class: string
}

interface PileData {
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
  activeNames: string[]
  tagType: string
}

interface ReportData {
  min_time: string
  max_time: string
  total: number
  last_check: string
  piles: PileData[]
}

interface TodayHour {
  hour: number
  label: string
  checks: number
  offline: number
  status: 'online' | 'offline' | 'nodata'
}

interface TodayPile {
  pile_no: string
  location: string
  loc_display: string
  total_checks: number
  total_offline: number
  hours: TodayHour[]
}

interface TodayData {
  date: string
  piles: TodayPile[]
}

const data = ref<ReportData | null>(null)
const today = ref<TodayData | null>(null)
const loading = ref(true)
const error = ref(false)
const countdown = ref(60)

const sortedPiles = computed<PileData[]>(() => {
  if (!data.value) return []
  return [...data.value.piles]
    .map((p) => ({
      ...p,
      activeNames: [],
      tagType: p.offline_rate >= 50 ? 'danger' : p.offline_rate >= 20 ? 'warning' : 'success',
    }))
    .sort((a, b) => a.pile_no.localeCompare(b.pile_no))
})

const counts = computed(() => {
  const piles = sortedPiles.value
  return {
    critical: piles.filter((p) => p.offline_rate >= 50).length,
    warning: piles.filter((p) => p.offline_rate >= 20 && p.offline_rate < 50).length,
    normal: piles.filter((p) => p.offline_rate < 20).length,
  }
})

async function fetchData() {
  try {
    const [reportRes, todayRes] = await Promise.all([fetch('/api/report'), fetch('/api/today')])
    if (!reportRes.ok) throw new Error(String(reportRes.status))
    data.value = await reportRes.json()
    if (todayRes.ok) today.value = await todayRes.json()
    error.value = false
    countdown.value = 60
  } catch (e) {
    console.error('数据获取失败:', e)
    error.value = !data.value
  } finally {
    loading.value = false
  }
}

let timer: ReturnType<typeof setInterval> | undefined
let cd: ReturnType<typeof setInterval> | undefined

onMounted(() => {
  fetchData()
  timer = setInterval(fetchData, 60000)
  cd = setInterval(() => {
    countdown.value = countdown.value > 1 ? countdown.value - 1 : 60
  }, 1000)
})

onBeforeUnmount(() => {
  clearInterval(timer)
  clearInterval(cd)
})
</script>

<template>
  <div v-cloak>
    <template v-if="loading">
      <el-skeleton :rows="6" animated style="padding: 40px" />
    </template>
    <template v-else-if="error">
      <el-result icon="error" title="数据加载失败" sub-title="请检查后端服务是否正常运行">
        <template #extra>
          <el-button type="primary" @click="fetchData">重试</el-button>
        </template>
      </el-result>
    </template>
    <template v-else-if="!data">
      <el-empty description="暂无数据，系统正在收集数据，请稍后刷新" />
    </template>
    <div v-else>
      <div class="header">
        <h1>
          <font-awesome-icon icon="bolt" />
          充电桩离线时段分析报告
        </h1>
        <div class="meta">
          <span
            ><font-awesome-icon icon="calendar-days" /> {{ data.min_time }} ~
            {{ data.max_time }}</span
          >
          <span><font-awesome-icon icon="magnifying-glass" /> 总检查 {{ data.total }} 次</span>
          <span><font-awesome-icon icon="clock" /> 上次检测 {{ data.last_check }}</span>
          <span><font-awesome-icon icon="arrows-rotate" /> {{ countdown }}秒后刷新</span>
          <el-button size="small" circle @click="fetchData" title="立即刷新">
            <font-awesome-icon icon="rotate" />
          </el-button>
        </div>
      </div>

      <StatCards
        :total="data.piles.length"
        :critical="counts.critical"
        :warning="counts.warning"
        :normal="counts.normal"
      />

      <TodayTimeline v-if="today" :today="today" />

      <PileCard v-for="pile in sortedPiles" :key="pile.pile_no" :pile="pile" />
    </div>
  </div>
</template>

<style lang="scss" scoped>
@use '../styles/variables' as *;

.header {
  background: $color-surface;
  padding: 28px 32px;
  border-radius: $radius-xl;
  margin-bottom: 24px;
  box-shadow: $shadow-md;
  border: 1px solid $color-border;

  h1 {
    font-size: 24px;
    font-weight: $font-weight-bold;
    color: $color-text-primary;
    margin: 0 0 14px;
    letter-spacing: -0.3px;
  }

  .meta {
    display: flex;
    gap: 12px;
    flex-wrap: wrap;
    font-size: 13px;
    align-items: center;

    span {
      background: $color-bg;
      color: $color-text-secondary;
      padding: 5px 14px;
      border-radius: 20px;
      font-weight: 500;
    }
  }
}
</style>
