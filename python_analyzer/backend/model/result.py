# =================================================================
# 统一响应对象 — 类似 Spring Boot 的 Result<T>
# =================================================================

from flask import jsonify


def ok(data=None, message="success"):
    """成功响应"""
    return jsonify({"code": 200, "message": message, "data": data})


def fail(message="error", code=400):
    """失败响应"""
    return jsonify({"code": code, "message": message, "data": None}), code


def success(message="success"):
    """无数据成功响应（如删除、重启等）"""
    return jsonify({"code": 200, "message": message, "data": None})
