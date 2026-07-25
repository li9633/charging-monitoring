# =================================================================
# 充电桩监控系统 - 服务层
# 负责：Flask HTTP 服务 + 后台定时检测循环
# =================================================================

import sqlite3
import threading
from datetime import datetime, timedelta, timezone

from flask import Flask, jsonify, redirect, send_file
from waitress import serve

from analyzer import get_report_data, get_today_data
from api import check_offline_piles
from config import CHECK_INTERVAL, HTTP_PORT
from db import cleanup_old_data, init_db

STATIC_DIR = "frontend/dist"
app = Flask(__name__, static_folder=STATIC_DIR, static_url_path='')
shutdown_event = threading.Event()


@app.route("/")
def index():
    return redirect("/index.html")


@app.route("/index.html")
def report_page():
    return send_file(f"{STATIC_DIR}/index.html")


@app.route("/api/report")
def api_report():
    return jsonify(get_report_data())


@app.route("/api/today")
def api_today():
    return jsonify(get_today_data())


def check_loop():
    """后台定时检测：定期查询充电桩状态并写入数据库"""
    while not shutdown_event.is_set():
        try:
            now_str = datetime.now(tz=timezone(timedelta(hours=8))).strftime("%H:%M:%S")
            print(f"\n[{now_str}] 开始新一轮检测...")
            check_offline_piles()
            cleanup_old_data()
            print(
                f"[{datetime.now(tz=timezone(timedelta(hours=8))).strftime('%H:%M:%S')}] 本轮完成，{CHECK_INTERVAL}秒后进行下一轮"
            )
        except (OSError, ValueError, sqlite3.Error) as e:
            print(f"检测异常: {e}")
        shutdown_event.wait(CHECK_INTERVAL)


def start_server():
    """启动 HTTP 服务 + 后台定时检测"""
    init_db()

    print("=" * 50)
    print("  充电桩监控系统")
    print("=" * 50)

    checker = threading.Thread(
        target=check_loop, daemon=True, name="PileChecker"
    )
    checker.start()

    print(f"\n✅ HTTP 报告服务已启动: http://localhost:{HTTP_PORT}")
    print(f"✅ 后台检测间隔: {CHECK_INTERVAL} 秒")
    print("按 Ctrl+C 停止服务\n")

    try:
        serve(app, host="0.0.0.0", port=HTTP_PORT)
    except KeyboardInterrupt:
        print("\n正在关闭服务...")
        shutdown_event.set()
        print("服务已停止")