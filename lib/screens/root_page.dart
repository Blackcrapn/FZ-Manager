import 'dart:async';
import 'package:flutter/material.dart';
import '../app.dart';
import '../native_service.dart';

class RootPage extends StatefulWidget {
  const RootPage({super.key, required this.state});
  final AppState state;
  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  bool busy = false;
  bool rootDirLoading = false;
  String rootDir = '/';
  List<RootEntry> rootItems = [];
  String? rootError;

  Future<void> check() async {
    setState(() => busy = true);
    final ok = await NativeService.instance.isRootAvailable();
    widget.state.rootChecked = true;
    widget.state.rootAvailable = ok;
    widget.state.log(ok ? 'Root verified' : 'Root not found');
    if (mounted) setState(() => busy = false);
  }

  Future<void> loadRoot([String dir = '/']) async {
    setState(() {
      rootDirLoading = true;
      rootError = null;
    });
    rootDir = dir;
    try {
      final res = await NativeService.instance.rootExec('ls -la "$dir"');
      if (!res.ok) {
        setState(() => rootError = res.stderr.isEmpty ? 'root error' : res.stderr);
      } else {
        final lines = res.stdout
            .split('\n')
            .where((l) => l.trim().isNotEmpty)
            .toList();
        final entries = <RootEntry>[];
        for (final line in lines.skip(1)) {
          final parts = line.split(RegExp(r'\s+'));
          if (parts.length < 9) continue;
          final isDir = parts[0].startsWith('d');
          final name = parts.sublist(8).join(' ').trim();
          if (name == '.' || name == '..') continue;
          entries.add(RootEntry(name, '$dir/$name'.replaceAll('//', '/'), isDir));
        }
        setState(() => rootItems = entries);
      }
    } catch (e) {
      setState(() => rootError = '$e');
    } finally {
      if (mounted) setState(() => rootDirLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Root', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: Icon(s.rootAvailable ? Icons.verified_user : Icons.shield_outlined,
                color: s.rootAvailable ? Colors.green : null),
            title: Text(!s.rootChecked
                ? tr(s, 'Статус не проверен', 'Status not checked')
                : s.rootAvailable
                ? tr(s, 'Root подтверждён', 'Root verified')
                : tr(s, 'Root не обнаружен', 'Root not found')),
            subtitle: Text(tr(
              s,
              'Проверяется только безопасная команда su -c id.',
              'Only the safe su -c id command is checked.',
            )),
            trailing: busy
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : FilledButton(
                    onPressed: check,
                    child: Text(tr(s, 'Проверить', 'Check')),
                  ),
          ),
        ),
        const SizedBox(height: 14),
        if (s.rootAvailable) ...[
          Text(tr(s, 'Системная файловая система', 'System filesystem'),
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: IconButton(
                onPressed: rootDir != '/' ? () => loadRoot(_parent(rootDir)) : null,
                icon: const Icon(Icons.arrow_upward),
              ),
              title: Text(rootDir),
              subtitle: Text(tr(s, 'Через su (только чтение для навигации)',
                  'Via su (read-only for navigation)')),
            ),
          ),
          const SizedBox(height: 8),
          if (rootDirLoading)
            const Center(child: CircularProgressIndicator())
          else if (rootError != null)
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(rootError!),
              ),
            )
          else
            Card(
              child: Column(
                children: rootItems.isEmpty
                    ? [ListTile(title: Text(tr(s, 'Пусто', 'Empty')))]
                        : rootItems
                            .map((e) => ListTile(
                                  dense: true,
                                  leading: Icon(e.isDir ? Icons.folder : Icons.insert_drive_file_outlined,
                                      color: e.isDir ? Colors.amber : null),
                                  title: Text(e.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                                  onTap: e.isDir ? () => loadRoot(e.path) : () => _viewFile(e),
                                ))
                            .toList(),
              ),
            ),
        ] else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(tr(
                s,
                'Root-доступ не обнаружен. Системные файлы недоступны без root.',
                'Root access not found. System files are unavailable without root.',
              )),
            ),
          ),
      ],
    );
  }

  Future<void> _viewFile(RootEntry e) async {
    final s = widget.state;
    setState(() => rootDirLoading = true);
    String content;
    try {
      final res = await NativeService.instance.rootExec('head -c 65536 "${e.path}"');
      content = res.ok
          ? (res.stdout.isEmpty ? tr(s, '(пусто или бинарный файл)', '(empty or binary file)') : res.stdout)
          : res.stderr;
    } catch (err) {
      content = '$err';
    } finally {
      if (mounted) setState(() => rootDirLoading = false);
    }
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (x) => AlertDialog(
        title: Text(e.name),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: SelectableText(content, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(x), child: Text(tr(s, 'Закрыть', 'Close'))),
        ],
      ),
    );
  }

  String _parent(String dir) {
    final p = dir.replaceAll(RegExp(r'/$'), '');
    final i = p.lastIndexOf('/');
    return i <= 0 ? '/' : p.substring(0, i);
  }
}

class RootEntry {
  final String name, path;
  final bool isDir;
  RootEntry(this.name, this.path, this.isDir);
}
