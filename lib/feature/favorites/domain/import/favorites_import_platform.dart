import 'package:bilimusic/feature/meting/domain/meting_server.dart';

enum FavoritesImportPlatform {
  netease('netease', '网易云音乐', MetingServer.netease),
  tencent('tencent', 'QQ音乐', MetingServer.tencent);

  const FavoritesImportPlatform(this.apiValue, this.label, this.metingServer);

  final String apiValue;
  final String label;
  final MetingServer metingServer;

  static FavoritesImportPlatform fromApiValue(String value) {
    for (final FavoritesImportPlatform platform in values) {
      if (platform.apiValue == value) {
        return platform;
      }
    }
    return netease;
  }
}
