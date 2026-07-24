# d:\MyCodeProject\charging-monitoring\python\server.py
# =================================================================
# 充电桩监控系统 - 服务层
# 负责：HTTP 服务器 + 后台定时检测循环
# =================================================================

import json
import os
import sqlite3
import threading
from datetime import datetime, timedelta, timezone
from http.server import BaseHTTPRequestHandler, HTTPServer

from analyzer import get_report_data
from api import check_offline_piles
from config import CHECK_INTERVAL, HTTP_PORT
from db import cleanup_old_data, init_db

shutdown_event = threading.Event()


class ReportHandler(BaseHTTPRequestHandler):
    """HTTP 请求处理器：返回静态页面 / JSON API"""

    def do_GET(self):
        if self.path in ("/", "/index.html"):
            self.send_response(200)
            self.send_header("Content-type", "text/html; charset=utf-8")
            self.end_headers()
            html_path = os.path.join(os.path.dirname(__file__), "index.html")
            with open(html_path, "r", encoding="utf-8") as f:
                self.wfile.write(f.read().encode("utf-8"))
        elif self.path == "/api/report":
            self.send_response(200)
            self.send_header("Content-type", "application/json; charset=utf-8")
            self.end_headers()
            data = get_report_data()
            self.wfile.write(json.dumps(data, ensure_ascii=False).encode("utf-8"))
        else:
            self.send_response(404)
            self.end_headers()

    def log_message(self, format, *args):
        pass  # 抑制 HTTP 访问日志


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

    server = HTTPServer(("0.0.0.0", HTTP_PORT), ReportHandler)
    print(f"\n✅ HTTP 报告服务已启动: http://localhost:{HTTP_PORT}")
    print(f"✅ 后台检测间隔: {CHECK_INTERVAL} 秒")
    print("按 Ctrl+C 停止服务\n")

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n正在关闭服务...")
        shutdown_event.set()
        server.shutdown()
        print("服务已停止")