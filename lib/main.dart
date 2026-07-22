// =================================================================
// 充电桩离线检测 - Flutter 应用
// 底部导航: 监测 | 日志 | 设置
// 启动时自动拉取充电桩状态，支持下拉刷新
// =================================================================

import 'package:flutter/material.dart';
import 'services/settings_service.dart';
import 'pages/monitor_page.dart';
import 'pages/logs_page.dart';
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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: HomePage(settings: settings),
    );
  }
}

class HomePage extends StatefulWidget {
  final SettingsService settings;

  const HomePage({super.key, required this.settings});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final _monitorKey = GlobalKey<MonitorPageState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          MonitorPage(key: _monitorKey, settings: widget.settings),
          const LogsPage(),
          SettingsPage(
            settings: widget.settings,
            onSettingsChanged: () {
              _monitorKey.currentState?.rebuildService();
            },
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.monitor_heart_outlined),
            selectedIcon: Icon(Icons.monitor_heart),
            label: '监测',
          ),
          NavigationDestination(
            icon: Icon(Icons.article_outlined),
            selectedIcon: Icon(Icons.article),
            label: '日志',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '设置',
          ),
        ],
      ),
    );
  }
}