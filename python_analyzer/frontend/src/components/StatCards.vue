<script setup lang="ts">
defineProps<{
  total: number
  critical: number
  warning: number
  normal: number
}>()
</script>

<template>
  <el-row :gutter="14" style="margin-bottom: 18px">
    <el-col :xs="12" :sm="6">
      <div class="stat-card">
        <div class="stat-val">{{ total }}</div>
        <div class="stat-label">监控桩数</div>
      </div>
    </el-col>
    <el-col :xs="12" :sm="6">
      <div class="stat-card">
        <div class="stat-val" style="color: var(--el-color-danger)">{{ critical }}</div>
        <div class="stat-label">严重离线 ≥50%</div>
      </div>
    </el-col>
    <el-col :xs="12" :sm="6">
      <div class="stat-card">
        <div class="stat-val" style="color: var(--el-color-warning)">{{ warning }}</div>
        <div class="stat-label">需关注 20%~50%</div>
      </div>
    </el-col>
    <el-col :xs="12" :sm="6">
      <div class="stat-card">
        <div class="stat-val" style="color: var(--el-color-success)">{{ normal }}</div>
        <div class="stat-label">正常运行 &lt;20%</div>
      </div>
    </el-col>
  </el-row>
</template>

<style lang="scss" scoped>
@use '../styles/variables' as *;

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
  letter-spacing: 0.2px;
}
</style>
