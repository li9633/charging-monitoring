<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { getHistory } from '@/api/modules/pile'

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
}

interface ReportData {
  min_time: string
  max_time: string
  total: number
  last_check: string
  piles: PileData[]
}

const data = ref<ReportData | null>(null)
const loading = ref(true)
const error = ref(false)

const stats = computed(() => {
  if (!data.value) return null
  const piles = data.value.piles
  const totalOffline = piles.reduce((s, p) => s + p.total_offline, 0)
  const totalChecks = piles.reduce((s, p) => s + p.total_checks, 0)
  const avgRate = totalChecks > 0 ? ((totalOffline / totalChecks) * 100).toFixed(1) : '0'
  const criticalCount = piles.filter((p) => p.offline_rate >= 50).length
  const warningCount = piles.filter((p) => p.offline_rate >= 20 && p.offline_rate < 50).length
  const normalCount = piles.filter((p) => p.offline_rate < 20).length

  const hourStats = Array.from({ length: 24 }, (_, h) => {
    let totalC = 0
    let totalO = 0
    piles.forEach((p) => {
      const hd = p.hours.find((x) => x.hour === h)
      if (hd) {
        totalC += hd.checks
        totalO += hd.offline
      }
    })
    return {
      hour: h,
      label: `${String(h).padStart(2, '0')}:00`,
      checks: totalC,
      offline: totalO,
      rate: totalC > 0 ? (totalO / totalC) * 100 : 0,
    }
  })

  return { totalOffline, totalChecks, avgRate, criticalCount, warningCount, normalCount, hourStats }
})

const topOfflinePiles = computed(() => {
  if (!data.value) return []
  return [...data.value.piles]
    .filter((p) => p.total_offline > 0)
    .sort((a, b) => b.offline_rate - a.offline_rate)
    .slice(0, 10)
})

async function fetchData() {
  loading.value = true
  try {
    const res = await getHistory({})
    data.value = res
    error.value = false
  } catch (e) {
    console.error('数据获取失败:', e)
    error.value = true
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  fetchData()
})

function barColor(rate: number): string {
  if (rate >= 50) return 'var(--el-color-danger)'
  if (rate >= 20) return 'var(--el-color-warning)'
  return 'var(--el-color-success)'
}
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
      <el-empty description="暂无历史数据" />
    </template>
    <div v-else>
      <div class="page-header">
        <h1>
          <font-awesome-icon icon="chart-line" />
          历史分析
        </h1>
        <p class="page-desc">
          查看历史累计数据，包含24小时离线率趋势图、各充电桩离线率排行TOP10及整体统计概览
        </p>
        <div class="header-meta">
          <span>数据范围：{{ data.min_time }} ~ {{ data.max_time }}</span>
          <el-button size="small" @click="fetchData">
            <font-awesome-icon icon="arrows-rotate" />
            刷新数据
          </el-button>
        </div>
      </div>

      <el-row :gutter="14" style="margin-bottom: 18px" v-if="stats">
        <el-col :xs="12" :sm="6">
          <div class="stat-card">
            <div class="stat-val">{{ stats.criticalCount }}</div>
            <div class="stat-label">严重离线桩 ≥50%</div>
          </div>
        </el-col>
        <el-col :xs="12" :sm="6">
          <div class="stat-card">
            <div class="stat-val" style="color: var(--el-color-warning)">
              {{ stats.warningCount }}
            </div>
            <div class="stat-label">需关注 20%~50%</div>
          </div>
        </el-col>
        <el-col :xs="12" :sm="6">
          <div class="stat-card">
            <div class="stat-val" style="color: var(--el-color-success)">
              {{ stats.normalCount }}
            </div>
            <div class="stat-label">正常运行 &lt;20%</div>
          </div>
        </el-col>
        <el-col :xs="12" :sm="6">
          <div class="stat-card">
            <div class="stat-val" style="color: var(--el-color-danger)">{{ stats.avgRate }}%</div>
            <div class="stat-label">整体离线率</div>
          </div>
        </el-col>
      </el-row>

      <el-card class="section-card">
        <template #header>
          <span class="section-title">
            <font-awesome-icon icon="clock" />
            24小时离线率趋势
          </span>
        </template>
        <div class="bar-chart" v-if="stats">
          <div class="bar-row" v-for="h in stats.hourStats" :key="h.hour">
            <span class="bar-label">{{ h.label }}</span>
            <div class="bar-track">
              <div
                class="bar-fill"
                :style="{
                  width: Math.min(h.rate, 100) + '%',
                  background: barColor(h.rate),
                }"
              ></div>
            </div>
            <span class="bar-val" :style="{ color: barColor(h.rate) }">
              {{ h.rate.toFixed(1) }}%
            </span>
          </div>
        </div>
      </el-card>

      <el-card class="section-card">
        <template #header>
          <span class="section-title">
            <font-awesome-icon icon="trophy" />
            离线率最高的充电桩 TOP10
          </span>
        </template>
        <el-table :data="topOfflinePiles" size="small" stripe>
          <el-table-column type="index" label="#" width="50" align="center" />
          <el-table-column prop="pile_no" label="桩号" width="120" />
          <el-table-column prop="loc_display" label="位置" min-width="180" />
          <el-table-column prop="total_checks" label="总检查" width="90" align="center" />
          <el-table-column prop="total_offline" label="总离线" width="90" align="center" />
          <el-table-column label="离线率" width="120" align="center">
            <template #default="{ row }">
              <el-progress
                :percentage="row.offline_rate"
                :color="row.status_color"
                :stroke-width="8"
              />
            </template>
          </el-table-column>
          <el-table-column prop="status" label="状态" width="90" align="center">
            <template #default="{ row }">
              <el-tag
                :type="
                  row.offline_rate >= 50 ? 'danger' : row.offline_rate >= 20 ? 'warning' : 'success'
                "
                size="small"
                effect="dark"
              >
                {{ row.status }}
              </el-tag>
            </template>
          </el-table-column>
        </el-table>
      </el-card>
    </div>
  </div>
