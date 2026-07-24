# d:\MyCodeProject\charging-monitoring\python\db.py
# =================================================================
# 充电桩监控系统 - 数据库层
# 负责：建表、写入检测结果、查询分析数据
# =================================================================

import sqlite3
from datetime import datetime, timedelta, timezone

from config import DB_PATH


def init_db():
    """初始化 SQLite 数据库，创建状态记录表（如果不存在）"""
    conn = sqlite3.connect(DB_PATH)
    conn.execute("""
        CREATE TABLE IF NOT EXISTS pile_status_log (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            pile_no TEXT NOT NULL,
            location TEXT,
            status INTEGER,
            check_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    """)
    conn.execute("""
        CREATE INDEX IF NOT EXISTS idx_pile_no_time
        ON pile_status_log(pile_no, check_time)
    """)
    conn.commit()
    conn.close()


def log_results_to_db(all_results):
    """将本轮所有查询结果写入数据库

    Args:
        all_results: [(pile_no, location, status_data), ...]
    """
    conn = sqlite3.connect(DB_PATH)
    now = datetime.now(tz=timezone(timedelta(hours=8))).strftime("%Y-%m-%d %H:%M:%S")
    for pile_no, location, status_data in all_results:
        status_code = status_data.get('status', -1) if status_data else -1
        conn.execute(
            "INSERT INTO pile_status_log (pile_no, location, status, check_time) VALUES (?, ?, ?, ?)",
            (pile_no, location, status_code, now)
        )
    conn.commit()
    conn.close()
    print(f"已写入 {len(all_results)} 条状态记录到数据库")


def query_report_data():
    """从数据库查询分析报告所需的全部数据

    Returns:
        dict or None: 包含 min_time, max_time, total, pile_hour_data,
                      location_map, last_check；无数据时返回 None
    """
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()

    cursor.execute("SELECT MIN(check_time), MAX(check_time), COUNT(*) FROM pile_status_log")
    row = cursor.fetchone()
    if not row or row[2] == 0:
        conn.close()
        return None

    min_time, max_time, total = row

    cursor.execute("""
        SELECT pile_no,
               CAST(strftime('%H', check_time) AS INTEGER) as hour,
               SUM(CASE WHEN status = 2 THEN 1 ELSE 0 END) as offline_count,
               COUNT(*) as total_count
        FROM pile_status_log
        GROUP BY pile_no, hour
        ORDER BY pile_no, hour
    """)
    rows = cursor.fetchall()

    pile_hour_data = {}
    for pile_no, hour, o, c in rows:
        if pile_no not in pile_hour_data:
            pile_hour_data[pile_no] = {}
        pile_hour_data[pile_no][hour] = (o, c)

    cursor.execute("SELECT DISTINCT pile_no, location FROM pile_status_log")
    location_map = {r[0]: r[1] for r in cursor.fetchall()}

    cursor.execute("SELECT MAX(check_time) FROM pile_status_log")
    last_check = cursor.fetchone()[0]
    conn.close()

    return {
        "min_time": min_time,
        "max_time": max_time,
        "total": total,
        "pile_hour_data": pile_hour_data,
        "location_map": location_map,
        "last_check": last_check
    }