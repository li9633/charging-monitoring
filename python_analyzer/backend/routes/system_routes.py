# =================================================================
# 系统管理路由 - /api/system/*
# =================================================================

import logging
import os
import threading
import time as time_module

from flask import Blueprint, jsonify, request

from config import MemoryLogHandler, is_dev

system_bp = Blueprint("system", __name__)
logger = logging.getLogger(__name__)


@system_bp.route("/logs")
def logs():
    level = request.args.get("level", None)
    limit = request.args.get("limit", "100")
    limit = int(limit) if limit.isdigit() else 100
    logs_data = MemoryLogHandler.get_logs(level=level, limit=limit)
    return jsonify({"logs": logs_data, "total": len(logs_data)})


@system_bp.route("/health")
def health():
    return jsonify({"status": "ok"})


@system_bp.route("/version")
def version():
    return jsonify({"version": 2})


@system_bp.route("/restart", methods=["POST"])
def restart():
    if not is_dev():
        return jsonify({"status": "error", "message": "仅开发模式可用"}), 403

    def _do_restart():
        time_module.sleep(0.3)
        with open(".restart_signal", "w") as f:
            f.write("1")
        logger.warning("进程重启中，加载最新代码...")
        os._exit(0)

    threading.Thread(target=_do_restart, daemon=True).start()
    return jsonify({"status": "ok", "message": "服务器进程正在重启..."})