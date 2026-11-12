import 'dart:async';

import 'package:bilimusic/common/diagnostics/player_diagnostics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// 「我的 → 播放诊断」：不接电脑、不用 Xcode，直接在手机上把播放日志发出去。
class PlayerDiagnosticsPage extends StatefulWidget {
  const PlayerDiagnosticsPage({super.key, this.desktop = false});

  final bool desktop;

  @override
  State<PlayerDiagnosticsPage> createState() => _PlayerDiagnosticsPageState();
}

class _PlayerDiagnosticsPageState extends State<PlayerDiagnosticsPage> {
  static const int _displayLines = 300;

  Timer? _timer;
  String _allText = '';
  String _displayText = '';
  String _version = '';
  String _path = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_loadMeta());
    unawaited(_refresh());
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      unawaited(_refresh());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadMeta() async {
    String version = '';
    try {
      final PackageInfo info = await PackageInfo.fromPlatform();
      version = '${info.version}+${info.buildNumber}';
    } on Object {
      version = '未知';
    }
    try {
      _path = await PlayerDiagnostics.instance.logFilePath();
    } on Object {
      _path = '未知';
    }
    if (mounted) {
      setState(() => _version = version);
    }
  }

  Future<void> _refresh() async {
    final String all = await PlayerDiagnostics.instance.readText();
    final List<String> lines = all
        .split('\n')
        .where((String line) => line.trim().isNotEmpty)
        .toList(growable: false);
    final int start = lines.length > _displayLines
        ? lines.length - _displayLines
        : 0;
    final String display = lines
        .sublist(start)
        .reversed
        .join('\n');
    if (!mounted) return;
    setState(() {
      _allText = all;
      _displayText = display;
      _loading = false;
    });
  }

  Future<void> _copyAll() async {
    await _refresh();
    if (_allText.trim().isEmpty) {
      _showMessage('还没有日志，先按下面的步骤复现一次');
      return;
    }
    await Clipboard.setData(ClipboardData(text: _allText));
    _showMessage('已复制 ${_allText.length} 个字符，直接粘贴发给开发者即可');
  }

  Future<void> _copyPath() async {
    if (_path.isEmpty || _path == '未知') {
      await _loadMeta();
    }
    await Clipboard.setData(ClipboardData(text: _path));
    _showMessage('已复制日志文件路径');
  }

  Future<void> _clear() async {
    await PlayerDiagnostics.instance.clear();
    await _refresh();
    _showMessage('日志已清空，可以开始复现了');
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('播放诊断')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              children: <Widget>[
                _buildGuideCard(theme),
                const SizedBox(height: 12),
                _buildMetaCard(theme),
                const SizedBox(height: 12),
                Text(
                  '最近 $_displayLines 条（新的在最上面，每 3 秒自动刷新）',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_displayText.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      '暂无日志。播放任意音频后这里就会出现记录。',
                      style: theme.textTheme.bodyMedium,
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(
                      _displayText,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        height: 1.35,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  FilledButton.icon(
                    onPressed: _copyAll,
                    icon: const Icon(Icons.copy_all_rounded, size: 18),
                    label: const Text('复制全部日志'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('刷新'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _copyPath,
                    icon: const Icon(Icons.folder_open_rounded, size: 18),
                    label: const Text('复制文件路径'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _clear,
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text('清空日志'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideCard(ThemeData theme) {
    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '怎么把日志发出来（不用等一小时）',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '1. 点「清空日志」，随便播放一个多 P 资源的某一分 P\n'
              '2. 把进度条拖到最后 1 分钟以内\n'
              '3. 按 Home 回桌面或锁屏，保持 40~60 秒\n'
              '4. 回到 App → 我的 → 播放诊断 → 点「复制全部日志」\n'
              '5. 粘贴发给开发者即可\n'
              '\n'
              '日志同时保存在 App 的 Documents 目录，iOS「文件」App → '
              '我的 iPhone → Bilimusic 里也能直接导出 player_diagnostics.log。',
              style: TextStyle(fontSize: 13, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('App 版本：$_version'),
            const SizedBox(height: 4),
            Text('当前状态：${PlayerDiagnostics.instance.lifecycle}'),
            const SizedBox(height: 4),
            Text(
              '日志文件：$_path',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
