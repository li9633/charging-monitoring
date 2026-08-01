# =================================================================
# 分页响应对象 — 类似 Spring Boot 的 PageResult<T>
# =================================================================

from flask import jsonify


def page_ok(records, total, page=1, page_size=20):
    """分页成功响应"""
    return jsonify({
        "code": 200,
        "message": "success",
        "data": {
            "records": records,
            "total": total,
            "page": page,
            "page_size": page_size
        }
    })
