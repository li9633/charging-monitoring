// =================================================================
// 日志页面：按级别筛选查看程序运行日志
// 支持长按复制、导出到文件
// =================================================================

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/log_service.dart';

class LogsPage extends StatefulWidget {
  const LogsPage({super.key});

  @override
  State<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage>
    with SingleTickerProviderStateMixin {
  final LogService _logService = LogService();
  late TabController _filterController;
  StreamSubscription<LogEntry>? _logSub;

  static const _filters = ['全部', 'INFO', 'WARN', 'ERROR', 'DEBUG'];
  static const _levelMap = {
    'INFO': LogLevel.info,
    'WARN': LogLevel.warning,
    'ERROR': LogLevel.error,
    'DEBUG': LogLevel.debug,
  };

  @override
  void initState() {
    super.initState();
    _filterController = TabController(length: _filters.length, vsync: this);
    _filterController.addListener(() => setState(() {}));
    _logSub = _logService.onLog.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _logSub?.cancel();
    _filterController.dispose();
    super.dispose();
  }

  List<LogEntry> get _filteredLogs {
    final all = _logService.logs.reversed.toList();
    if (_filterController.index == 0) return all;
    final targetLevel = _levelMap[_filters[_filterController.index]];
    return all.where((e) => e.level == targetLevel).toList();
  }

  Color _levelColor(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return Colors.grey;
      case LogLevel.info:
        return Colors.blue;
      case LogLevel.warning:
        return Colors.orange;
      case LogLevel.error:
        return Colors.red;
    }
  }

  IconData _levelIcon(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return Icons.bug_report;
      case LogLevel.info:
        return Icons.info_outline;
      case LogLevel.warning:
        return Icons.warning_amber;
      case LogLevel.error:
        return Icons.error_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final logs = _filteredLogs;
    return Scaffold(
      appBar: AppBar(
        title: const Text('运行日志'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share),
            tooltip: '导出日志',
            onPressed: _exportLogs,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: '清空日志',
            onPressed: () {
              setState(() => _logService.clear());
            },
          ),
        ],
        bottom: TabBar(
          controller: _filterController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: _filters.map((f) => Tab(text: f)).toList(),
        ),
      ),
      body: logs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.article_outlined,
                      size: 60,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text('暂无日志',
                      style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.5))),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(8),
              itemCount: logs.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final entry = logs[index];
                final color = _levelColor(entry.level);
                final time = '${entry.timestamp.hour.toString().padLeft(2, '0')}:'
                    '${entry.timestamp.minute.toString().padLeft(2, '0')}:'
                    '${entry.timestamp.second.toString().padLeft(2, '0')}';
                return ListTile(
                  dense: true,
                  leading: Icon(_levelIcon(entry.level), color: color, size: 20),
                  onLongPress: () => _copyToClipboard(entry),
                  title: Row(
                    children: [
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(entry.levelLabel,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: color)),
                      ),
                      const SizedBox(width: 8),
                      Text(time,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(entry.message,
                        style: const TextStyle(fontSize: 13)),
                  ),
                );
              },
            ),
    );
  }

  void _copyToClipboard(LogEntry entry) {
    final time = '${entry.timestamp.hour.toString().padLeft(2, '0')}:'
        '${entry.timestamp.minute.toString().padLeft(2, '0')}:'
        '${entry.timestamp.second.toString().padLeft(2, '0')}';
    final text = '[$time] [${entry.levelLabel}] ${entry.message}';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已复制到剪贴板'), duration: Duration(seconds: 1)),
    );
  }

  Future<void> _exportLogs() async {
    final all = _logService.logs.reversed.toList();
    if (all.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('暂无日志可导出')),
      );
      return;
    }

    final buffer = StringBuffer();
    buffer.writeln('充电桩监测 - 运行日志');
    buffer.writeln('─' * 50);

    final deviceInfo = await _buildDeviceInfo();
    buffer.writeln(deviceInfo);

    buffer.writeln('导出时间: ${DateTime.now()}');
    buffer.writeln('共 ${all.length} 条日志');
    buffer.writeln('─' * 50);
    for (final entry in all) {
      final time = '${entry.timestamp.hour.toString().padLeft(2, '0')}:'
          '${entry.timestamp.minute.toString().padLeft(2, '0')}:'
          '${entry.timestamp.second.toString().padLeft(2, '0')}';
      buffer.writeln('[$time] [${entry.levelLabel}] ${entry.message}');
    }

    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/charging_monitor_logs.txt');
      await file.writeAsString(buffer.toString());
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: $e')),
        );
      }
    }
  }

  Future<String> _buildDeviceInfo() async {
    final buffer = StringBuffer();
    try {
      final pkg = await PackageInfo.fromPlatform();
      buffer.writeln('应用: ${pkg.appName}');
      buffer.writeln('版本: ${pkg.version} (build ${pkg.buildNumber})');
      buffer.writeln('包名: ${pkg.packageName}');
    } catch (_) {
      buffer.writeln('应用信息: 获取失败');
    }

    buffer.writeln('系统: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}');

    try {
      final plugin = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final android = await plugin.androidInfo;
        buffer.writeln('设备型号: ${android.model}');
        buffer.writeln('制造商: ${android.manufacturer}');
        buffer.writeln('Android 版本: ${android.version.release}');
        buffer.writeln('API 级别: ${android.version.sdkInt}');
        buffer.writeln('品牌: ${android.brand}');
        buffer.writeln('硬件: ${android.hardware}');
      } else if (Platform.isIOS) {
        final ios = await plugin.iosInfo;
        buffer.writeln('设备型号: ${ios.model}');
        buffer.writeln('设备名称: ${ios.name}');
        buffer.writeln('iOS 版本: ${ios.systemVersion}');
      }
    } catch (_) {
      buffer.writeln('设备信息: 获取失败');
    }

    return buffer.toString();
  }
}