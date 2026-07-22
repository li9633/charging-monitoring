// =================================================================
// 监测页面：充电桩状态检测（自动启动 + 下拉刷新 + Tab 筛选）
// =================================================================

import 'package:flutter/material.dart';
import '../services/pile_service.dart';
import '../services/settings_service.dart';
import '../services/log_service.dart';

class MonitorPage extends StatefulWidget {
  final SettingsService settings;

  const MonitorPage({super.key, required this.settings});

  @override
  State<MonitorPage> createState() => MonitorPageState();
}

class MonitorPageState extends State<MonitorPage>
    with SingleTickerProviderStateMixin {
  final LogService _log = LogService();
  late PileService _service;
  bool _isLoading = false;
  CheckResult? _result;
  String? _errorMessage;
  late TabController _tabController;

  static const _tabs = ['全部', '离线', '在线'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
        length: _tabs.length,
        vsync: this,
        initialIndex: widget.settings.defaultFilter);
    rebuildService();
    // 自动启动检测
    WidgetsBinding.instance.addPostFrameCallback((_) => _startCheck());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void rebuildService() {
    _service = PileService(
      wxToken: widget.settings.wxToken,
      pileTagMap: widget.settings.pileTagMap,
      defaultPileNo: widget.settings.defaultPileNo,
      useChargeRecord: widget.settings.useChargeRecord,
    );
  }

  Future<void> _startCheck() async {
    setState(() {
      _isLoading = true;
      _result = null;
      _errorMessage = null;
    });

    try {
      rebuildService();
      _log.info('开始检测充电桩状态...');
      final pileInfo = await _service.getPileList();
      _log.info('共获取 ${pileInfo.length} 个充电桩');
      final checkResult = await _service.checkOfflinePiles(pileInfo);
      final offline = checkResult.allPiles.where((p) => p.isOffline).length;
      final online = checkResult.allPiles.where((p) => p.isOnline).length;
      _log.info('检测完成: 在线 $online, 离线 $offline, 耗时 ${checkResult.elapsedMs}ms');
      setState(() {
        _result = checkResult;
        _isLoading = false;
      });
    } catch (e) {
      _log.error('检测失败: $e');
      setState(() {
        _errorMessage = '检测失败: $e';
        _isLoading = false;
      });
    }
  }

  List<PileStatus> _filteredPiles() {
    if (_result == null) return [];
    final all = _result!.allPiles;
    switch (_tabController.index) {
      case 0:
        return all;
      case 1:
        return all.where((p) => p.isOffline).toList();
      case 2:
        return all.where((p) => p.isOnline).toList();
      default:
        return all;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('充电桩监测'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '刷新检测',
            onPressed: _isLoading ? null : _startCheck,
          ),
        ],
        bottom: _result != null
            ? TabBar(
                controller: _tabController,
                tabs: _tabs.map((t) => Tab(text: t)).toList(),
                onTap: (_) => setState(() {}),
              )
            : null,
      ),
      body: RefreshIndicator(
        onRefresh: _startCheck,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_result == null && _errorMessage == null && !_isLoading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.ev_station,
                      size: 80,
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.4)),
                  const SizedBox(height: 16),
                  Text('正在初始化...',
                      style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6))),
                  const SizedBox(height: 8),
                  Text('下拉可重新检测',
                      style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.4))),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (_isLoading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 24),
                  Text('正在检测充电桩状态...',
                      style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.7))),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (_errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(_errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16, color: Colors.red)),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _startCheck,
                      icon: const Icon(Icons.refresh),
                      label: const Text('重试'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    final filtered = _filteredPiles();
    final checkResult = _result!;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.timer, size: 28),
                const SizedBox(width: 12),
                Text('总耗时: ${checkResult.elapsedMs} 毫秒',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text('共 ${checkResult.allPiles.length} 个桩',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600])),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '${_tabs[_tabController.index]} ${filtered.length} 个充电桩',
          style: TextStyle(
            fontSize: 16,
            color: _tabController.index == 1 && filtered.isEmpty
                ? Colors.green
                : Colors.blueGrey,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          SizedBox(
            height: 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 60, color: Colors.green[400]),
                  const SizedBox(height: 16),
                  Text(
                    _tabController.index == 1 ? '所有充电桩均在线' : '无匹配结果',
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
          )
        else
          ...filtered.map((pile) => _buildPileCard(pile)),
      ],
    );
  }

  Widget _buildPileCard(PileStatus pile) {
    final locationDisplay =
        pile.tag.isNotEmpty ? '[${pile.tag}] ${pile.location}' : pile.location;
    final isOffline = pile.isOffline;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isOffline ? Colors.red[100] : Colors.green[100],
          child: Icon(Icons.ev_station,
              color: isOffline ? Colors.red[700] : Colors.green[700]),
        ),
        title: Text('充电桩编号: ${pile.pileNo}',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('位置: $locationDisplay\n状态: ${isOffline ? "离线" : "在线"}',
            style: const TextStyle(fontSize: 13)),
        isThreeLine: true,
      ),
    );
  }
}