# =================================================================
# 充电桩监控系统 - 服务层
# 负责：Flask HTTP 服务 + 后台定时检测循环
# =================================================================

import logging
import sqlite3
import threading
from datetime import datetime, timedelta, timezone

from flask import Flask, jsonify, redirect, request, send_file
from waitress import serve

from analyzer import get_history_data, get_report_data
from api import check_offline_piles
from config import (
    CHECK_INTERVAL,
    HTTP_PORT,
    MemoryLogHandler,
    pile_tag_map,
    setup_logging,
)
from db import cleanup_old_data, init_db

STATIC_DIR = "frontend/dist"
app = Flask(__name__, static_folder=STATIC_DIR, static_url_path='')
shutdown_event = threading.Event()
logger = logging.getLogger(__name__)


@app.route("/")
def index():
    return redirect("/index.html")


@app.route("/index.html")
def report_page():
    return send_file(f"{STATIC_DIR}/index.html")


@app.route("/api/report")
def api_report():
    tag = request.args.get("tag", None)
    pile_no = request.args.get("pile_no", None)
    today = datetime.now(tz=timezone(timedelta(hours=8))).strftime("%Y-%m-%d")
    start_date = request.args.get("start_date", today)
    end_date = request.args.get("end_date", today)
    return jsonify(get_report_data(tag_filter=tag, pile_no_filter=pile_no, start_date=start_date, end_date=end_date))


@app.route("/api/history")
def api_history():
    """历史分析接口：基于全部数据进行分析"""
    tag = request.args.get("tag", None)
    pile_no = request.args.get("pile_no", None)
    return jsonify(get_history_data(tag_filter=tag, pile_no_filter=pile_no))


@app.route("/api/logs")
def api_logs():
    """返回后端运行日志，支持按级别筛选"""
    level = request.args.get("level", None)
    limit = request.args.get("limit", "100")
    limit = int(limit) if limit.isdigit() else 100
    logs = MemoryLogHandler.get_logs(level=level, limit=limit)
    return jsonify({"logs": logs, "total": len(logs)})


@app.route("/api/tags")
def api_tags():
    """返回所有可用标签及对应桩号"""
    tags = {}
    for pile, tag in pile_tag_map.items():
        if tag not in tags:
            tags[tag] = []
        tags[tag].append(pile)
    return jsonify({"tags": tags, "all_tags": list(tags.keys())})


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


def start_server():
    """启动 HTTP 服务 + 后台定时检测"""
    setup_logging()
    init_db()

    logger.info("=" * 50)
    logger.info("  充电桩监控系统")
    logger.info("=" * 50)

    checker = threading.Thread(
        target=check_loop, daemon=True, name="PileChecker"
    )
    checker.start()

    logger.info("HTTP 报告服务已启动: http://localhost:%s", HTTP_PORT)
    logger.info("后台检测间隔: %s 秒", CHECK_INTERVAL)
    logger.info("按 Ctrl+C 停止服务")

    try:
        serve(app, host="0.0.0.0", port=HTTP_PORT)
    except KeyboardInterrupt:
        logger.info("正在关闭服务...")
        shutdown_event.set()
        logger.info("服务已停止")