# d:\MyCodeProject\charging-monitoring\python\api.py
# =================================================================
# 充电桩监控系统 - API 网络层
# 负责：HTTP 请求、桩号状态并发查询
# =================================================================

import time
from concurrent.futures import ThreadPoolExecutor, as_completed

import requests

from config import basic_url, headers, pile_no, pile_tag_map
from db import log_results_to_db


def fetch_api(config, max_retries=3, retry_delay=1.0):
    """根据配置发起 GET 请求，返回 JSON 数据，支持 503 自动重试

    Args:
        config: 请求配置字典，含 name/url/params
        max_retries: 最大重试次数（默认 3 次）
        retry_delay: 每次重试前等待秒数（默认 1 秒）

    Returns:
        dict: 成功返回 JSON 数据，失败返回 None
    """
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
            print(f"[{config['name']}] 成功, 耗时 {elapsed_ms:.0f} 毫秒")
            return data
        except requests.exceptions.HTTPError as e:
            elapsed_ms = (time.time() - start) * 1000
            if e.response is not None and e.response.status_code == 503:
                print(f"[{config['name']}] 503 限流, 耗时 {elapsed_ms:.0f} 毫秒, 第 {attempt} 次尝试, {retry_delay} 秒后重试")
                if attempt < max_retries:
                    time.sleep(retry_delay)
                    continue
            print(f"[{config['name']}] 请求失败({e.response.status_code if e.response else 'N/A'}), 耗时 {elapsed_ms:.0f} 毫秒: {e}")
            return None
        except requests.exceptions.RequestException as e:
            elapsed_ms = (time.time() - start) * 1000
            print(f"[{config['name']}] 请求失败, 耗时 {elapsed_ms:.0f} 毫秒: {e}")
            return None
    return None


def check_single_pile(pile, location):
    """查询单个充电桩状态，3 次重试全部失败视为离线

    Args:
        pile: 桩号（如 "0000224"）
        location: 位置信息

    Returns:
        tuple: (桩号, 位置, 状态数据或模拟离线数据)
    """
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
    """批处理查询桩号状态，3 次全部失败才记录为离线

    执行方式:
        - 按 batch_size（默认 2）分批
        - 每批并发查询，等该批全部完成后再开始下一批
    """
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
        print("\n=== 离线充电桩列表 ===")
        for p, location, _status_data in offline_piles:
            tag = pile_tag_map.get(p, "")
            location_display = f"[{tag}] {location}" if tag else location
            print(f"\n充电桩编号: {p}")
            print(f"位置: {location_display}")
            print("状态: 离线")

    print(f"\n共发现 {len(offline_piles)} 个离线充电桩")

    log_results_to_db(all_results)
    return all_results