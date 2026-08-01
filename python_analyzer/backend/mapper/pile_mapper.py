# =================================================================
# 充电桩 Mapper — 数据库访问层（类似 MyBatis Mapper）
# =================================================================

import logging
import sqlite3
from datetime import datetime, timedelta, timezone

from config import DB_PATH

logger = logging.getLogger(__name__)


def init_db():
    """初始化数据库表"""
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
        CREATE INDEX IF NOT EXISTS idx_check_time
        ON pile_status_log(check_time)
    """)
    conn.commit()
    conn.close()


def insert_batch(all_results):
    """批量写入检测结果"""
    conn = sqlite3.connect(DB_PATH)
    now = datetime.now(tz=timezone(timedelta(hours=8))
                       ).strftime("%Y-%m-%d %H:%M:%S")
    rows = [
        (pile_no, location, status_data.get(
            'status', -1) if status_data else -1, now)
        for pile_no, location, status_data in all_results
    ]
    conn.executemany(
        "INSERT INTO pile_status_log (pile_no, location, status, check_time) VALUES (?, ?, ?, ?)",
        rows
    )
    conn.commit()
    conn.close()
    logger.info("已写入 %s 条状态记录到数据库", len(rows))


def delete_old_data(days=30):
    """清理过期数据"""
    cutoff = (datetime.now(tz=timezone(timedelta(hours=8))) -
              timedelta(days=days)).strftime("%Y-%m-%d %H:%M:%S")
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.execute(
        "DELETE FROM pile_status_log WHERE check_time < ?", (cutoff,))
    deleted = cursor.rowcount
    conn.commit()
    if deleted > 0:
        logger.info("已清理 %s 条超过 %s 天的旧数据", deleted, days)
    conn.close()


def query_report_data(start_date=None, end_date=None):
    """查询分析报告数据"""
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()

    conditions = []
    params = []
    if start_date is not None:
        conditions.append("check_time >= ?")
        params.append(start_date)
    if end_date is not None:
        conditions.append("check_time < ?")
        params.append(end_date)

    where_clause = " AND ".join(conditions) if conditions else "1=1"
    logger.debug("SQL条件: %s | 参数: %s", where_clause, params)

    cursor.execute(
        f"SELECT MIN(check_time), MAX(check_time), COUNT(*) FROM pile_status_log WHERE {where_clause}",
        params
    )
    row = cursor.fetchone()
    if not row or row[2] == 0:
        conn.close()
        return None

    min_time, max_time, total = row
    logger.debug("数据范围: %s ~ %s, 总记录: %s", min_time, max_time, total)

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

    pile_hour_data = {}
    for pile_no, hour, o, c in rows:
        if pile_no not in pile_hour_data:
            pile_hour_data[pile_no] = {}
        pile_hour_data[pile_no][hour] = (o, c)

    cursor.execute(
        f"SELECT DISTINCT pile_no, location FROM pile_status_log WHERE {where_clause}", params)
    location_map = {r[0]: r[1] for r in cursor.fetchall()}

    cursor.execute(
        f"SELECT MAX(check_time) FROM pile_status_log WHERE {where_clause}", params)
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