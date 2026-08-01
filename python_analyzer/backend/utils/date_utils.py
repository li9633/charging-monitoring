# =================================================================
# 日期工具 — 参数解析、格式化
# =================================================================

from datetime import datetime, timedelta, timezone

TZ = timezone(timedelta(hours=8))


def parse_date_param(value, suffix):
    """解析并校验日期参数

    Args:
        value: 前端传入的原始值
        suffix: 纯日期时拼接的时间后缀（" 00:00:00" 或 " 23:59:59"）

    Returns:
        str: 格式化后的日期时间字符串

    处理场景：
        - "2026-07-25"          → "2026-07-25 00:00:00"
        - "2026-07-25 08:30:00" → 已含时间，直接返回
        - "abc" / "" / 无效     → 今天的日期 + suffix
    """
    default = datetime.now(tz=TZ).strftime("%Y-%m-%d") + suffix

    if not value:
        return default

    value = value.strip()
    if not value:
        return default

    if " " in value:
        try:
            datetime.strptime(value, "%Y-%m-%d %H:%M:%S").replace(tzinfo=TZ)
            return value
        except ValueError:
            pass
        try:
            datetime.strptime(value, "%Y-%m-%d %H:%M").replace(tzinfo=TZ)
            return value + ":00"
        except ValueError:
            pass

    try:
        datetime.strptime(value, "%Y-%m-%d").replace(tzinfo=TZ)
        return value + suffix
    except ValueError:
        pass

    return default
