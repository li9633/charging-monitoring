# =================================================================
# 守护进程 - 管理 server 进程，支持前端触发重启加载最新代码
# 启动方式: python run.py （替代 python main.py）
# =================================================================

import os
import subprocess
import sys
import time

SIGNAL_FILE = ".restart_signal"

while True:
    print("🚀 启动服务...")
    proc = subprocess.Popen([sys.executable, "main.py"])

    proc.wait()
    exit_code = proc.returncode

    if os.path.exists(SIGNAL_FILE):
        os.remove(SIGNAL_FILE)
        print("🔄 前端请求重启，加载最新代码...\n")
        time.sleep(1)
        continue

    if exit_code == 0 or exit_code == -2:
        print("服务已停止")
        break
    else:
        print(f"⚠ 服务异常退出 (code={exit_code})，5 秒后重启...\n")
        time.sleep(5)
