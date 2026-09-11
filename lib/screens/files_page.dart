import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../app.dart';
import '../widgets.dart';
import '../path_service.dart';

class FileEntry {
  FileEntry(this.name, this.path, this.directory, this.size, this.modified);
  final String name, path;
  final bool directory;
  final int size;
  final DateTime modified;
}

class FilesPage extends StatefulWidget {
  const FilesPage({super.key, required this.state});
  final AppState state;
  @override
  State<FilesPage> createState() => _FilesPageState();
}

class _FilesPageState extends State<FilesPage> {
  final path = TextEditingController();
  String query = '';
  String sort = 'name';
  bool loading = true;
  String? error;
  List<FileEntry> items = [];
  Set<String> selected = {};
  List<PathCompletion> _completions = [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    path.text = widget.state.path;
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    path.dispose();
    super.dispose();
  }

  Future<void> _load([String? target]) async {
    setState(() {
      loading = true;
      error = null;
      selected.clear();
    });
    final raw = (target ?? path.text).trim();
    try {
      var dir = Directory(raw);
      if (!await dir.exists()) {
        final fixed = await PathService.fixLastSegment(raw);
        if (fixed != null) {
          dir = Directory(fixed);
          path.text = fixed;
          _snack('${tr(widget.state, 'Исправлен путь', 'Corrected path')}: $fixed');
        } else {
          throw FileSystemException(
            tr(widget.state, 'Каталог не существует', 'Directory does not exist'),
            raw,
          );
        }
      }
      final list = <FileEntry>[];
      await for (final e in dir.list(followLinks: false)) {
        try {
          final st = await e.stat();
          list.add(FileEntry(
            e.uri.pathSegments.where((x) => x.isNotEmpty).last,
            e.path,
            e is Directory,
            st.size,
            st.modified,
          ));
        } catch (_) {}
      }
      widget.state.path = dir.path;
      path.text = dir.path;
      widget.state.rememberRecent(dir.path);
      _sort(list);
      if (mounted) setState(() => items = list);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _onPathChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 180), () async {
      final c = await PathService.complete(v);
      if (mounted && c != null) setState(() => _completions = [c]);
    });
  }

  void _sort(List<FileEntry> v) {
    v.sort((a, b) {
      if (a.directory != b.directory) return a.directory ? -1 : 1;
      return switch (sort) {
        'date' => b.modified.compareTo(a.modified),
        'size' => b.size.compareTo(a.size),
        _ => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final shown = items
        .where((e) => e.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
    return Column(
      children: [
        _header(s),
        if (selected.isNotEmpty) _batch(s),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : error != null
              ? _error(s)
              : shown.isEmpty
              ? Center(child: Text(tr(s, 'Папка пуста', 'Folder is empty')))
              : s.grid ? _grid(shown) : _list(shown),
        ),
      ],
    );
  }

  Widget _header(AppState s) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
    child: Column(
      children: [
        Row(
          children: [
            Text(tr(s, 'Файлы', 'Files'),
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const Spacer(),
            IconButton(
              tooltip: tr(s, 'Избранное', 'Favorites'),
              onPressed: () =>
                  _pathsDialog(tr(s, 'Избранное', 'Favorites'), s.favorites.toList()),
              icon: const Icon(Icons.star_outline),
            ),
            IconButton(
              onPressed: () {
                s.grid = !s.grid;
                s.change();
              },
              icon: Icon(s.grid ? Icons.view_list : Icons.grid_view),
            ),
            PopupMenuButton<String>(
              onSelected: (v) {
                sort = v;
                _sort(items);
                setState(() {});
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'name', child: Text(tr(s, 'По имени', 'By name'))),
                PopupMenuItem(value: 'date', child: Text(tr(s, 'По дате', 'By date'))),
                PopupMenuItem(value: 'size', child: Text(tr(s, 'По размеру', 'By size'))),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: path,
          onChanged: _onPathChanged,
          onSubmitted: _load,
          decoration: InputDecoration(
            prefixIcon: IconButton(
              onPressed: () => _load(Directory(path.text).parent.path),
              icon: const Icon(Icons.arrow_upward),
            ),
            suffixIcon: IconButton(
              onPressed: () => _load(),
              icon: const Icon(Icons.arrow_forward),
            ),
            hintText: '/storage/emulated/0',
            border: const OutlineInputBorder(),
          ),
        ),
        if (_completions.isNotEmpty)
          _suggestions(s),
        const SizedBox(height: 8),
        TextField(
          onChanged: (v) => setState(() => query = v),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText: tr(s, 'Поиск в каталоге', 'Search in folder'),
            isDense: true,
          ),
        ),
      ],
    ),
  );

  Widget _suggestions(AppState s) {
    final c = _completions.first;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            if (c.typedSegment.isNotEmpty &&
                !c.suggestions.any((x) => x == c.typedSegment))
              ActionChip(
                avatar: const Icon(Icons.healing, size: 16),
                label: Text(
                  tr(s, 'Исправить', 'Fix') + ' → ${c.suggestions.isNotEmpty ? c.suggestions.first : c.typedSegment}',
                ),
                onPressed: () {
                  final next = c.suggestions.isNotEmpty
                      ? c.suggestions.first
                      : c.typedSegment;
                  path.text = '$c.existingPrefix/$next';
                  _load(path.text);
                  setState(() => _completions = []);
                },
              ),
            ...c.suggestions.take(6).map(
              (sugg) => ActionChip(
                label: Text(sugg),
                onPressed: () {
                  path.text = '$c.existingPrefix/$sugg';
                  _load(path.text);
                  setState(() => _completions = []);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _batch(AppState s) => Material(
    color: Theme.of(context).colorScheme.secondaryContainer,
    child: Row(
      children: [
        const SizedBox(width: 16),
        Text('${selected.length}'),
        const Spacer(),
        IconButton(
          tooltip: tr(s, 'В избранное', 'Favorite'),
          onPressed: () {
            s.favorites.addAll(selected);
            s.change();
            setState(() => selected.clear());
          },
          icon: const Icon(Icons.star),
        ),
        IconButton(
          tooltip: tr(s, 'Удалить безопасно', 'Safe delete'),
          onPressed: () => _confirmDelete(selected.toList()),
          icon: const Icon(Icons.delete_outline),
        ),
        IconButton(
          onPressed: () => setState(() => selected.clear()),
          icon: const Icon(Icons.close),
        ),
      ],
    ),
  );

  Widget _error(AppState s) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_outline, size: 56),
          const SizedBox(height: 12),
          Text(tr(s, 'Нет доступа или путь недоступен', 'No access or path unavailable'),
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(error!, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => _load('/storage/emulated/0'),
            icon: const Icon(Icons.home),
            label: Text(tr(s, 'Открыть хранилище', 'Open storage')),
          ),
        ],
      ),
    ),
  );

  Widget _list(List<FileEntry> v) =>
      ListView.builder(itemCount: v.length, itemBuilder: (_, i) => _tile(v[i]));

  Widget _grid(List<FileEntry> v) => GridView.builder(
    padding: const EdgeInsets.all(12),
    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: 170,
      childAspectRatio: 1.05,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
    ),
    itemCount: v.length,
    itemBuilder: (_, i) {
      final e = v[i];
      return InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _open(e),
        onLongPress: () => setState(() => selected.add(e.path)),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(e.directory ? Icons.folder_rounded : Icons.insert_drive_file_outlined,
                    size: 48, color: e.directory ? Colors.amber : null),
                const SizedBox(height: 8),
                Text(e.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      );
    },
  );

  Widget _tile(FileEntry e) => ListTile(
    selected: selected.contains(e.path),
    leading: Icon(e.directory ? Icons.folder_rounded : Icons.insert_drive_file_outlined,
        color: e.directory ? Colors.amber : null),
    title: Text(e.name, maxLines: 1, overflow: TextOverflow.ellipsis),
    subtitle: Text(e.directory ? tr(widget.state, 'Папка', 'Folder') : formatBytes(e.size)),
    onTap: () => selected.isEmpty
        ? _open(e)
        : setState(() => selected.contains(e.path)
            ? selected.remove(e.path)
            : selected.add(e.path)),
    onLongPress: () => setState(() => selected.add(e.path)),
    trailing: PopupMenuButton<String>(
      onSelected: (v) => _action(v, e),
      itemBuilder: (_) => [
        PopupMenuItem(value: 'favorite', child: Text(tr(widget.state, 'Избранное', 'Favorite'))),
        PopupMenuItem(value: 'bookmark', child: Text(tr(widget.state, 'Закладка пути', 'Path bookmark'))),
        PopupMenuItem(value: 'rename', child: Text(tr(widget.state, 'Переименовать', 'Rename'))),
        PopupMenuItem(value: 'delete', child: Text(tr(widget.state, 'В корзину', 'Move to trash'))),
      ],
    ),
  );

  void _open(FileEntry e) {
    if (e.directory) {
      _load(e.path);
    } else {
      widget.state.log('${tr(widget.state, 'Открыт файл', 'Opened file')}: ${e.path}');
      _snack(tr(widget.state, 'Предпросмотр этого типа пока недоступен', 'Preview for this type is not available yet'));
    }
  }

  void _action(String a, FileEntry e) {
    final s = widget.state;
    if (a == 'favorite') {
      s.favorites.add(e.path);
      s.log('${tr(s, 'В избранное', 'Favorited')}: ${e.name}');
    } else if (a == 'bookmark') {
      s.bookmarks.add(e.directory ? e.path : File(e.path).parent.path);
      s.change();
    } else if (a == 'delete') {
      _confirmDelete([e.path]);
    } else {
      _rename(e);
    }
  }

  Future<void> _rename(FileEntry e) async {
    final c = TextEditingController(text: e.name);
    final ok = await showDialog<bool>(
      context: context,
      builder: (x) => AlertDialog(
        title: Text(tr(widget.state, 'Переименовать', 'Rename')),
        content: TextField(controller: c, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(x, false),
              child: Text(tr(widget.state, 'Отмена', 'Cancel'))),
          FilledButton(onPressed: () => Navigator.pop(x, true), child: const Text('OK')),
        ],
      ),
    ) ?? false;
    if (!ok || c.text.trim().isEmpty) return;
    try {
      final np = '${File(e.path).parent.path}${Platform.pathSeparator}${c.text.trim()}';
      if (e.directory) {
        await Directory(e.path).rename(np);
      } else {
        await File(e.path).rename(np);
      }
      widget.state.log('${tr(widget.state, 'Переименовано', 'Renamed')}: ${e.name} → ${c.text.trim()}');
      _load();
    } catch (x) {
      _snack(x.toString());
    }
  }

  Future<void> _confirmDelete(List<String> paths) async {
    final s = widget.state;
    final ok = await showDialog<bool>(
      context: context,
      builder: (x) => AlertDialog(
        icon: const Icon(Icons.warning_amber),
        title: Text(tr(s, 'Переместить в корзину?', 'Move to trash?')),
        content: Text(tr(
          s,
          'Элементы будут перемещены в папку .fz_trash текущего хранилища. При ошибке ничего не удаляется.',
          'Items move to the .fz_trash folder. Nothing is deleted if moving fails.',
        )),
        actions: [
          TextButton(onPressed: () => Navigator.pop(x, false),
              child: Text(tr(s, 'Отмена', 'Cancel'))),
          FilledButton(onPressed: () => Navigator.pop(x, true),
              child: Text(tr(s, 'В корзину', 'Move'))),
        ],
      ),
    ) ?? false;
    if (!ok) return;
    int done = 0;
    for (final p in paths) {
      try {
        final trash = Directory(
          '${Directory(widget.state.path).path}${Platform.pathSeparator}.fz_trash',
        );
        await trash.create(recursive: true);
        final n = p.split(Platform.pathSeparator).last;
        final target = '${trash.path}${Platform.pathSeparator}${DateTime.now().millisecondsSinceEpoch}_$n';
        if (await FileSystemEntity.isDirectory(p)) {
          await Directory(p).rename(target);
        } else {
          await File(p).rename(target);
        }
        done++;
      } catch (x) {
        _snack(x.toString());
      }
    }
    s.log('${tr(s, 'В корзину перемещено', 'Moved to trash')}: $done');
    _load();
  }

  void _pathsDialog(String title, List<String> p) => showDialog(
    context: context,
    builder: (x) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 500,
        child: p.isEmpty
            ? Text(tr(widget.state, 'Пока пусто', 'Empty for now'))
            : ListView(shrinkWrap: true, children: p
                .map((v) => ListTile(
                    title: Text(v),
                    onTap: () {
                      Navigator.pop(x);
                      _load(v);
                    }))
                .toList()),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(x),
            child: Text(tr(widget.state, 'Закрыть', 'Close'))),
      ],
    ),
  );

  void _snack(String x) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(x)));
}
