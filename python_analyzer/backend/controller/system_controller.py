# =================================================================
# 系统 Controller — /api/system/*（类似 Spring Boot @RestController）
# =================================================================

import logging
import os
import threading
import time as time_module

from flask import Blueprint, request

from config import is_dev
from model.result import fail, ok, success
from utils.log_utils import MemoryLogHandler

system_bp = Blueprint("system", __name__)
logger = logging.getLogger(__name__)


@system_bp.route("/logs")
def logs():
    level = request.args.get("level", None)
    limit = request.args.get("limit", "100")
    limit = int(limit) if limit.isdigit() else 100
    logs_data = MemoryLogHandler.get_logs(level=level, limit=limit)
    return ok({"logs": logs_data, "total": len(logs_data)})


@system_bp.route("/health")
def health():
    return ok({"status": "ok"})


@system_bp.route("/version")
def version():
    return ok({"version": 2})


@system_bp.route("/restart", methods=["POST"])
def restart():
    if not is_dev():
        return fail("仅开发模式可用", 403)

    def _do_restart():
        time_module.sleep(0.3)
        signal_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), ".restart_signal")
        with open(signal_path, "w") as f:
            f.write("1")
        logger.warning("进程重启中，加载最新代码...")
        os._exit(0)

    threading.Thread(target=_do_restart, daemon=True).start()
    return success("服务器进程正在重启...")