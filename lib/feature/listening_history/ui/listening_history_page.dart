import 'package:bilimusic/common/components/cached_image.dart';
import 'package:bilimusic/common/components/status_view.dart';
import 'package:bilimusic/common/util/player_util.dart';
import 'package:bilimusic/feature/listening_history/data/listening_history_local_repository.dart';
import 'package:bilimusic/feature/listening_history/domain/listening_history_entry.dart';
import 'package:bilimusic/feature/player/domain/playable_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ListeningHistoryPage extends ConsumerStatefulWidget {
  const ListeningHistoryPage({super.key, this.desktop = false});

  final bool desktop;

  @override
  ConsumerState<ListeningHistoryPage> createState() =>
      _ListeningHistoryPageState();
}

class _ListeningHistoryPageState extends ConsumerState<ListeningHistoryPage>
    with WidgetsBindingObserver {
  static const String _sourceLabel = '收听记录';

  final ListeningHistoryLocalRepository _repository =
      const ListeningHistoryLocalRepository();
  List<ListeningHistoryEntry> _entries = <ListeningHistoryEntry>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _reload();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _reload();
  }

  void _reload() {
    final Map<String, ListeningHistoryEntry> latestByGroup =
        <String, ListeningHistoryEntry>{};
    for (final ListeningHistoryEntry entry in _repository.load()) {
      latestByGroup.putIfAbsent(entry.groupKey, () => entry);
    }
    final List<ListeningHistoryEntry> grouped =
        latestByGroup.values.toList(growable: false)
          ..sort(
            (ListeningHistoryEntry a, ListeningHistoryEntry b) =>
                b.updatedAtMs.compareTo(a.updatedAtMs),
          );
    if (mounted) setState(() => _entries = grouped);
  }

  Future<void> _play(ListeningHistoryEntry entry) async {
    await PlayerUtil.playQueueAndOpenPlayer(
      context,
      ref,
      items: <PlayableItem>[entry.toPlayableItem()],
      startIndex: 0,
      sourceLabel: _sourceLabel,
      initialPosition: entry.resumePosition,
    );
    _reload();
  }

  Future<void> _remove(ListeningHistoryEntry entry) async {
    await _repository.remove(entry.stableId);
    _reload();
  }

  Future<void> _clearAll() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('清空收听记录？'),
        content: const Text('会删除本机保存的全部播放进度，此操作无法恢复。'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('清空'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _repository.clear();
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: widget.desktop
          ? null
          : AppBar(
              title: const Text(_sourceLabel),
              actions: <Widget>[
                IconButton(
                  tooltip: '清空收听记录',
                  icon: const Icon(Icons.delete_sweep_outlined),
                  onPressed: _entries.isEmpty ? null : _clearAll,
                ),
              ],
            ),
      body: _entries.isEmpty
          ? StatusView(
              icon: Icons.history_rounded,
              iconColor: colorScheme.primary,
              title: '还没有收听记录',
              description: '播放过的音频会按分 P 记住进度，\n下次点开自动接着上次的位置播放。',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 8, 6),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          '${_sourceLabel} · ${_entries.length} 个资源',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (widget.desktop)
                        IconButton(
                          tooltip: '清空收听记录',
                          icon: const Icon(Icons.delete_sweep_outlined),
                          onPressed: _clearAll,
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _entries.length,
                    itemBuilder: (BuildContext context, int index) {
                      final ListeningHistoryEntry entry = _entries[index];
                      return _HistoryTile(
                        entry: entry,
                        colorScheme: colorScheme,
                        subtitle: _subtitle(entry),
                        onTap: () => _play(entry),
                        onRemove: () => _remove(entry),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  String _subtitle(ListeningHistoryEntry entry) {
    final List<String> parts = <String>[];
    if (entry.partLabel.isNotEmpty) parts.add(entry.partLabel);
    final String pageTitle = entry.pageTitle?.trim() ?? '';
    if (pageTitle.isNotEmpty && pageTitle != entry.title) {
      parts.add(pageTitle);
    }
    if (entry.completed) {
      parts.add('已听完 · 下次从头播放');
    } else {
      final String position = _formatDuration(entry.position);
      parts.add(
        entry.durationMs > 0
            ? '已听到 $position / ${_formatDuration(entry.duration)}'
            : '已听到 $position',
      );
    }
    parts.add(_formatTime(entry.updatedAtMs));
    return parts.join(' · ');
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.entry,
    required this.colorScheme,
    required this.subtitle,
    required this.onTap,
    required this.onRemove,
  });

  final ListeningHistoryEntry entry;
  final ColorScheme colorScheme;
  final String subtitle;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      children: <Widget>[
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          leading: CommonCachedImage(
            imageUrl: entry.coverUrl,
            width: 48,
            height: 48,
            fit: BoxFit.cover,
            borderRadius: BorderRadius.circular(8),
            fallbackIcon: Icons.music_note_rounded,
            iconColor: colorScheme.primary,
            backgroundColor: colorScheme.primary.withValues(alpha: 0.14),
          ),
          title: Text(
            entry.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          trailing: IconButton(
            tooltip: '删除这条记录',
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: onRemove,
          ),
          onTap: onTap,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: LinearProgressIndicator(
            value: entry.completed ? 1.0 : entry.progress,
            minHeight: 2,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 6),
      ],
    );
  }
}

String _formatDuration(Duration value) {
  final int total = value.inSeconds < 0 ? 0 : value.inSeconds;
  final int hours = total ~/ 3600;
  final int minutes = (total % 3600) ~/ 60;
  final int seconds = total % 60;
  final String mm = minutes.toString().padLeft(2, '0');
  final String ss = seconds.toString().padLeft(2, '0');
  return hours > 0 ? '$hours:$mm:$ss' : '$minutes:$ss';
}

String _formatTime(int epochMs) {
  final DateTime time = DateTime.fromMillisecondsSinceEpoch(epochMs);
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(time.month)}-${two(time.day)} ${two(time.hour)}:${two(time.minute)}';
}