</template>

<style lang="scss" scoped>
@use '../styles/variables' as *;

.page-header {
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
}

.header-meta {
  display: flex;
  gap: 16px;
  align-items: center;
  font-size: 13px;
  color: $color-text-secondary;
  font-weight: 500;
}

.section-card {
  margin-bottom: 20px;
  border-radius: $radius-lg;
  overflow: hidden;

  :deep(.el-card__header) {
    padding: 16px 20px;
    border-bottom: 1px solid $color-border;
  }

  :deep(.el-card__body) {
    padding: 20px;
  }
}

.section-title {
  font-weight: $font-weight-semibold;
  font-size: 15px;
  color: $color-text-primary;
  letter-spacing: -0.2px;
}

.stat-card {
  text-align: center;
  padding: 24px 16px;
  border-radius: $radius-lg;
  background: $color-surface;
  box-shadow: $shadow-md;
  transition: box-shadow $transition-smooth;

  &:hover {
    box-shadow: $shadow-lg;
  }
}

.stat-val {
  font-size: 32px;
  font-weight: $font-weight-bold;
  letter-spacing: -0.5px;
  line-height: 1.1;
}

.stat-label {
  font-size: 12px;
  color: $color-text-secondary;
  margin-top: 6px;
  font-weight: 500;
}

.bar-chart {
  padding: 4px 0;
}

.bar-row {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-bottom: 8px;
}

.bar-label {
  width: 44px;
  font-size: 11px;
  color: $color-text-tertiary;
  text-align: right;
  flex-shrink: 0;
  font-weight: 500;
}

.bar-track {
  flex: 1;
  height: 22px;
  background: $color-bg;
  border-radius: 6px;
  overflow: hidden;
}

.bar-fill {
  height: 100%;
  border-radius: 6px;
  transition: width 0.5s cubic-bezier(0.25, 0.1, 0.25, 1);
  min-width: 2px;
}

.bar-val {
  width: 52px;
  font-size: 12px;
  font-weight: $font-weight-semibold;
  text-align: left;
  flex-shrink: 0;
}
</style>
