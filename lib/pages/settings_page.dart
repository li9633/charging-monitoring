// =================================================================
// 设置页面：配置 wx-token、默认桩号、位置标签、充电记录拉取开关
// =================================================================

import 'package:flutter/material.dart';
import '../services/settings_service.dart';

class SettingsPage extends StatefulWidget {
  final SettingsService settings;
  final VoidCallback? onSettingsChanged;

  const SettingsPage({super.key, required this.settings, this.onSettingsChanged});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late TextEditingController _wxTokenController;
  late bool _useChargeRecord;
  late int _defaultFilter;
  late List<_MapEntry> _pileNoEntries;
  late List<_MapEntry> _tagEntries;

  @override
  void initState() {
    super.initState();
    _wxTokenController = TextEditingController(text: widget.settings.wxToken);
    _useChargeRecord = widget.settings.useChargeRecord;
    _defaultFilter = widget.settings.defaultFilter;
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
    super.dispose();
  }

  Future<void> _save() async {
    await widget.settings.setWxToken(_wxTokenController.text.trim());
    await widget.settings.setUseChargeRecord(_useChargeRecord);
    await widget.settings.setDefaultFilter(_defaultFilter);

    final pileNoMap = <String, String>{};
    for (final e in _pileNoEntries) {
      if (e.key.isNotEmpty && e.value.isNotEmpty) pileNoMap[e.key] = e.value;
    }
    await widget.settings.setDefaultPileNo(pileNoMap);

    final tagMap = <String, String>{};
    for (final e in _tagEntries) {
      if (e.key.isNotEmpty && e.value.isNotEmpty) tagMap[e.key] = e.value;
    }
    await widget.settings.setPileTagMap(tagMap);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('设置已保存，下次检测生效')),
      );
      widget.onSettingsChanged?.call();
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

          // 默认筛选
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('监测页默认筛选',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('应用启动后监测页面默认显示哪个分类',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                  const SizedBox(height: 12),
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 0, label: Text('全部')),
                      ButtonSegment(value: 1, label: Text('离线')),
                      ButtonSegment(value: 2, label: Text('在线')),
                    ],
                    selected: {_defaultFilter},
                    onSelectionChanged: (v) => setState(() => _defaultFilter = v.first),
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
            keyHint: '桩号',
            valueHint: '位置',
            onAdd: (key, value) => setState(() => _pileNoEntries.add(_MapEntry(key: key, value: value))),
            onEdit: (i, key, value) => setState(() {
              _pileNoEntries[i] = _MapEntry(key: key, value: value);
            }),
            onRemove: (i) => setState(() => _pileNoEntries.removeAt(i)),
          ),
          const SizedBox(height: 12),

          // 位置标签
          _buildSection(
            title: '位置标签',
            subtitle: '桩号 → 标签（如「地下室」「1号楼」）',
            entries: _tagEntries,
            keyHint: '桩号',
            valueHint: '标签',
            onAdd: (key, value) => setState(() => _tagEntries.add(_MapEntry(key: key, value: value))),
            onEdit: (i, key, value) => setState(() {
              _tagEntries[i] = _MapEntry(key: key, value: value);
            }),
            onRemove: (i) => setState(() => _tagEntries.removeAt(i)),
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
    required String keyHint,
    required String valueHint,
    required void Function(String key, String value) onAdd,
    required void Function(int index, String key, String value) onEdit,
    required void Function(int index) onRemove,
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
                      Text(title,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(subtitle,
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey[600])),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _showEntryDialog(
                    title: '添加$title',
                    keyHint: keyHint,
                    valueHint: valueHint,
                    onConfirm: (key, value) => onAdd(key, value),
                  ),
                  icon: const Icon(Icons.add_circle, color: Colors.teal),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (entries.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text('暂无数据，点击 + 添加',
                    style: TextStyle(color: Colors.grey[500], fontSize: 13)),
              )
            else
              ...entries.asMap().entries.map((e) {
                final i = e.key;
                final entry = e.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 6),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _showEntryDialog(
                      title: '编辑',
                      keyHint: keyHint,
                      valueHint: valueHint,
                      initialKey: entry.key,
                      initialValue: entry.value,
                      onConfirm: (key, value) => onEdit(i, key, value),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(entry.key,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14)),
                          ),
                          const Icon(Icons.arrow_forward,
                              size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 3,
                            child: Text(entry.value,
                                style: TextStyle(
                                    fontSize: 13, color: Colors.grey[700]),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle,
                                color: Colors.red, size: 20),
                            onPressed: () => onRemove(i),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Future<void> _showEntryDialog({
    required String title,
    required String keyHint,
    required String valueHint,
    String initialKey = '',
    String initialValue = '',
    required void Function(String key, String value) onConfirm,
  }) async {
    String? resultKey;
    String? resultValue;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        final keyCtrl = TextEditingController(text: initialKey);
        final valueCtrl = TextEditingController(text: initialValue);
        final formKey = GlobalKey<FormState>();

        return AlertDialog(
          title: Text(title),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: keyCtrl,
                  decoration: InputDecoration(
                    labelText: keyHint,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? '不能为空' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: valueCtrl,
                  decoration: InputDecoration(
                    labelText: valueHint,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  maxLines: 3,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? '不能为空' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  resultKey = keyCtrl.text.trim();
                  resultValue = valueCtrl.text.trim();
                  Navigator.pop(ctx);
                }
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );

    if (resultKey != null) {
      onConfirm(resultKey!, resultValue!);
    }
  }
}

class _MapEntry {
  final String key;
  final String value;

  const _MapEntry({required this.key, required this.value});
}