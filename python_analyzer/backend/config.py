# =================================================================
# 充电桩监控系统 - 全局配置
# =================================================================

import logging
import os
from collections import deque
from datetime import datetime, timedelta, timezone
from typing import ClassVar

import urllib3

# 禁用 SSL 警告（仅用于测试/内部 API）
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# =================================================================
# 运行环境（类似 Spring Boot 的 spring.profiles.active）
# =================================================================
os.environ.setdefault('APP_ENV', 'production')
APP_ENV = os.environ['APP_ENV']
print(f"当前运行环境: {APP_ENV}")


def is_dev():
    """运行时判断是否为开发模式，比模块级常量更可靠"""
    return os.environ.get('APP_ENV') == 'development'

# 充电桩 API 基础地址
basic_url = "https://api-mini.cdyun.vip"

# 请求头
headers = {
    "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 18_7 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 MicroMessenger/8.0.69(0x18004539) NetType/WIFI Language/zh_CN",
    "Content-Type": "application/json"
}

# SQLite 数据库文件路径
DB_PATH = "pile_status.db"

# API 全局前缀（类似 Spring Boot 的 server.servlet.context-path）
API_PREFIX = "/api"

# 守护进程配置
CHECK_INTERVAL = 60  # 后台检测间隔（秒），默认 5 分钟
HTTP_PORT = 9901      # HTTP 报告服务端口

# 桩号位置标签（方便快速识别，如「地下室」「1号楼」等）
pile_tag_map = {
    "0000224": "地下室",
    "0000225": "地下室"
}

# 监控桩号配置：{桩号: 位置信息}
pile_no = {
    "0000288": "浙江省杭州市钱塘区经济开发区学林支路与2号大街辅路交叉口西北角杭州钱塘宝龙广场",
    "0000279": "浙江省杭州市钱塘区经济开发区学林支路与2号大街辅路交叉口西北角杭州钱塘宝龙广场",
    "0000286": "浙江省杭州市钱塘区经济开发区学林支路与2号大街辅路交叉口西北角杭州钱塘宝龙广场",
    "0000224": "浙江省杭州市钱塘区经济开发区学林支路与2号大街辅路交叉口西北角杭州钱塘宝龙广场",
    "0000280": "浙江省杭州市钱塘区经济开发区学林支路与2号大街辅路交叉口西北角杭州钱塘宝龙广场",
    "0000225": "浙江省杭州市钱塘区经济开发区学林支路与2号大街辅路交叉口西北角杭州钱塘宝龙广场"
}


# =================================================================
# 日志系统：内存缓冲 + 控制台输出
# =================================================================

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
        """获取最近的日志

        Args:
            level: 可选，按级别筛选（DEBUG/INFO/WARNING/ERROR）
            limit: 返回条数，默认 100
        """
        logs = list(cls._buffer)
        if level:
            logs = [l for l in logs if l["level"] == level.upper()]
        return logs[-limit:]


def setup_logging():
    """初始化日志系统：控制台 + 内存双通道"""
    root = logging.getLogger()
    root.setLevel(logging.DEBUG)

    # 屏蔽第三方库的 DEBUG 日志（urllib3、requests 等）
    for lib in ["urllib3", "requests", "charset_normalizer"]:
        logging.getLogger(lib).setLevel(logging.WARNING)

    fmt = logging.Formatter("%(asctime)s [%(levelname)s] %(message)s", datefmt="%Y-%m-%d %H:%M:%S")

    console = logging.StreamHandler()
    console.setFormatter(fmt)
    root.addHandler(console)

    memory = MemoryLogHandler()
    root.addHandler(memory)