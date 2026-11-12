import 'dart:collection';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// 播放链路诊断日志。
///
/// 目的：iOS 真机在后台 / 锁屏播放时无法接 Xcode 控制台，因此把关键事件
/// 同时写在内存和 App 的 Documents 目录里，用户可以在「我的 → 播放诊断」
/// 里直接复制发出来，或在 iOS「文件」App 中导出 [fileName]。
class PlayerDiagnostics {
  PlayerDiagnostics._();

  static final PlayerDiagnostics instance = PlayerDiagnostics._();

  static const String fileName = 'player_diagnostics.log';
  static const int maxLines = 1200;
  static const int maxReadBytes = 240 * 1024;

  final Queue<String> _lines = Queue<String>();
  Future<void> _writes = Future<void>.value();
  String _lifecycle = 'unknown';

  String get lifecycle => _lifecycle;

  /// 当前 App 生命周期（resumed / inactive / paused / hidden / detached）。
  void onLifecycleChanged(String state) {
    _lifecycle = state;
    log('lifecycle', <String, Object?>{'state': state});
  }

  void log(String event, [Map<String, Object?>? details]) {
    final DateTime now = DateTime.now();
    final String stamp =
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}.'
        '${now.millisecond.toString().padLeft(3, '0')}';
    final StringBuffer buffer = StringBuffer('$stamp [$_lifecycle] $event');
    if (details != null && details.isNotEmpty) {
      buffer.write(' | ');
      buffer.write(
        details.entries
            .map((MapEntry<String, Object?> entry) =>
                '${entry.key}=${entry.value}')
            .join(', '),
      );
    }
    final String line = buffer.toString();
    _lines.addLast(line);
    while (_lines.length > maxLines) {
      _lines.removeFirst();
    }
    _append(line);
  }

  void _append(String line) {
    _writes = _writes.then<void>((_) async {
      try {
        final File file = await logFile();
        await file.writeAsString('$line\n', mode: FileMode.append, flush: true);
      } on Object {
        // 诊断日志本身不能影响播放。
      }
    });
  }

  Future<File> logFile() async {
    final Directory directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$fileName');
  }

  /// 优先读磁盘（包含 App 被系统杀掉前的记录），失败时退回内存缓冲。
  Future<String> readText() async {
    await _writes;
    try {
      final File file = await logFile();
      if (await file.exists()) {
        final String content = await file.readAsString();
        if (content.length > maxReadBytes) {
          return content.substring(content.length - maxReadBytes);
        }
        return content;
      }
    } on Object {
      // 退回内存缓冲。
    }
    return _lines.join('\n');
  }

  Future<String> logFilePath() async {
    final File file = await logFile();
    return file.path;
  }

  Future<void> clear() async {
    _lines.clear();
    _writes = _writes.then<void>((_) async {
      try {
        final File file = await logFile();
        await file.writeAsString('', flush: true);
      } on Object {
        // 忽略。
      }
    });
    await _writes;
    log('diagnostics:cleared');
  }
}
