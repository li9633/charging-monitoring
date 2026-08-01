# =================================================================
# 充电桩监控系统 - 主入口
# 启动 FastAPI HTTP 服务 + 后台定时检测
# =================================================================

import uvicorn

from config import HTTP_PORT
from server import app, start_background_checker

if __name__ == "__main__":
    start_background_checker()
    uvicorn.run(app, host="0.0.0.0", port=HTTP_PORT, log_level="warning")