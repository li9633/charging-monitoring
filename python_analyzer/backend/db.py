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
    """将本轮所有查询结果批量写入数据库

    Args:
        all_results: [(pile_no, location, status_data), ...]
    """
    conn = sqlite3.connect(DB_PATH)
    now = datetime.now(tz=timezone(timedelta(hours=8))).strftime("%Y-%m-%d %H:%M:%S")
    rows = [
        (pile_no, location, status_data.get('status', -1) if status_data else -1, now)
        for pile_no, location, status_data in all_results
    ]
    conn.executemany(
        "INSERT INTO pile_status_log (pile_no, location, status, check_time) VALUES (?, ?, ?, ?)",
        rows
    )
    conn.commit()
    conn.close()
    print(f"已写入 {len(rows)} 条状态记录到数据库")


def cleanup_old_data(days=30):
    """删除超过指定天数的旧数据，并回收磁盘空间"""
    cutoff = (datetime.now(tz=timezone(timedelta(hours=8))) - timedelta(days=days)).strftime("%Y-%m-%d %H:%M:%S")
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.execute("DELETE FROM pile_status_log WHERE check_time < ?", (cutoff,))
    deleted = cursor.rowcount
    conn.commit()
    if deleted > 0:
        conn.execute("VACUUM")
        print(f"已清理 {deleted} 条超过 {days} 天的旧数据，并回收磁盘空间")
    conn.close()


def query_report_data(start_date=None, end_date=None):
    """从数据库查询分析报告所需的全部数据

    Args:
        start_date: 可选，起始日期（格式 "YYYY-MM-DD"），None 表示不限制
        end_date: 可选，结束日期（格式 "YYYY-MM-DD"），None 表示不限制
        两者都为 None 时查询全部数据

    Returns:
        dict or None: 包含 min_time, max_time, total, pile_hour_data,
                      location_map, last_check；无数据时返回 None
    """
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()

    conditions = []
    params = []
    if start_date is not None:
        conditions.append("check_time >= ?")
        params.append(start_date + " 00:00:00")
    if end_date is not None:
        conditions.append("check_time < ?")
        params.append(end_date + " 23:59:59")

    where_clause = " AND ".join(conditions) if conditions else "1=1"
    print(f"[SQL] 条件: {where_clause} | 参数: {params}")

    cursor.execute(
        f"SELECT MIN(check_time), MAX(check_time), COUNT(*) FROM pile_status_log WHERE {where_clause}",
        params
    )
    row = cursor.fetchone()
    if not row or row[2] == 0:
        conn.close()
        return None

    min_time, max_time, total = row
    print(f"[SQL] 数据范围: {min_time} ~ {max_time}, 总记录: {total}")

    cursor.execute(f"""
        SELECT pile_no,
               CAST(strftime('%H', check_time) AS INTEGER) as hour,
               SUM(CASE WHEN status = 2 THEN 1 ELSE 0 END) as offline_count,
               COUNT(*) as total_count
        FROM pile_status_log
        WHERE {where_clause}
        GROUP BY pile_no, hour
        ORDER BY pile_no, hour
    """, params)
    rows = cursor.fetchall()
    print(f"[SQL] 按桩号小时聚合结果: {len(rows)} 行")

    pile_hour_data = {}
    for pile_no, hour, o, c in rows:
        if pile_no not in pile_hour_data:
            pile_hour_data[pile_no] = {}
        pile_hour_data[pile_no][hour] = (o, c)

    print(f"[SQL] 涉及桩号: {list(pile_hour_data.keys())}")

    cursor.execute(f"SELECT DISTINCT pile_no, location FROM pile_status_log WHERE {where_clause}", params)
    location_map = {r[0]: r[1] for r in cursor.fetchall()}

    cursor.execute(f"SELECT MAX(check_time) FROM pile_status_log WHERE {where_clause}", params)
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