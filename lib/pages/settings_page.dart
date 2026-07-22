// =================================================================
// 设置页面：配置 wx-token、默认桩号、位置标签、充电记录拉取开关
// =================================================================

import 'package:flutter/material.dart';
import '../services/settings_service.dart';

class SettingsPage extends StatefulWidget {
  final SettingsService settings;

  const SettingsPage({super.key, required this.settings});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late TextEditingController _wxTokenController;
  late bool _useChargeRecord;
  late List<_MapEntry> _pileNoEntries;
  late List<_MapEntry> _tagEntries;

  @override
  void initState() {
    super.initState();
    _wxTokenController = TextEditingController(text: widget.settings.wxToken);
    _useChargeRecord = widget.settings.useChargeRecord;
    _pileNoEntries = widget.settings.defaultPileNo.entries
        .map((e) => _MapEntry(key: e.key, value: e.value))
        .toList();
    _tagEntries = widget.settings.pileTagMap.entries
        .map((e) => _MapEntry(key: e.key, value: e.value))
        .toList();
  }

  @override
  void dispose() {
    _wxTokenController.dispose();
    for (final e in _pileNoEntries) {
      e.keyController.dispose();
      e.valueController.dispose();
    }
    for (final e in _tagEntries) {
      e.keyController.dispose();
      e.valueController.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    await widget.settings.setWxToken(_wxTokenController.text.trim());
    await widget.settings.setUseChargeRecord(_useChargeRecord);

    final pileNoMap = <String, String>{};
    for (final e in _pileNoEntries) {
      final k = e.keyController.text.trim();
      final v = e.valueController.text.trim();
      if (k.isNotEmpty && v.isNotEmpty) pileNoMap[k] = v;
    }
    await widget.settings.setDefaultPileNo(pileNoMap);

    final tagMap = <String, String>{};
    for (final e in _tagEntries) {
      final k = e.keyController.text.trim();
      final v = e.valueController.text.trim();
      if (k.isNotEmpty && v.isNotEmpty) tagMap[k] = v;
    }
    await widget.settings.setPileTagMap(tagMap);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('设置已保存，下次检测生效')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          TextButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: const Text('保存'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // WX-Token
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('WX-Token', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _wxTokenController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: '输入认证 Token',
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 充电记录开关
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('优先拉取充电记录',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                          '启用后优先从充电记录提取桩号，失败时回退到默认配置',
                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _useChargeRecord,
                    onChanged: (v) => setState(() => _useChargeRecord = v),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 默认桩号配置
          _buildSection(
            title: '默认桩号配置',
            subtitle: '桩号 → 位置（拉取失败或关闭充电记录时使用）',
            entries: _pileNoEntries,
            onAdd: () => setState(() => _pileNoEntries.add(_MapEntry(key: '', value: ''))),
            onRemove: (i) => setState(() {
              _pileNoEntries[i].keyController.dispose();
              _pileNoEntries[i].valueController.dispose();
              _pileNoEntries.removeAt(i);
            }),
          ),
          const SizedBox(height: 12),

          // 位置标签
          _buildSection(
            title: '位置标签',
            subtitle: '桩号 → 标签（如「地下室」「1号楼」）',
            entries: _tagEntries,
            onAdd: () => setState(() => _tagEntries.add(_MapEntry(key: '', value: ''))),
            onRemove: (i) => setState(() {
              _tagEntries[i].keyController.dispose();
              _tagEntries[i].valueController.dispose();
              _tagEntries.removeAt(i);
            }),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String subtitle,
    required List<_MapEntry> entries,
    required VoidCallback onAdd,
    required void Function(int) onRemove,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                    ],
                  ),
                ),
                IconButton(onPressed: onAdd, icon: const Icon(Icons.add_circle, color: Colors.teal)),
              ],
            ),
            const SizedBox(height: 8),
            ...entries.asMap().entries.map((e) {
              final i = e.key;
              final entry = e.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: entry.keyController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: '桩号',
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: entry.valueController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: '位置/标签',
                          isDense: true,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                      onPressed: () => onRemove(i),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _MapEntry {
  final TextEditingController keyController;
  final TextEditingController valueController;

  _MapEntry({required String key, required String value})
      : keyController = TextEditingController(text: key),
        valueController = TextEditingController(text: value);
}