<script setup lang="ts">
import { ref, computed, watch, onMounted, onBeforeUnmount } from 'vue'
import { getReport, getTags } from '@/api/modules/pile'
import type { ReportResponse, PileData, HourData } from '@/api/modules/pile'
import StatCards from '@/components/StatCards.vue'
import PileCard from '@/components/PileCard.vue'

defineOptions({ name: 'DashboardView' })

interface PileWithUI extends PileData {
  activeNames: string[]
  tagType: 'danger' | 'warning' | 'success'
}

const data = ref<ReportResponse | null>(null)
const tags = ref<string[]>([])
const selectedTag = ref('')
const selectedPeriod = ref('today')
const customRange = ref<string[]>([])
const initialLoading = ref(true)
const refreshing = ref(false)
const error = ref(false)
const countdown = ref(60)

function fmtDate(d: Date) {
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
}

function todayStr() {
  return fmtDate(new Date())
}

function daysAgo(n: number) {
  const d = new Date()
  d.setDate(d.getDate() - n)
  return fmtDate(d)
}

const sortedPiles = computed<PileWithUI[]>(() => {
  if (!data.value) return []
  return [...data.value.piles]
    .map((p) => ({
      ...p,
      activeNames: [],
      tagType: (p.offline_rate >= 50 ? 'danger' : p.offline_rate >= 20 ? 'warning' : 'success') as
        'danger' | 'warning' | 'success',
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

async function loadTags() {
  try {
    const res = await getTags()
    tags.value = res?.all_tags || []
  } catch (e) {
    console.error('标签获取失败:', e)
  }
}

async function fetchData() {
  try {
    const params: Record<string, string> = {}
    if (selectedTag.value) params.tag = selectedTag.value

    if (selectedPeriod.value === 'yesterday') {
      params.start_date = daysAgo(1)
      params.end_date = daysAgo(1)
    } else if (selectedPeriod.value === '7') {
      params.start_date = daysAgo(7)
      params.end_date = todayStr()
    } else if (selectedPeriod.value === '30') {
      params.start_date = daysAgo(30)
      params.end_date = todayStr()
    } else if (selectedPeriod.value === 'custom' && customRange.value?.length === 2) {
      const [start, end] = customRange.value as [string, string]
      params.start_date = start
      params.end_date = end
    } else {
      params.start_date = todayStr()
      params.end_date = todayStr()
    }
    const res = await getReport(params)
    data.value = res
    error.value = false
    countdown.value = 60
  } catch (e) {
    console.error('数据获取失败:', e)
    if (!data.value) error.value = true
  } finally {
    initialLoading.value = false
    refreshing.value = false
  }
}

watch([selectedTag, selectedPeriod, customRange], () => {
  refreshing.value = true
  fetchData()
})

let timer: ReturnType<typeof setInterval> | undefined
let cd: ReturnType<typeof setInterval> | undefined

onMounted(() => {
  loadTags()
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
    <div class="header">
      <h1>
        <font-awesome-icon icon="bolt" />
        充电桩离线时段分析报告
      </h1>
      <p class="page-desc">
        查看所有充电桩的离线率统计、按标签筛选特定区域，支持今日/昨日/近N日/指定日期，以及每桩24小时离线热力图
      </p>
      <div class="meta">
        <template v-if="data">
          <span
            ><font-awesome-icon icon="calendar-days" /> {{ data.min_time }} ~
            {{ data.max_time }}</span
          >
          <span><font-awesome-icon icon="magnifying-glass" /> 总检查 {{ data.total }} 次</span>
          <span><font-awesome-icon icon="clock" /> 上次检测 {{ data.last_check }}</span>
        </template>
        <span><font-awesome-icon icon="arrows-rotate" /> {{ countdown }}秒后刷新</span>
        <el-tooltip content="立即刷新" placement="top">
          <el-button size="small" circle @click="fetchData" :loading="refreshing">
            <font-awesome-icon v-if="!refreshing" icon="rotate" />
          </el-button>
        </el-tooltip>
      </div>
    </div>

    <div class="filter-bar">
      <div class="filter-group">
        <span class="filter-label">
          <font-awesome-icon icon="clock" />
          时间范围
        </span>
        <el-radio-group v-model="selectedPeriod" size="small">
          <el-radio-button value="yesterday">昨日</el-radio-button>
          <el-radio-button value="today">今日</el-radio-button>
          <el-radio-button value="7">近7天</el-radio-button>
          <el-radio-button value="30">近30天</el-radio-button>
          <el-radio-button value="custom">自定义</el-radio-button>
        </el-radio-group>
        <el-date-picker
          v-if="selectedPeriod === 'custom'"
          v-model="customRange"
          type="daterange"
          range-separator="至"
          start-placeholder="开始日期"
          end-placeholder="结束日期"
          size="small"
          value-format="YYYY-MM-DD"
          style="width: 260px"
        />
      </div>
      <div v-if="tags.length" class="filter-group">
        <span class="filter-label">
          <font-awesome-icon icon="tags" />
          标签筛选
        </span>
        <el-radio-group v-model="selectedTag" size="small">
          <el-radio-button value="">全部</el-radio-button>
          <el-radio-button v-for="t in tags" :key="t" :value="t">{{ t }}</el-radio-button>
        </el-radio-group>
      </div>
    </div>

    <div v-if="refreshing && data" class="refresh-bar">
      <el-progress :percentage="100" :indeterminate="true" :stroke-width="2" :show-text="false" />
    </div>

    <template v-if="initialLoading">
      <el-skeleton :rows="6" animated style="padding: 40px" />
    </template>
    <template v-else-if="error && !data">
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
      <StatCards
        :total="data.piles.length"
        :critical="counts.critical"
        :warning="counts.warning"
        :normal="counts.normal"
      />

      <PileCard v-for="pile in sortedPiles" :key="pile.pile_no" :pile="pile" />
    </div>
  </div>
</template>

<style lang="scss" scoped>
@use '../styles/variables' as *;

.refresh-bar {
  margin-bottom: 16px;

  :deep(.el-progress-bar__outer) {
    background: transparent;
  }
}

.filter-bar {
  display: flex;
  align-items: center;
  gap: 24px;
  background: $color-surface;
  padding: 14px 24px;
  border-radius: $radius-lg;
  margin-bottom: 20px;
  box-shadow: $shadow-sm;
  border: 1px solid $color-border;
  flex-wrap: wrap;

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
}

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
    margin: 0 0 6px;
    letter-spacing: -0.3px;
  }

  .page-desc {
    font-size: 14px;
    color: $color-text-secondary;
    margin: 0 0 16px;
    line-height: 1.5;
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
