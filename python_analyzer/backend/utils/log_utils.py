# =================================================================
# 日志工具 — MemoryLogHandler + 初始化
# =================================================================

import logging
from collections import deque
from datetime import datetime, timedelta, timezone
from typing import ClassVar


class MemoryLogHandler(logging.Handler):
    """自定义日志处理器：将日志存入内存双端队列，供前端 API 查询"""
    _buffer: ClassVar[deque] = deque(maxlen=2000)

    def emit(self, record):
        t = datetime.fromtimestamp(record.created, tz=timezone(timedelta(hours=8)))
        self._buffer.append({
            "time": t.strftime("%Y-%m-%d %H:%M:%S"),
            "level": record.levelname,
            "message": record.getMessage()
        })

    @classmethod
    def get_logs(cls, level=None, limit=100):
        if level:
            level = level.upper()
            filtered = [l for l in cls._buffer if l["level"] == level]
            return filtered[-limit:]
        return list(cls._buffer)[-limit:]


def setup_logging():
    """初始化日志系统：控制台 + 内存双通道"""
    root = logging.getLogger()
    root.setLevel(logging.DEBUG)

    for lib in ["urllib3", "requests", "charset_normalizer"]:
        logging.getLogger(lib).setLevel(logging.WARNING)

    fmt = logging.Formatter("%(asctime)s [%(levelname)s] %(message)s", datefmt="%Y-%m-%d %H:%M:%S")

    console = logging.StreamHandler()
    console.setFormatter(fmt)
    root.addHandler(console)

    memory = MemoryLogHandler()
    root.addHandler(memory)