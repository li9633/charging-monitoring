# d:\MyCodeProject\charging-monitoring\python\config.py
# =================================================================
# 充电桩监控系统 - 全局配置
# =================================================================

import urllib3

# 禁用 SSL 警告（仅用于测试/内部 API）
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# 充电桩 API 基础地址
basic_url = "https://api-mini.cdyun.vip"

# 请求头
headers = {
    "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 18_7 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 MicroMessenger/8.0.69(0x18004539) NetType/WIFI Language/zh_CN",
    "Content-Type": "application/json"
}

# SQLite 数据库文件路径
DB_PATH = "pile_status.db"

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