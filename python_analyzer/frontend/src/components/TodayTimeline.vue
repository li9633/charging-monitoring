<script setup lang="ts">
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

defineProps<{
  today: TodayData
}>()

function blockClass(h: TodayHour): string {
  return { online: 'green', offline: 'red', nodata: 'gray' }[h.status] ?? 'gray'
}
</script>

<template>
  <el-card class="today-card">
    <template #header>
      <div class="today-header">
        <span class="today-title">
          <font-awesome-icon icon="calendar-days" />
          今日状态 {{ today.date }}
        </span>
        <div class="today-legend">
          <span><span class="dot" style="background: #67c23a"></span>在线</span>
          <span><span class="dot" style="background: #f56c6c"></span>有离线</span>
          <span><span class="dot" style="background: #e8e8e8"></span>暂无数据</span>
        </div>
      </div>
    </template>
    <div style="overflow-x: auto">
      <div class="hour-labels">
        <span v-for="h in 24" :key="h">{{ h - 1 }}</span>
      </div>
      <div v-for="pile in today.piles" :key="pile.pile_no" class="today-row">
        <div class="pile-label">
          <div>{{ pile.pile_no }}</div>
          <div class="loc" :title="pile.location">{{ pile.loc_display }}</div>
        </div>
        <div class="today-timeline">
          <div
            v-for="h in pile.hours"
            :key="h.hour"
            :class="['tblk', blockClass(h)]"
            :title="h.label + ' 检查:' + h.checks + '次 离线:' + h.offline + '次'"
          ></div>
        </div>
      </div>
    </div>
  </el-card>
</template>

<style lang="scss" scoped>
@use '../styles/variables' as *;

.today-card {
  margin-bottom: 20px;
  border-radius: $radius-lg;
  overflow: hidden;

  :deep(.el-card__header) {
    padding: 16px 20px;
    border-bottom: 1px solid $color-border;
  }

  :deep(.el-card__body) {
    padding: 16px 20px;
  }
}

.today-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.today-title {
  font-weight: $font-weight-semibold;
  font-size: 15px;
  color: $color-text-primary;
  letter-spacing: -0.2px;
}

.today-legend {
  display: flex;
  gap: 16px;
  align-items: center;
  font-size: 12px;
  color: $color-text-secondary;
  font-weight: 500;

  .dot {
    width: 10px;
    height: 10px;
    border-radius: 50%;
    display: inline-block;
    margin-right: 4px;
  }
}

.hour-labels {
  display: flex;
  gap: 2px;
  padding: 4px 0;
  margin-left: 130px;

  span {
    flex: 1;
    min-width: 12px;
    font-size: 9px;
    color: $color-text-tertiary;
    text-align: center;
    font-weight: 500;
  }
}

.today-row {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 0;
  border-bottom: 1px solid $color-border;

  &:last-child {
    border-bottom: none;
  }
}

.pile-label {
  width: 130px;
  flex-shrink: 0;
  font-size: 13px;
  font-weight: $font-weight-semibold;
  color: $color-text-primary;

  .loc {
    font-weight: 400;
    font-size: 11px;
    color: $color-text-secondary;
  }
}

.today-timeline {
  display: flex;
  gap: 2px;
  flex: 1;
}

.tblk {
  flex: 1;
  min-width: 12px;
  height: 28px;
  border-radius: 4px;
  cursor: pointer;
  transition:
    transform $transition-fast,
    opacity $transition-fast;

  &:hover {
    transform: scale(1.15);
    z-index: 1;
    opacity: 0.85;
  }

  &.green {
    background: $color-green;
  }

  &.red {
    background: $color-red;
  }

  &.gray {
    background: #e8e8ed;
  }
}
</style>
