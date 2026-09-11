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
        Text(tr(s, 'Обзор хранилища', 'Storage insights'),
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _card(context, Icons.pie_chart_outline,
                tr(s, 'Анализ места', 'Space analysis'),
                tr(s, 'Категории и размеры каталогов', 'Categories and folder sizes'),
                onTap: () => _analyze(s)),
            _card(context, Icons.copy_all_outlined,
                tr(s, 'Дубликаты', 'Duplicates'),
                tr(s, 'Сканирование по размеру и хэшу', 'Size and hash scanning'),
                onTap: () => _scanDuplicates(s)),
            _card(context, Icons.data_usage,
                tr(s, 'Большие файлы', 'Large files'),
                tr(s, 'Найти самые объёмные элементы', 'Find largest items'),
                onTap: () => _scanLarge(s)),
            _card(context, Icons.history,
                tr(s, 'Недавние', 'Recent'), '${s.recent.length}',
                onTap: () => _paths(s.recent.take(15).toList())),
            _card(context, Icons.delete_sweep_outlined,
                tr(s, 'Корзина', 'Trash'), '.fz_trash',
                onTap: () => _trash(s)),
            _card(context, Icons.star,
                tr(s, 'Закладки', 'Bookmarks'), '${s.bookmarks.length}',
                onTap: () => _paths(s.bookmarks.toList())),
          ],
        ),
        const SizedBox(height: 20),
        if (largeFiles.isNotEmpty) ...[
          Text(tr(s, 'Большие файлы', 'Large files'),
              style: Theme.of(context).textTheme.titleLarge),
          ...largeFiles.map((e) => ListTile(
              leading: const Icon(Icons.insert_drive_file_outlined),
              title: Text(e.name),
              subtitle: Text(formatBytes(e.size)))),
        ],
      ],
    );
  }

  Widget _card(BuildContext c, IconData i, String t, String sub, {VoidCallback? onTap}) =>
      SizedBox(
        width: 260,
        height: 145,
        child: Card(
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(i),
                  const Spacer(),
                  Text(t, style: Theme.of(c)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
                  Text(sub, maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
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
              'В этом MVP доступен каркас функции.',
          'Scanning will show folder sizes in the current storage. '
              'In this MVP the function scaffold is available.',
        )),
        actions: [
          TextButton(onPressed: () => Navigator.pop(x),
              child: Text(tr(s, 'ОК', 'OK'))),
        ],
      ),
    );
  }

  Future<void> _scanDuplicates(AppState s) async {
    _snack(tr(s, 'Сканер дубликатов — каркас', 'Duplicates scanner — scaffold'));
  }

  Future<void> _scanLarge(AppState s) async {
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
  }

  Future<void> _trash(AppState s) async {
    final trash = Directory('${s.path}${Platform.pathSeparator}.fz_trash');
    if (!await trash.exists()) {
      _snack(tr(s, 'Корзина пуста', 'Trash is empty'));
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
                            leading: Icon(e is Directory
                                ? Icons.folder
                                : Icons.insert_drive_file_outlined),
                            title: Text(e.path.split(Platform.pathSeparator).last),
                            trailing: IconButton(
                              icon: const Icon(Icons.restore),
                              tooltip: tr(s, 'Восстановить', 'Restore'),
                              onPressed: () async {
                                final name = e.path
                                    .split(Platform.pathSeparator)
                                    .last;
                                final cleaned = name.contains('_')
                                    ? name.substring(name.indexOf('_') + 1)
                                    : name;
                                final target =
                                    '${s.path}${Platform.pathSeparator}$cleaned';
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
          TextButton(onPressed: () => Navigator.pop(x),
              child: Text(tr(s, 'Закрыть', 'Close'))),
        ],
      ),
    );
  }

  void _paths(List<String> p) {
    if (p.isEmpty) {
      _snack(tr(widget.state, 'Пока пусто', 'Empty for now'));
      return;
    }
    showDialog(
      context: context,
      builder: (x) => AlertDialog(
        title: Text(tr(widget.state, 'Пути', 'Paths')),
        content: SizedBox(
          width: 500,
          child: ListView(shrinkWrap: true,
              children: p.map((v) => ListTile(title: Text(v))).toList()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(x),
              child: Text(tr(widget.state, 'Закрыть', 'Close'))),
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
