// =================================================================
// 充电桩离线检测服务
// 执行流程:
//   1. 尝试拉取充电记录接口，提取历史使用的桩号
//   2. 如果拉取失败（如 401），则使用默认桩号配置
//   3. 批处理并发查询所有桩号的状态（每批 2 个并发）
//   4. 只返回离线的充电桩信息
//   5. 记录任务总耗时
// =================================================================

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class PileService {
  // 充电桩 API 基础地址
  static const String basicUrl = 'https://api-mini.cdyun.vip';

  final String wxToken;
  final Map<String, String> pileTagMap;
  final Map<String, String> defaultPileNo;
  final bool useChargeRecord;

  PileService({
    required this.wxToken,
    required this.pileTagMap,
    required this.defaultPileNo,
    required this.useChargeRecord,
  });

  // 请求头
  Map<String, String> get headers => {
        'WX-Token': wxToken,
        'User-Agent':
            'Mozilla/5.0 (iPhone; CPU iPhone OS 18_7 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 MicroMessenger/8.0.69(0x18004539) NetType/WIFI Language/zh_CN',
        'Content-Type': 'application/json',
      };

  // =================================================================
  // 3. 通用请求函数：带 503 自动重试，记录每次请求耗时
  // =================================================================
  Future<dynamic> fetchApi(
    String name,
    String url,
    Map<String, String> params, {
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 1),
  }) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      final stopwatch = Stopwatch()..start();
      try {
        final uri = Uri.parse(url).replace(queryParameters: params);
        final response = await http
            .get(
              uri,
              headers: headers,
            )
            .timeout(const Duration(seconds: 10));

        stopwatch.stop();
        final elapsedMs = stopwatch.elapsedMilliseconds;

        if (response.statusCode == 200) {
          debugPrint('[$name] 成功, 耗时 $elapsedMs 毫秒');
          return jsonDecode(response.body);
        } else if (response.statusCode == 503) {
          // 503 = 服务器限流/过载：等待后自动重试
          debugPrint(
              '[$name] 503 限流, 耗时 $elapsedMs 毫秒, 第 $attempt 次尝试, ${retryDelay.inSeconds} 秒后重试');
          if (attempt < maxRetries) {
            await Future.delayed(retryDelay);
            continue;
          }
        }
        debugPrint(
            '[$name] 请求失败(${response.statusCode}), 耗时 $elapsedMs 毫秒');
        return null;
      } catch (e) {
        stopwatch.stop();
        final elapsedMs = stopwatch.elapsedMilliseconds;
        debugPrint('[$name] 请求失败, 耗时 $elapsedMs 毫秒: $e');
        return null;
      }
    }
    return null;
  }

  // =================================================================
  // 4. 获取桩号列表：优先从充电记录拉取，失败回退到默认配置
  // =================================================================
  Future<Map<String, String>> getPileList() async {
    // 如果用户关闭了优先拉取充电记录，直接使用默认桩号
    if (!useChargeRecord) {
      debugPrint('已关闭充电记录拉取，直接使用默认充电桩配置');
      debugPrint('默认配置共 ${defaultPileNo.length} 个充电桩');
      return Map<String, String>.from(defaultPileNo);
    }

    // 步骤 1：尝试拉取最近 100 条充电记录
    final data = await fetchApi('充电记录',
        '$basicUrl/btzncdz/charge-record/index',
        {'page': '0', 'size': '100', 'card': '', 'lang': 'zh'});

    // 步骤 2：如果拉取成功，提取桩号和位置信息（自动去重）
    if (data != null) {
      final pileInfo = <String, String>{};
      if (data is List) {
        for (final record in data) {
          if (record is Map<String, dynamic>) {
            final pileNo = record['pileNo'] as String?;
            final location = record['location'] as String?;
            if (pileNo != null && location != null) {
              pileInfo.putIfAbsent(pileNo, () => location);
            }
          }
        }
      } else if (data is Map && data.containsKey('records')) {
        final records = data['records'] as List?;
        if (records != null) {
          for (final record in records) {
            if (record is Map<String, dynamic>) {
              final pileNo = record['pileNo'] as String?;
              final location = record['location'] as String?;
              if (pileNo != null && location != null) {
                pileInfo.putIfAbsent(pileNo, () => location);
              }
            }
          }
        }
      }
      return pileInfo;
    }

    // 步骤 3：拉取失败 → 使用默认桩号配置
    debugPrint('无法拉取充电记录，已使用默认充电桩配置进行查询');
    debugPrint('默认配置共 ${defaultPileNo.length} 个充电桩');
    return Map<String, String>.from(defaultPileNo);
  }

  // =================================================================
  // 5. 查询单个桩状态：作为并发任务的最小执行单元
  // =================================================================
  Future<Map<String, dynamic>?> checkSinglePile(
      String pileNo, String location) async {
    final statusData = await fetchApi(
        '充电桩状态_$pileNo',
        '$basicUrl/btzncdz/charge-pile/show',
        {'pileNo': pileNo, 'lang': 'zh'});
    if (statusData != null) {
      statusData['_pileNo'] = pileNo;
      statusData['_location'] = location;
    }
    return statusData;
  }

  // =================================================================
  // 6. 批处理查询所有桩号：每批 2 个并发，等该批完成后再开始下一批
  // =================================================================
  Future<CheckResult> checkOfflinePiles(Map<String, String> pileInfo) async {
    final stopwatch = Stopwatch()..start();
    final allPiles = <PileStatus>[];

    if (pileInfo.isEmpty) {
      stopwatch.stop();
      return CheckResult(allPiles: [], elapsedMs: stopwatch.elapsedMilliseconds);
    }

    final pileList = pileInfo.entries.toList();
    const batchSize = 2;
    final total = pileList.length;

    for (int batchStart = 0; batchStart < total; batchStart += batchSize) {
      final batchEnd = (batchStart + batchSize > total) ? total : batchStart + batchSize;
      final batch = pileList.sublist(batchStart, batchEnd);

      final futures = batch.map((entry) => checkSinglePile(entry.key, entry.value));
      final results = await Future.wait(futures);

      for (final statusData in results) {
        if (statusData != null) {
          final statusCode = statusData['status'] as int? ?? 0;
          final pileNo = statusData['_pileNo'] as String;
          final location = statusData['_location'] as String;
          final tag = pileTagMap[pileNo] ?? '';
          allPiles.add(PileStatus(
            pileNo: pileNo,
            location: location,
            tag: tag,
            status: statusCode,
          ));
        }
      }
    }

    stopwatch.stop();
    return CheckResult(
      allPiles: allPiles,
      elapsedMs: stopwatch.elapsedMilliseconds,
    );
  }
}

// =================================================================
// 7. 数据模型
// =================================================================
class PileStatus {
  final String pileNo;
  final String location;
  final String tag;
  final int status; // 0=未知, 1=在线, 2=离线

  bool get isOnline => status == 1;
  bool get isOffline => status == 2;

  PileStatus({
    required this.pileNo,
    required this.location,
    required this.tag,
    required this.status,
  });
}

class CheckResult {
  final List<PileStatus> allPiles;
  final int elapsedMs;

  List<PileStatus> get offlinePiles =>
      allPiles.where((p) => p.isOffline).toList();
  List<PileStatus> get onlinePiles =>
      allPiles.where((p) => p.isOnline).toList();

  CheckResult({
    required this.allPiles,
    required this.elapsedMs,
  });
}