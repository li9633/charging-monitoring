# =================================================================
# 充电桩监控系统 - 服务层
# 负责：FastAPI HTTP 服务 + 后台定时检测循环
# =================================================================

import logging
import sqlite3
import threading
from pathlib import Path

from fastapi import FastAPI
from fastapi.responses import FileResponse, RedirectResponse

from config import (
    API_PREFIX,
    CHECK_INTERVAL,
)
from controller.pile_controller import router as pile_router
from controller.system_controller import router as system_router
from mapper.pile_mapper import delete_old_data, init_db
from service.monitor_service import check_offline_piles
from utils.log_utils import setup_logging

DIST_DIR = Path(__file__).resolve().parent.parent / "frontend" / "dist"
app = FastAPI(
    title="充电桩监控系统",
    version="1.0.0",
    description="实时监控充电桩状态，离线检测与数据分析",
)
shutdown_event = threading.Event()
logger = logging.getLogger(__name__)

# ===== 注册路由（类似 Spring Boot 的 @RequestMapping） =====
app.include_router(pile_router, prefix=f"{API_PREFIX}/pile")
app.include_router(system_router, prefix=f"{API_PREFIX}/system")


@app.get("/health", tags=["系统"])
def health_check():
    return {"status": "ok", "service": "充电桩监控系统"}


# ===== SPA 兜底：未匹配 API 路由时返回 index.html =====
@app.get("/index.html")
async def redirect_index_to_root():
    return RedirectResponse(url="/")


@app.get("/{full_path:path}")
def serve_spa(full_path: str):
    file_path = DIST_DIR / full_path
    if file_path.is_file():
        return FileResponse(file_path)
    return FileResponse(DIST_DIR / "index.html")


def check_loop():
    """后台定时检测：定期查询充电桩状态并写入数据库"""
    while not shutdown_event.is_set():
        try:
            logger.info("开始新一轮检测...")
            check_offline_piles()
            delete_old_data()
            logger.info("本轮完成，%s 秒后进行下一轮", CHECK_INTERVAL)
        except (OSError, ValueError, sqlite3.Error) as e:
            logger.error("检测异常: %s", e)
        shutdown_event.wait(CHECK_INTERVAL)


def start_background_checker():
    """初始化系统并启动后台定时检测线程"""
    setup_logging()
    init_db()

    logger.info("=" * 50)
    logger.info("  充电桩监控系统")
    logger.info("=" * 50)

    checker = threading.Thread(
        target=check_loop, daemon=True, name="PileChecker"
    )
    checker.start()

    logger.info("后台检测间隔: %s 秒", CHECK_INTERVAL)