# =================================================================
# 充电桩监控系统 - 主入口（守护进程）
# 启动 HTTP 服务 + 后台定时检测，前端通过 /api/report 获取数据
# 主程序异常退出时自动重启，Ctrl+C 正常退出
# =================================================================

import time

from server import start_server

if __name__ == "__main__":
    while True:
        try:
            start_server()
            break
        except KeyboardInterrupt:
            break
        except Exception as e:  # noqa: BLE001
            print(f"\n⚠ 服务异常退出: {e}")
            print("5 秒后自动重启...\n")
            time.sleep(5)