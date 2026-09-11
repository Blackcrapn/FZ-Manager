import 'package:flutter/material.dart';
import '../app.dart';
import '../widgets.dart';
import '../native_service.dart';

/// Kernel section: quick access to kernel-level info via root.
class KernelPage extends StatefulWidget {
  const KernelPage({super.key, required this.state});
  final AppState state;
  @override
  State<KernelPage> createState() => _KernelPageState();
}

class _KernelPageState extends State<KernelPage> {
  bool loading = false;
  String? error;
  final output = StringBuffer();

  static const _quickCmds = <String, String>{
    'Kernel': 'uname -a',
    'CPU': 'cat /proc/cpuinfo | head -30',
    'Memory': 'head -20 /proc/meminfo',
    'Build': 'getprop ro.build.display.id; getprop ro.product.model',
    'dmesg': 'dmesg | tail -40',
    'Mounts': 'cat /proc/mounts | head -20',
    'Partitions': 'ls -la /dev/block/by-name 2>/dev/null || ls /proc/partitions',
    'Battery': 'dumpsys battery | head -15',
  };

  Future<void> _run(String name, String cmd) async {
    final s = widget.state;
    if (!s.rootAvailable) {
      _snack(tr(s, 'Сначала подтвердите Root в разделе Root', 'Verify Root in the Root section first'));
      return;
    }
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final res = await NativeService.instance.rootExec(cmd);
      setState(() {
        output.writeln('=== $name ===');
        output.writeln(res.ok ? res.stdout : res.stderr);
        output.writeln('');
      });
      s.log('kernel: $name');
    } catch (e) {
      setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _viewFile(String path) async {
    final s = widget.state;
    if (!s.rootAvailable) {
      _snack(tr(s, 'Сначала подтвердите Root', 'Verify Root first'));
      return;
    }
    final res = await NativeService.instance.rootExec('head -c 65536 "$path"');
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (x) => AlertDialog(
        title: Text(path, style: const TextStyle(fontSize: 14, fontFamily: 'monospace')),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: SelectableText(
              res.ok ? res.stdout : res.stderr,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
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
          title: tr(s, 'Ядро', 'Kernel'),
          subtitle: tr(s, 'Ядровая информация системы через root', 'Kernel-level system info via root'),
        ),
        const SizedBox(height: 14),
        if (!s.rootAvailable)
          GlassCard(
            child: Row(
              children: [
                const Icon(Icons.lock_outline_rounded, size: 36),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    tr(s,
                        'Kernel требует root. Проверьте Root в соседнем разделе — затем здесь появится быстрая ядровая информация.',
                        'Kernel needs root. Verify Root in the neighboring section — quick kernel info appears here.'),
                  ),
                ),
              ],
            ),
          )
        else ...[
          SectionHeader(title: tr(s, 'Быстрые команды', 'Quick commands')),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickCmds.entries
                .map((e) => ActionChip(
                      avatar: const Icon(Icons.terminal_rounded, size: 16),
                      label: Text(e.key),
                      onPressed: () => _run(e.key, e.value),
                    ))
                .toList(),
          ),
          const SizedBox(height: 14),
          SectionHeader(title: tr(s, 'Ядровые файлы', 'Kernel files')),
          const SizedBox(height: 10),
          GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _kf('/proc/version', 'version'),
                _kf('/proc/cmdline', 'cmdline'),
                _kf('/proc/cpuinfo', 'cpuinfo'),
                _kf('/proc/meminfo', 'meminfo'),
                _kf('/proc/uptime', 'uptime'),
                _kf('/proc/mounts', 'mounts'),
                _kf('/proc/partitions', 'partitions'),
                _kf('/sys/kernel/mm/transparent_hugepage/enabled', 'THP'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (loading) const Center(child: CircularProgressIndicator()),
          if (error != null)
            GlassCard(
              child: Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          if (output.isNotEmpty) ...[
            SectionHeader(title: tr(s, 'Вывод', 'Output')),
            const SizedBox(height: 10),
            GlassCard(
              child: SizedBox(
                width: double.infinity,
                child: SingleChildScrollView(
                  child: SelectableText(
                    output.toString(),
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => setState(() => output.clear()),
                  icon: const Icon(Icons.clear_all_rounded),
                  label: Text(tr(s, 'Очистить вывод', 'Clear output')),
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _kf(String path, String label) => ListTile(
        dense: true,
        leading: const Icon(Icons.description_outlined),
        title: Text(label, style: const TextStyle(fontFamily: 'monospace')),
        subtitle: Text(path, style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
        onTap: () => _viewFile(path),
      );

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
}
