# =================================================================
# 充电桩业务路由 - /api/pile/*
# =================================================================

from datetime import datetime, timedelta, timezone

from flask import Blueprint, jsonify, request

from analyzer import get_history_data, get_report_data
from config import pile_tag_map

pile_bp = Blueprint("pile", __name__)


def _parse_date(value, suffix):
    """解析并校验日期参数

    Args:
        value: 前端传入的原始值
        suffix: 纯日期时拼接的时间后缀（" 00:00:00" 或 " 23:59:59"）

    Returns:
        str: 格式化后的日期时间字符串

    处理场景：
        - "2026-07-25"          → "2026-07-25 00:00:00"
        - "2026-07-25 08:30:00" → "2026-07-25 08:30:00"（已含时间，不拼接）
        - "abc" / "" / 无效     → 今天的日期 + suffix
    """
    if not value:
        return datetime.now(tz=timezone(timedelta(hours=8))).strftime("%Y-%m-%d") + suffix

    value = value.strip()
    if not value:
        return datetime.now(tz=timezone(timedelta(hours=8))).strftime("%Y-%m-%d") + suffix

    # 如果已经包含时间部分（有空格），直接返回
    if " " in value:
        try:
            datetime.strptime(value, "%Y-%m-%d %H:%M:%S").replace(tzinfo=timezone(timedelta(hours=8)))
            return value
        except ValueError:
            pass
        try:
            datetime.strptime(value, "%Y-%m-%d %H:%M").replace(tzinfo=timezone(timedelta(hours=8)))
            return value + ":00"
        except ValueError:
            pass

    # 纯日期格式校验
    try:
        datetime.strptime(value, "%Y-%m-%d").replace(tzinfo=timezone(timedelta(hours=8)))
        return value + suffix
    except ValueError:
        pass

    # 无效输入 → 默认今天
    return datetime.now(tz=timezone(timedelta(hours=8))).strftime("%Y-%m-%d") + suffix


@pile_bp.route("/report")
def report():
    tag = request.args.get("tag", None)
    pile_no = request.args.get("pile_no", None)
    start_date = _parse_date(request.args.get("start_date"), " 00:00:00")
    end_date = _parse_date(request.args.get("end_date"), " 23:59:59")
    return jsonify(get_report_data(
        tag_filter=tag, pile_no_filter=pile_no,
        start_date=start_date, end_date=end_date,
    ))


@pile_bp.route("/history")
def history():
    tag = request.args.get("tag", None)
    pile_no = request.args.get("pile_no", None)
    return jsonify(get_history_data(tag_filter=tag, pile_no_filter=pile_no))


@pile_bp.route("/tags")
def tags():
    tags = {}
    for pile, tag in pile_tag_map.items():
        if tag not in tags:
            tags[tag] = []
        tags[tag].append(pile)
    return jsonify({"tags": tags, "all_tags": list(tags.keys())})