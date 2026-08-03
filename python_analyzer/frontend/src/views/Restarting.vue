<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { healthCheck } from '@/api/modules/system'

defineOptions({ name: 'RestartingView' })

const router = useRouter()
const route = useRoute()

const elapsed = ref(0)
const timedOut = ref(false)
const from = (route.query.from as string) || '/'

let timer: ReturnType<typeof setInterval>

function reloadPage() {
  window.location.reload()
}

onMounted(async () => {
  timer = setInterval(() => elapsed.value++, 1000)

  for (let i = 0; i < 30; i++) {
    await new Promise((r) => setTimeout(r, 1000))
    try {
      await healthCheck()
      clearInterval(timer)
      router.replace(from)
      return
    } catch {
      /* 继续等待 */
    }
  }

  clearInterval(timer)
  timedOut.value = true
})
</script>

<template>
  <div class="restarting-page">
    <div class="card">
      <div class="spinner" v-if="!timedOut">
        <el-icon :size="48" class="is-loading">
          <font-awesome-icon icon="arrows-rotate" />
        </el-icon>
      </div>
      <div class="icon-fail" v-else>
        <font-awesome-icon icon="triangle-exclamation" />
      </div>

      <h2 v-if="!timedOut">后端服务重启中</h2>
      <h2 v-else>服务恢复超时</h2>

      <p v-if="!timedOut" class="hint">
        服务正在重新加载最新代码，预计需要 3-5 秒<br />
        已等待 <strong>{{ elapsed }}</strong> 秒
      </p>
      <p v-else class="hint fail">
        已等待 30 秒，服务未能自动恢复<br />
        请检查后端是否正常运行，然后手动刷新
      </p>

      <el-button v-if="timedOut" type="primary" size="large" @click="reloadPage">
        手动刷新页面
      </el-button>
    </div>
  </div>
</template>

<style lang="scss" scoped>
@use '../styles/variables' as *;

.restarting-page {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background: $color-bg;
  font-family: $font-family;
}

.card {
  text-align: center;
  background: $color-surface;
  padding: 48px 64px;
  border-radius: $radius-xl;
  box-shadow: $shadow-lg;
  max-width: 420px;
  width: 100%;

  h2 {
    margin: 20px 0 12px;
    font-size: 20px;
    font-weight: $font-weight-semibold;
    color: $color-text-primary;
  }

  .hint {
    font-size: 14px;
    color: $color-text-secondary;
    line-height: 1.6;
    margin: 0 0 24px;

    strong {
      color: $color-blue;
    }

    &.fail {
      color: $color-red;
    }
  }
}

.spinner {
  color: $color-blue;
  animation: spin 1.2s linear infinite;
}

.icon-fail {
  font-size: 48px;
  color: $color-orange;
}

@keyframes spin {
  from {
    transform: rotate(0deg);
  }
  to {
    transform: rotate(360deg);
  }
}
</style>
