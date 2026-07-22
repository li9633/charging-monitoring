// =================================================================
// 充电桩离线检测 - Flutter 应用
// 功能:
//   1. Tab 筛选: 全部 / 离线（默认） / 在线
//   2. 设置页: 配置 wx-token、默认桩号、位置标签、充电记录拉取开关
//   3. 点击「开始检测」后批处理查询所有桩状态
// =================================================================

import 'package:flutter/material.dart';
import 'services/pile_service.dart';
import 'services/settings_service.dart';
import 'pages/settings_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = await SettingsService.create();
  runApp(MyApp(settings: settings));
}

class MyApp extends StatelessWidget {
  final SettingsService settings;

  const MyApp({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '充电桩离线检测',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: PileCheckerPage(settings: settings),
    );
  }
}

class PileCheckerPage extends StatefulWidget {
  final SettingsService settings;

  const PileCheckerPage({super.key, required this.settings});

  @override
  State<PileCheckerPage> createState() => _PileCheckerPageState();
}

class _PileCheckerPageState extends State<PileCheckerPage>
    with SingleTickerProviderStateMixin {
  late PileService _service;
  bool _isLoading = false;
  CheckResult? _result;
  String? _errorMessage;
  late TabController _tabController;

  static const _tabs = ['全部', '离线', '在线'];
  static const _defaultTabIndex = 1; // 默认选中「离线」

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this, initialIndex: _defaultTabIndex);
    _rebuildService();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _rebuildService() {
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
      _rebuildService();
      final pileInfo = await _service.getPileList();
      final checkResult = await _service.checkOfflinePiles(pileInfo);
      setState(() {
        _result = checkResult;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '检测失败: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _openSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsPage(settings: widget.settings),
      ),
    );
    // 从设置页返回后，刷新服务配置
    _rebuildService();
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
        title: const Text('充电桩离线检测'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
            tooltip: '设置',
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
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _startCheck,
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.electrical_services),
        label: Text(_isLoading ? '检测中...' : '开始检测'),
      ),
    );
  }

  Widget _buildBody() {
    if (_result == null && _errorMessage == null && !_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.ev_station, size: 80,
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text('点击下方按钮开始检测',
                style: TextStyle(fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
            const SizedBox(height: 8),
            Text('将自动检测所有充电桩的在线状态',
                style: TextStyle(fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4))),
          ],
        ),
      );
    }

    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text('正在检测充电桩状态...',
                style: TextStyle(fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(_errorMessage!, textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.red)),
            ],
          ),
        ),
      );
    }

    final filtered = _filteredPiles();
    final checkResult = _result!;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
              color: _tabController.index == 1 && filtered.isEmpty ? Colors.green : Colors.blueGrey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: filtered.isEmpty
                ? Center(
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
                  )
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) => _buildPileCard(filtered[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPileCard(PileStatus pile) {
    final locationDisplay = pile.tag.isNotEmpty ? '[${pile.tag}] ${pile.location}' : pile.location;
    final isOffline = pile.isOffline;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isOffline ? Colors.red[100] : Colors.green[100],
          child: Icon(Icons.ev_station, color: isOffline ? Colors.red[700] : Colors.green[700]),
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