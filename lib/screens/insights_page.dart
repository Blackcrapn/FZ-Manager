import 'dart:io';
import 'package:flutter/material.dart';
import '../app.dart';
import '../widgets.dart';

class InsightsPage extends StatefulWidget {
  const InsightsPage({super.key, required this.state});
  final AppState state;
  @override
  State<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends State<InsightsPage> {
  bool scanning = false;
  List<FileEntryLike> largeFiles = [];

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SectionHeader(
          title: tr(s, 'Обзор хранилища', 'Storage insights'),
          subtitle: tr(s, 'Здоровье хранилища одним экраном', 'Storage health at a glance'),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _card(context, Icons.pie_chart_outline_rounded,
                tr(s, 'Анализ места', 'Space analysis'),
                tr(s, 'Категории и размеры каталогов', 'Categories and folder sizes'),
                onTap: () => _analyze(s)),
            _card(context, Icons.copy_all_rounded,
                tr(s, 'Дубликаты', 'Duplicates'),
                tr(s, 'Сканирование по размеру и хэшу', 'Size and hash scanning'),
                onTap: () => _scanDuplicates(s)),
            _card(context, Icons.data_usage_rounded,
                tr(s, 'Большие файлы', 'Large files'),
                tr(s, 'Найти самые объёмные элементы', 'Find largest items'),
                onTap: () => _scanLarge(s)),
            _card(context, Icons.history_rounded,
                tr(s, 'Недавние', 'Recent'), '${s.recent.length}',
                onTap: () => _paths(tr(s, 'Недавние папки', 'Recent folders'), s.recent.take(15).toList())),
            _card(context, Icons.delete_sweep_rounded,
                tr(s, 'Корзина', 'Trash'), '.fz_trash',
                onTap: () => _trash(s)),
            _card(context, Icons.star_rounded,
                tr(s, 'Закладки', 'Bookmarks'), '${s.bookmarks.length}',
                onTap: () => _paths(tr(s, 'Закладки путей', 'Path bookmarks'), s.bookmarks.toList())),
          ],
        ),
        const SizedBox(height: 20),
        if (scanning)
          const Center(child: CircularProgressIndicator())
        else if (largeFiles.isNotEmpty) ...[
          SectionHeader(title: tr(s, 'Большие файлы', 'Large files')),
          const SizedBox(height: 10),
          GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: largeFiles
                  .map((e) => ListTile(
                        dense: true,
                        leading: const Icon(Icons.insert_drive_file_outlined),
                        title: Text(e.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(e.path, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)),
                        trailing: Text(formatBytes(e.size), style: const TextStyle(fontWeight: FontWeight.w700)),
                      ))
                  .toList(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _card(BuildContext c, IconData i, String t, String sub, {VoidCallback? onTap}) => SizedBox(
        width: 260,
        height: 145,
        child: GlassCard(
          padding: const EdgeInsets.all(16),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(i, size: 28),
                const Spacer(),
                Text(t, style: Theme.of(c).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                Text(sub, maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ),
      );

  Future<void> _analyze(AppState s) async {
    showDialog(
      context: context,
      builder: (x) => AlertDialog(
        title: Text(tr(s, 'Анализ места', 'Space analysis')),
        content: Text(tr(
            s,
            'Сканирование покажет размеры папок в текущем хранилище. '
            'В этом выпуске доступен каркас функции.',
            'Scanning will show folder sizes in the current storage. '
            'In this release the function scaffold is available.')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(x), child: Text(tr(s, 'ОК', 'OK'))),
        ],
      ),
    );
  }

  Future<void> _scanDuplicates(AppState s) async {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(tr(s, 'Сканер дубликатов — каркас', 'Duplicates scanner — scaffold'))));
  }

  Future<void> _scanLarge(AppState s) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      scanning = true;
      largeFiles = [];
    });
    final root = s.path;
    final found = <FileEntryLike>[];
    try {
      await for (final e in Directory(root).list(recursive: true, followLinks: false)) {
        if (e is! File) continue;
        try {
          final st = await e.stat();
          if (st.size > 50 * 1024 * 1024) {
            found.add(FileEntryLike(
                e.uri.pathSegments.where((x) => x.isNotEmpty).last, e.path, st.size));
          }
        } catch (_) {}
      }
      found.sort((a, b) => b.size.compareTo(a.size));
    } catch (_) {}
    if (mounted) {
      setState(() {
        largeFiles = found.take(50).toList();
        scanning = false;
      });
    }
    if (found.isEmpty) {
      messenger.showSnackBar(SnackBar(
          content: Text(tr(s, 'Файлов больше 50 МБ не найдено', 'No files above 50 MB found'))));
    }
  }

  Future<void> _trash(AppState s) async {
    final trash = Directory('${s.path}${Platform.pathSeparator}.fz_trash');
    if (!await trash.exists()) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(tr(s, 'Корзина пуста', 'Trash is empty'))));
      return;
    }
    final entries = <FileSystemEntity>[];
    await for (final e in trash.list()) {
      entries.add(e);
    }
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (x) => AlertDialog(
        title: Text(tr(s, 'Корзина', 'Trash')),
        content: SizedBox(
          width: 500,
          child: entries.isEmpty
              ? Text(tr(s, 'Корзина пуста', 'Trash is empty'))
              : ListView(
                  shrinkWrap: true,
                  children: entries
                      .map((e) => ListTile(
                            leading: Icon(e is Directory ? Icons.folder_rounded : Icons.insert_drive_file_outlined),
                            title: Text(e.path.split(Platform.pathSeparator).last,
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            trailing: IconButton(
                              icon: const Icon(Icons.restore_rounded),
                              tooltip: tr(s, 'Восстановить', 'Restore'),
                              onPressed: () async {
                                final name = e.path.split(Platform.pathSeparator).last;
                                final cleaned = name.contains('_') ? name.substring(name.indexOf('_') + 1) : name;
                                final target = '${s.path}${Platform.pathSeparator}$cleaned';
                                try {
                                  if (e is Directory) {
                                    await Directory(e.path).rename(target);
                                  } else {
                                    await File(e.path).rename(target);
                                  }
                                  s.log('${tr(s, 'Восстановлено', 'Restored')}: $cleaned');
                                } catch (err) {
                                  _snack(err.toString());
                                }
                                if (x.mounted) Navigator.pop(x);
                                _trash(s);
                              },
                            ),
                          ))
                      .toList(),
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(x), child: Text(tr(s, 'Закрыть', 'Close'))),
        ],
      ),
    );
  }

  void _paths(String title, List<String> p) {
    if (p.isEmpty) {
      _snack(tr(widget.state, 'Пока пусто', 'Empty for now'));
      return;
    }
    showDialog(
      context: context,
      builder: (x) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 500,
          child: ListView(shrinkWrap: true, children: p.map((v) => ListTile(title: Text(v))).toList()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(x), child: Text(tr(widget.state, 'Закрыть', 'Close'))),
        ],
      ),
    );
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
}

class FileEntryLike {
  final String name, path;
  final int size;
  FileEntryLike(this.name, this.path, this.size);
}
