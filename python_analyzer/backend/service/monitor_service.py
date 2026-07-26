# =================================================================
# 监控 Service — 充电桩状态查询 + 离线检测
# =================================================================

import logging
import time
from concurrent.futures import ThreadPoolExecutor, as_completed

import requests

from config import basic_url, headers, pile_no, pile_tag_map
from mapper.pile_mapper import insert_batch

logger = logging.getLogger(__name__)


def fetch_api(config, max_retries=3, retry_delay=1.0):
    """根据配置发起 GET 请求，返回 JSON 数据，支持 503 自动重试"""
    for attempt in range(1, max_retries + 1):
        start = time.time()
        try:
            resp = requests.get(
                config["url"],
                params=config["params"],
                headers=headers,
                timeout=10,
                verify=False
            )
            resp.raise_for_status()
            elapsed_ms = (time.time() - start) * 1000
            data = resp.json()
            logger.debug("[%s] 成功, 耗时 %.0f 毫秒", config['name'], elapsed_ms)
            return data
        except requests.exceptions.HTTPError as e:
            elapsed_ms = (time.time() - start) * 1000
            if e.response is not None and e.response.status_code == 503:
                logger.warning("[%s] 503 限流, 耗时 %.0f 毫秒, 第 %s 次尝试",
                               config['name'], elapsed_ms, attempt)
                if attempt < max_retries:
                    time.sleep(retry_delay)
                    continue
            logger.error("[%s] HTTP错误(%s), 耗时 %.0f 毫秒: %s", config['name'],
                         e.response.status_code if e.response else 'N/A', elapsed_ms, e)
            return None
        except requests.exceptions.RequestException as e:
            elapsed_ms = (time.time() - start) * 1000
            logger.error("[%s] 请求失败, 耗时 %.0f 毫秒: %s",
                         config['name'], elapsed_ms, e)
            return None
    return None


def check_single_pile(pile, location):
    """查询单个充电桩状态，3 次重试全部失败视为离线"""
    status_config = {
        "name": f"充电桩状态_{pile}",
        "url": f"{basic_url}/btzncdz/charge-pile/show",
        "params": {"pileNo": pile, "lang": "zh"}
    }
    status_data = fetch_api(status_config)
    if status_data is None:
        status_data = {"status": 2}
    return pile, location, status_data


def check_offline_piles():
    """批处理查询桩号状态，3 次全部失败才记录为离线"""
    pile_list = list(pile_no.items())
    batch_size = 2
    total = len(pile_list)

    offline_piles = []
    all_results = []

    for batch_start in range(0, total, batch_size):
        batch_end = min(batch_start + batch_size, total)
        batch = pile_list[batch_start:batch_end]

        batch_results = []
        with ThreadPoolExecutor(max_workers=batch_size) as executor:
            futures = [
                executor.submit(check_single_pile, p, loc)
                for p, loc in batch
            ]
            for future in as_completed(futures):
                batch_results.append(future.result())

        all_results.extend(batch_results)

        for p, location, status_data in batch_results:
            status_code = status_data.get("status", 0)
            if status_code == 2:
                offline_piles.append((p, location, status_data))

    if offline_piles:
        logger.warning("=== 离线充电桩列表 ===")
        for p, location, _status_data in offline_piles:
            tag = pile_tag_map.get(p, "")
            location_display = f"[{tag}] {location}" if tag else location
            logger.warning("充电桩编号: %s, 位置: %s", p, location_display)

    logger.info("共发现 %s 个离线充电桩", len(offline_piles))

    insert_batch(all_results)
    return all_results
