import 'package:bilimusic/feature/player/domain/audio_stream_info.dart';
import 'package:flutter/material.dart';

class PlayerQualityBadge extends StatelessWidget {
  const PlayerQualityBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final Color color =
        IconTheme.of(context).color ??
        Theme.of(context).colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 1.4),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}

String qualityBadgeLabel({required List<AudioQualityOption> qualities}) {
  AudioQualityOption? quality;
  for (final AudioQualityOption option in qualities) {
    if (option.isSelected) {
      quality = option;
      break;
    }
  }

  quality ??= qualities.isEmpty ? null : qualities.first;
  if (quality == null) {
    return 'HQ';
  }

  final String label = quality.label.toLowerCase();
  if (quality.qualityId == 192000 || label.contains('192k')) {
    return 'SQ';
  }

  if (label.contains('hi-res')) {
    return 'HiRse';
  }

  return 'HQ';
}

bool hasSelectedQuality(List<AudioQualityOption> qualities) {
  for (final AudioQualityOption option in qualities) {
    if (option.isSelected) {
      return true;
    }
  }

  return false;
}
