# =================================================================
# 充电桩 Controller — /api/pile/*（类似 Spring Boot @RestController）
# =================================================================

from flask import Blueprint, request

from config import pile_tag_map
from model.result import ok
from service.pile_service import get_history_data, get_report_data
from utils.date_utils import parse_date_param

pile_bp = Blueprint("pile", __name__)


@pile_bp.route("/report")
def report():
    tag = request.args.get("tag", None)
    pile_no = request.args.get("pile_no", None)
    start_date = parse_date_param(request.args.get("start_date"), " 00:00:00")
    end_date = parse_date_param(request.args.get("end_date"), " 23:59:59")

    data = get_report_data(
        tag_filter=tag, pile_no_filter=pile_no,
        start_date=start_date, end_date=end_date,
    )
    if data is None:
        data = {"min_time": None, "max_time": None, "total": 0, "last_check": None, "piles": []}
    return ok(data)


@pile_bp.route("/history")
def history():
    tag = request.args.get("tag", None)
    pile_no = request.args.get("pile_no", None)
    data = get_history_data(tag_filter=tag, pile_no_filter=pile_no)
    if data is None:
        data = {"min_time": None, "max_time": None, "total": 0, "last_check": None, "piles": []}
    return ok(data)


@pile_bp.route("/tags")
def tags():
    all_tags = sorted(set(pile_tag_map.values()))
    tag_pile_map = {}
    for p, t in pile_tag_map.items():
        tag_pile_map.setdefault(t, []).append(p)
    return ok({"tags": tag_pile_map, "all_tags": all_tags})