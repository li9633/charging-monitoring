# =================================================================
# 充电桩监控系统 - 服务层
# 负责：FastAPI HTTP 服务 + 后台定时检测循环
# =================================================================

import logging
import sqlite3
import threading
from datetime import datetime, timedelta, timezone
from pathlib import Path

from fastapi import FastAPI, Query
from fastapi.responses import FileResponse, RedirectResponse

from analyzer import get_history_data, get_report_data
from api import check_offline_piles
from config import (
    CHECK_INTERVAL,
    MemoryLogHandler,
    pile_tag_map,
    setup_logging,
)
from db import cleanup_old_data, init_db

DIST_DIR = Path(__file__).resolve().parent.parent / "frontend" / "dist"
app = FastAPI(
    title="充电桩监控系统",
    version="1.0.0",
    description="实时监控充电桩状态，离线检测与数据分析",
)
shutdown_event = threading.Event()
logger = logging.getLogger(__name__)


@app.get("/api/report")
async def api_report(
    tag: str = Query(None),
    pile_no: str = Query(None),
    start_date: str = Query(None),
    end_date: str = Query(None),
):
    today = datetime.now(tz=timezone(timedelta(hours=8))).strftime("%Y-%m-%d")
    if start_date is None:
        start_date = today
    if end_date is None:
        end_date = today
    return get_report_data(tag_filter=tag, pile_no_filter=pile_no, start_date=start_date, end_date=end_date)


@app.get("/api/history")
async def api_history(
    tag: str = Query(None),
    pile_no: str = Query(None),
):
    """历史分析接口：基于全部数据进行分析"""
    return get_history_data(tag_filter=tag, pile_no_filter=pile_no)


@app.get("/api/logs")
async def api_logs(
    level: str = Query(None),
    limit: int = Query(100),
):
    """返回后端运行日志，支持按级别筛选"""
    logs = MemoryLogHandler.get_logs(level=level, limit=limit)
    return {"logs": logs, "total": len(logs)}


@app.get("/api/tags")
async def api_tags():
    """返回所有可用标签及对应桩号"""
    tags = {}
    for pile, tag in pile_tag_map.items():
        if tag not in tags:
            tags[tag] = []
        tags[tag].append(pile)
    return {"tags": tags, "all_tags": list(tags.keys())}


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
            cleanup_old_data()
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