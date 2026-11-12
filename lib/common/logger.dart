import 'package:bilimusic/common/diagnostics/player_diagnostics.dart';
import 'package:logger/logger.dart';

class AppLogger {
  AppLogger(String tag) : _tag = tag;

  final String _tag;

  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 8,
      lineLength: 100,
      printTime: true,
    ),
  );

  static void dioLogPrint(Object object) {
    AppLogger('Dio').d(object.toString());
  }

  void t(Object? message, [Object? error, StackTrace? stackTrace]) {
    _capture('t', message);
    _logger.t(_message(message), error: error, stackTrace: stackTrace);
  }

  void d(Object? message, [Object? error, StackTrace? stackTrace]) {
    _capture('d', message);
    _logger.d(_message(message), error: error, stackTrace: stackTrace);
  }

  void i(Object? message, [Object? error, StackTrace? stackTrace]) {
    _capture('i', message);
    _logger.i(_message(message), error: error, stackTrace: stackTrace);
  }

  void w(Object? message, [Object? error, StackTrace? stackTrace]) {
    _capture('w', message);
    _logger.w(_message(message), error: error, stackTrace: stackTrace);
  }

  void e(Object? message, [Object? error, StackTrace? stackTrace]) {
    _capture('e', message);
    _logger.e(_message(message), error: error, stackTrace: stackTrace);
  }

  void f(Object? message, [Object? error, StackTrace? stackTrace]) {
    _capture('f', message);
    _logger.f(_message(message), error: error, stackTrace: stackTrace);
  }

  /// 只把播放链路日志（带 [PlayerDebug] / [Diagnostics] 标记）写入本地诊断文件，
  /// 避免 Dio 等高频日志把文件撑爆、也避免拖慢后台播放。
  void _capture(String level, Object? message) {
    final String text = message?.toString() ?? '';
    if (!text.contains('[PlayerDebug]') && !text.contains('[Diagnostics]')) {
      return;
    }
    final String trimmed = text.length > 800 ? text.substring(0, 800) : text;
    PlayerDiagnostics.instance.log('console:$level $trimmed');
  }

  String _message(Object? message) {
    return '[$_tag] ${message ?? ''}'.trimRight();
  }
}
