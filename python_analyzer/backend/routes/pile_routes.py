# =================================================================
# 充电桩业务路由 - /api/pile/*
# =================================================================

from datetime import datetime, timedelta, timezone

from flask import Blueprint, jsonify, request

from analyzer import get_history_data, get_report_data
from config import pile_tag_map

pile_bp = Blueprint("pile", __name__)


@pile_bp.route("/report")
def report():
    tag = request.args.get("tag", None)
    pile_no = request.args.get("pile_no", None)
    today = datetime.now(tz=timezone(timedelta(hours=8))).strftime("%Y-%m-%d")
    start_date = request.args.get("start_date", today)
    end_date = request.args.get("end_date", today)
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
