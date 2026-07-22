// =================================================================
// 关于页面：应用介绍、版本、开发者信息、GitHub 链接
// =================================================================

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  static const String githubUrl = 'https://github.com/xindev';
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() => _version = 'v${info.version} (build ${info.buildNumber})');
    }
  }

  Future<void> _openGitHub(BuildContext context) async {
    final uri = Uri.parse(githubUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('无法打开链接')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('关于'),
        backgroundColor: theme.colorScheme.inversePrimary,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // 应用图标
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.teal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.ev_station,
                  size: 40,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(height: 16),

              // 应用名
              const Text(
                '充电桩监测',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),

              // 版本号
              Text(
                _version.isEmpty ? '加载中...' : _version,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),

              // 功能简介
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.info_outline, size: 18, color: Colors.teal),
                          SizedBox(width: 8),
                          Text('功能介绍',
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '实时监测充电桩在线状态，支持批量查询、离线筛选、'
                        '日志记录等功能。通过充电记录自动发现充电桩，'
                        '也可手动配置默认桩号进行监测。',
                        style: TextStyle(fontSize: 13, height: 1.6),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 开发者信息
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.person_outline, size: 18, color: Colors.teal),
                          SizedBox(width: 8),
                          Text('开发者',
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text('xindev',
                          style: TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // GitHub
              Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _openGitHub(context),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.code, size: 18, color: Colors.teal),
                        const SizedBox(width: 8),
                        const Text('GitHub',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        Text(githubUrl,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600])),
                        const SizedBox(width: 4),
                        const Icon(Icons.open_in_new,
                            size: 16, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 底部版权
              Text(
                '© 2026 xindev',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}