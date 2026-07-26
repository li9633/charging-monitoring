# =================================================================
# 充电桩监控系统 - 服务层
# 负责：注册蓝图路由 + Flask HTTP 服务 + 后台定时检测循环
# =================================================================

import logging
import os
import sqlite3
import threading

from cheroot.wsgi import Server
from flask import Flask, redirect, send_file

from config import (
    API_PREFIX,
    CHECK_INTERVAL,
    HTTP_PORT,
)
from controller.pile_controller import pile_bp
from controller.system_controller import system_bp
from mapper.pile_mapper import delete_old_data, init_db
from service.monitor_service import check_offline_piles
from utils.log_utils import setup_logging

STATIC_DIR = "../frontend/dist"
app = Flask(__name__, static_folder=STATIC_DIR, static_url_path='')

# ===== UTF-8 全局配置 =====
app.json.ensure_ascii = False
app.config['JSONIFY_MIMETYPE'] = 'application/json; charset=utf-8'
app.config['JSON_AS_ASCII'] = False

shutdown_event = threading.Event()
logger = logging.getLogger(__name__)

# ===== 注册蓝图（类似 Spring Boot 的 @RequestMapping） =====
app.register_blueprint(pile_bp, url_prefix=f"{API_PREFIX}/pile")
app.register_blueprint(system_bp, url_prefix=f"{API_PREFIX}/system")


# ===== SPA 兜底：404 时返回 index.html（等价于 nginx try_files） =====
@app.route("/index.html")
def redirect_index_to_root():
    return redirect("/")


@app.errorhandler(404)
def serve_spa(_e):
    index_path = os.path.join(STATIC_DIR, "index.html")
    if not os.path.isfile(index_path):
        return "前端未构建，请先执行: cd frontend && npm run build", 503
    return send_file(index_path, mimetype='text/html; charset=utf-8')


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

    server = None
    try:
        server = Server(("0.0.0.0", HTTP_PORT), app)
        server.start()
    except KeyboardInterrupt:
        pass
    finally:
        logger.info("正在关闭服务...")
        shutdown_event.set()
        if server:
            server.stop()
        logger.info("服务已停止")