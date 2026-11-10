// 预览组件使用
import 'package:bilimusic/common/components/badged_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

@Preview(name: 'badge Icon button')
Widget previewBadgeIconButton() {
  return BadgedIconButton(
    onPressed: () {},
    noBadgeIcon: const Icon(Icons.play_arrow),
    badgeIcon: const Icon(Icons.play_circle_fill_sharp),
    badge: const Text('100'),
  );
}
