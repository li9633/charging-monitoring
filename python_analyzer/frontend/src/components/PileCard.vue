<script setup lang="ts">
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

defineProps<{
  pile: PileData
}>()

function heatClass(css: string): string {
  return { d: 'danger', w: 'warning', g: 'success' }[css] ?? 'info'
}
</script>

<template>
  <el-card class="pile-card" :style="{ borderLeft: '4px solid ' + pile.status_color }">
    <div class="pile-header">
      <span class="pile-no">{{ pile.pile_no }}</span>
      <span class="loc" :title="pile.location">{{ pile.loc_display }}</span>
      <el-tag :type="pile.tagType" size="small" effect="dark">{{ pile.status }}</el-tag>
      <el-progress
        :percentage="pile.offline_rate"
        :color="pile.status_color"
        :stroke-width="6"
        style="width: 100px; flex-shrink: 0"
      />
    </div>

    <div class="stats">
      <span>检查 {{ pile.total_checks }}</span>
      <span>在线 {{ pile.online }}</span>
      <span>离线 {{ pile.total_offline }}</span>
      <span>离线率 {{ pile.offline_rate }}%</span>
    </div>

    <div class="heatmap">
      <span class="heatmap-label">0h</span>
      <div
        v-for="h in pile.hours"
        :key="h.hour"
        :class="['blk', heatClass(h.css_class)]"
        :title="h.label + ' 检查:' + h.checks + ' 离线:' + h.offline + ' ' + h.rate + '%'"
      ></div>
    </div>

    <el-alert
      v-if="pile.suspicious_ranges"
      :title="'疑似禁用时段: ' + pile.suspicious_ranges"
      type="warning"
      :closable="false"
      show-icon
      style="margin-top: 10px"
    />

    <el-collapse style="margin-top: 12px" v-model="pile.activeNames">
      <el-collapse-item title="详细数据" name="detail">
        <el-table :data="pile.hours" size="small" stripe max-height="360">
          <el-table-column prop="label" label="时段" width="80" align="center" />
          <el-table-column prop="checks" label="检查" width="80" align="center" />
          <el-table-column prop="offline" label="离线" width="80" align="center" />
          <el-table-column label="离线率" align="center">
            <template #default="{ row }">
              <span
                :style="{
                  color:
                    row.rate >= 80
                      ? 'var(--el-color-danger)'
                      : row.rate >= 50
                        ? 'var(--el-color-warning)'
                        : '',
                }"
                >{{ row.rate }}%</span
              >
            </template>
          </el-table-column>
          <el-table-column label="状态" width="120" align="center">
            <template #default="{ row }">
              <el-tag v-if="row.css_class === 'd'" type="danger" size="small">疑似禁用</el-tag>
              <el-tag v-else-if="row.css_class === 'w'" type="warning" size="small">关注</el-tag>
              <el-tag v-else-if="row.css_class === 'g'" type="success" size="small">正常</el-tag>
              <span v-else style="color: #c0c4cc">无数据</span>
            </template>
          </el-table-column>
        </el-table>
      </el-collapse-item>
    </el-collapse>
  </el-card>
</template>

<style lang="scss" scoped>
@use '../styles/variables' as *;

.pile-card {
  margin-bottom: 16px;
  border-radius: $radius-lg;
  overflow: hidden;
  transition: box-shadow $transition-smooth;

  &:hover {
    box-shadow: $shadow-lg;
  }

  :deep(.el-card__body) {
    padding: 20px 24px;
  }
}

.pile-header {
  display: flex;
  align-items: center;
  gap: 12px;
  flex-wrap: wrap;
}

.pile-no {
  font-size: 16px;
  font-weight: $font-weight-bold;
  color: $color-text-primary;
  letter-spacing: -0.2px;
}

.loc {
  font-size: 12px;
  color: $color-text-secondary;
  flex: 1;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.stats {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
  margin: 12px 0;
  font-size: 12px;
  font-weight: 500;

  span {
    background: $color-bg;
    padding: 4px 10px;
    border-radius: 6px;
    color: $color-text-secondary;
  }
}

.heatmap {
  display: flex;
  gap: 2px;
  margin: 12px 0;
  align-items: center;
}

.heatmap-label {
  font-size: 10px;
  color: $color-text-tertiary;
  width: 36px;
  flex-shrink: 0;
  font-weight: 500;
}

.blk {
  flex: 1;
  min-width: 14px;
  height: 24px;
  border-radius: 4px;
  cursor: pointer;
  transition: transform $transition-fast;

  &:hover {
    transform: scale(1.2);
    z-index: 1;
  }

  &.danger {
    background: $color-red;
  }

  &.warning {
    background: $color-orange;
  }

  &.success {
    background: $color-green;
  }

  &.info {
    background: #e8e8ed;
  }
}
</style>
