import 'dart:async';
import 'package:flutter/material.dart';
import '../app.dart';
import '../widgets.dart';
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
  RootProbe? probe;

  Future<void> check() async {
    setState(() => busy = true);
    final p = await NativeService.instance.rootProbe();
    final ok = p?.rootGranted ?? false;
    setState(() {
      probe = p;
      busy = false;
    });
    widget.state.rootChecked = true;
    widget.state.rootAvailable = ok;
    widget.state.log(ok
        ? 'Root: ${p!.manager} (uid=0)'
        : 'Root not confirmed (${p?.manager ?? 'no probe'})');
    if (ok && rootItems.isEmpty) await loadRoot('/');
  }

  IconData _managerIcon() {
    switch (probe?.iconKind() ?? 'none') {
      case 'ok':
        return Icons.verified_user_rounded;
      case 'magisk':
        return Icons.verified_user_rounded;
      case 'ksu':
        return Icons.terminal_rounded;
      case 'apatch':
        return Icons.build_circle_rounded;
      case 'supersu':
        return Icons.bolt_rounded;
      case 'su_partial':
        return Icons.help_outline_rounded;
      default:
        return Icons.shield_outlined;
    }
  }

  Widget _probeDetails(RootProbe p, AppState s) {
    final rows = <String, String>{};
    if (p.rootGranted) {
      rows[tr(s, 'Менеджер', 'Manager')] = p.manager +
          (p.magiskVersion.isNotEmpty && p.hasMagisk ? ' ${p.magiskVersion}' : '');
      if (p.canWrite) rows[tr(s, 'Запись', 'Write')] = tr(s, 'доступна', 'writable');
      if (p.canRemount) rows[tr(s, 'Remount /', 'Remount /')] = 'rw';
    } else if (p.suBinaries.isNotEmpty) {
      rows[tr(s, 'Найдены su', 'su found')] = p.suBinaries.take(2).join(', ');
    }
    if (p.managerApps.isNotEmpty) {
      rows[tr(s, 'Приложения', 'Apps')] = p.managerApps.join(', ');
    }
    if (p.kernel.isNotEmpty) rows[tr(s, 'Ядро', 'Kernel')] = p.kernel;
    if (p.selinux.isNotEmpty) rows['SELinux'] = p.selinux;
    if (rows.isEmpty) return const SizedBox.shrink();
    return Column(
      children: rows.entries
          .map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(e.key,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    Flexible(
                      child: Text(
                        e.value,
                        textAlign: TextAlign.end,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
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
        final lines = res.stdout.split('\n').where((l) => l.trim().isNotEmpty).toList();
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

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SectionHeader(
          title: 'Root',
          subtitle: tr(s, 'Системные разделы с правами суперпользователя', 'System partitions with superuser rights'),
        ),
        const SizedBox(height: 14),
        GlassCard(
          child: Column(
            children: [
              Icon(
                _managerIcon(),
                size: 64,
                color: probe != null && probe!.rootGranted ? Colors.green : null,
              ),
              const SizedBox(height: 8),
              Text(
                probe == null
                    ? tr(s, 'Нажмите «Проверить Root» для глубокого анализа',
                        'Tap "Check Root" for a deep analysis')
                    : probe!.verdict(s.russian),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                tr(
                  s,
                  'Проверка: su-бинарники, uid=0, Magisk/KernelSU/APatch/SuperSU, SELinux, версия ядра, тест записи. Команды su не меняют систему.',
                  'Probe checks: su binaries, uid=0, Magisk/KernelSU/APatch/SuperSU, SELinux, kernel version, write test. su commands do not modify the system.',
                ),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              if (probe != null) _probeDetails(probe!, s),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: busy ? null : check,
                icon: busy
                    ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.security_rounded),
                label: Text(tr(s, 'Проверить Root', 'Check Root')),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (s.rootAvailable) ...[
          SectionHeader(title: tr(s, 'Системная файловая система', 'System filesystem')),
          const SizedBox(height: 10),
          GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: IconButton(
                    onPressed: rootDir != '/' ? () => loadRoot(_parent(rootDir)) : null,
                    icon: const Icon(Icons.arrow_upward),
                  ),
                  title: Text(rootDir, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w600)),
                  subtitle: Text(tr(s, 'Через su (навигация и чтение)', 'Via su (navigation and reading)')),
                  trailing: IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    onPressed: () => loadRoot(rootDir),
                  ),
                ),
                const Divider(height: 1),
                if (rootDirLoading)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (rootError != null)
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(rootError!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  )
                else if (rootItems.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Text(tr(s, 'Пусто или нет доступа', 'Empty or no access')),
                  )
                else
                  ...rootItems.map((e) => ListTile(
                        dense: true,
                        leading: Icon(e.isDir ? Icons.folder_rounded : Icons.insert_drive_file_outlined,
                            color: e.isDir ? Colors.amber : null),
                        title: Text(e.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                        onTap: e.isDir ? () => loadRoot(e.path) : () => _viewFile(e),
                      )),
              ],
            ),
          ),
        ] else
          GlassCard(
            child: Text(
              tr(s,
                  'Root-доступ не обнаружен. Системные файлы недоступны без root — '
                  'это нормально: всё остальное работает.',
                  'Root access not found. System files are unavailable without '
                  'root — that is fine: everything else works.'),
            ),
          ),
      ],
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
