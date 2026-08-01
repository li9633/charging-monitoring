# =================================================================
# 充电桩 Service — 业务逻辑层（分析报告、历史数据）
# =================================================================

from config import pile_tag_map
from mapper.pile_mapper import query_report_data


def _merge_suspicious_ranges(hours):
    """将离散的疑似小时合并为连续的时段字符串"""
    if not hours:
        return ""
    ranges = []
    s = e = hours[0]
    for h in hours[1:]:
        if h == e + 1:
            e = h
        else:
            ranges.append((s, e))
            s = e = h
    ranges.append((s, e))
    return ", ".join(
        f"{s:02d}:00-{e:02d}:59" if s != e else f"{s:02d}:00-{s:02d}:59"
        for s, e in ranges
    )


def get_report_data(tag_filter=None, pile_no_filter=None, start_date=None, end_date=None):
    """返回结构化报告数据

    Args:
        tag_filter: 可选，按标签筛选（如 "地下室"）
        pile_no_filter: 可选，按桩号筛选（如 "0000224"）
        start_date: 可选，起始日期时间字符串
        end_date: 可选，结束日期时间字符串
    """
    data = query_report_data(start_date=start_date, end_date=end_date)
    if data is None:
        return None

    pile_hour_data = data["pile_hour_data"]
    location_map = data["location_map"]

    piles = []
    for pile_no in sorted(pile_hour_data.keys()):
        hour_data = pile_hour_data[pile_no]
        location = location_map.get(pile_no, "未知")
        tag = pile_tag_map.get(pile_no, "")

        if tag_filter is not None and tag != tag_filter:
            continue
        if pile_no_filter is not None and pile_no != pile_no_filter:
            continue

        loc_display = f"[{tag}] {location}" if tag else location

        total_checks = sum(t for _, t in hour_data.values())
        total_offline = sum(o for o, _ in hour_data.values())
        offline_rate = (total_offline / total_checks *
                        100) if total_checks > 0 else 0

        hours = []
        suspicious = []
        for hour in range(24):
            o, c = hour_data.get(hour, (0, 0))
            r = o / c * 100 if c > 0 else 0
            css_class = ""
            if r >= 80 and c >= 2:
                css_class = "d"
                suspicious.append(hour)
            elif r >= 50 and c >= 2 or r >= 80 and c >= 1:
                css_class = "w"
            elif c > 0:
                css_class = "g"
            hours.append({
                "hour": hour,
                "label": f"{hour:02d}:00",
                "checks": c,
                "offline": o,
                "rate": round(r),
                "css_class": css_class
            })

        suspicious_ranges = _merge_suspicious_ranges(
            suspicious) if suspicious else ""

        if offline_rate >= 50:
            status_color, status_text = "#e74c3c", "严重"
        elif offline_rate >= 20:
            status_color, status_text = "#f39c12", "注意"
        else:
            status_color, status_text = "#27ae60", "正常"

        piles.append({
            "pile_no": pile_no,
            "location": location,
            "tag": tag,
            "loc_display": loc_display,
            "total_checks": total_checks,
            "total_offline": total_offline,
            "online": total_checks - total_offline,
            "offline_rate": round(offline_rate, 1),
            "status": status_text,
            "status_color": status_color,
            "suspicious_ranges": suspicious_ranges,
            "hours": hours
        })

    return {
        "min_time": data["min_time"],
        "max_time": data["max_time"],
        "total": data["total"],
        "last_check": data["last_check"],
        "piles": piles
    }


def get_history_data(tag_filter=None, pile_no_filter=None):
    """返回全部历史数据分析报告"""
    return get_report_data(tag_filter=tag_filter, pile_no_filter=pile_no_filter, start_date=None, end_date=None)


def analyze_offline_patterns():
    """控制台输出：分析各充电桩的在线/离线时段分布"""
    data = query_report_data()
    if data is None:
        print("数据库中暂无数据，请先运行检测脚本收集数据")
        return

    pile_hour_data = data["pile_hour_data"]
    location_map = data["location_map"]

    print(f"\n{'=' * 60}")
    print("           充电桩离线时段分析报告")
    print(f"{'=' * 60}")
    print(f"数据范围: {data['min_time']} ~ {data['max_time']}")
    print(f"总检查次数: {data['total']}")

    for pile_no in sorted(pile_hour_data.keys()):
        hour_data = pile_hour_data[pile_no]
        location = location_map.get(pile_no, "未知")
        tag = pile_tag_map.get(pile_no, "")
        location_display = f"[{tag}] {location}" if tag else location

        total_checks = sum(t for _, t in hour_data.values())
        total_offline = sum(o for o, _ in hour_data.values())
        offline_rate = (total_offline / total_checks *
                        100) if total_checks > 0 else 0

        print(f"\n{'─' * 60}")
        print(f"桩号: {pile_no} | {location_display}")
        print(
            f"总检查: {total_checks} | 在线: {total_checks - total_offline} | 离线: {total_offline} | 离线率: {offline_rate:.1f}%")
        print(f"\n{'时':>3} | {'检查':>5} | {'离线':>5} | {'离线率':>7} | 标记")
        print("-" * 40)

        suspicious_hours = []
        for hour in range(24):
            o, c = hour_data.get(hour, (0, 0))
            r = o / c * 100 if c > 0 else 0
            flag = ""
            if r >= 80 and c >= 2:
                flag = " ***"
                suspicious_hours.append(hour)
            elif r >= 50 and c >= 2:
                flag = "  *"
            print(f"{hour:>3} | {c:>5} | {o:>5} | {r:>6.0f}% |{flag}")

        if suspicious_hours:
            rs = _merge_suspicious_ranges(suspicious_hours)
            print(f"\n⚠ 疑似禁用时段: {rs}")

    print(f"\n{'=' * 60}")
    print("*** 离线率>=80%  |  * 离线率>=50%")
    print(f"{'=' * 60}")
