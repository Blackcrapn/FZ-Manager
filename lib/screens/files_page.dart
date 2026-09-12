import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../app.dart';
import '../widgets.dart';
import '../path_service.dart';
import '../native_service.dart';
import 'media_viewer.dart';
import 'root_page.dart';

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

  static const _imageExt = {'.png', '.jpg', '.jpeg', '.webp', '.gif', '.bmp'};
  static const _textExt = {
    '.txt', '.md', '.json', '.xml', '.yaml', '.yml', '.log', '.csv',
    '.sh', '.properties', '.conf', '.ini', '.py', '.js', '.ts', '.html', '.css',
  };

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
    final visible = s.showHidden
        ? items
        : items.where((e) => !e.name.startsWith('.')).toList();
    final shown = visible
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
              ? EmptyState(
                  title: tr(s, 'Папка пуста', 'Folder is empty'),
                  subtitle: tr(s, 'Измените путь или поиск', 'Change path or search'),
                )
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
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const Spacer(),
            IconButton(
              tooltip: tr(s, 'Корневой раздел', 'Root filesystem'),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => Scaffold(
                        appBar: AppBar(title: Text(tr(s, 'Корневой раздел', 'Root filesystem'))),
                        body: RootPage(state: s),
                      ))),
              icon: const Icon(Icons.admin_panel_settings_rounded),
            ),
            IconButton(
              tooltip: tr(s, 'Избранное', 'Favorites'),
              onPressed: () =>
                  _pathsDialog(tr(s, 'Избранное', 'Favorites'), s.favorites.toList()),
              icon: const Icon(Icons.star_outline)),
            IconButton(
              onPressed: () => s.grid = !s.grid,
              icon: Icon(s.grid ? Icons.view_list : Icons.grid_view)),
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
              icon: const Icon(Icons.arrow_upward)),
            suffixIcon: IconButton(
              onPressed: () => _load(),
              icon: const Icon(Icons.arrow_forward)),
            hintText: '/storage/emulated/0',
            border: const OutlineInputBorder(),
          ),
        ),
        if (_completions.isNotEmpty) _suggestions(s),
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
                  '${tr(s, 'Исправить', 'Fix')} → ${c.suggestions.isNotEmpty ? c.suggestions.first : c.typedSegment}',
                ),
                onPressed: () {
                  final next = c.suggestions.isNotEmpty ? c.suggestions.first : c.typedSegment;
                  path.text = '$c.existingPrefix/$next';
                  _load(path.text);
                  setState(() => _completions = []);
                }),
            ...c.suggestions.take(6).map(
              (sugg) => ActionChip(
                label: Text(sugg),
                onPressed: () {
                  path.text = '$c.existingPrefix/$sugg';
                  _load(path.text);
                  setState(() => _completions = []);
                }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _batch(AppState s) => Material(
    color: Theme.of(context).colorScheme.primaryContainer,
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
          icon: const Icon(Icons.star)),
        IconButton(
          tooltip: tr(s, 'Удалить безопасно', 'Safe delete'),
          onPressed: () => _confirmDelete(selected.toList()),
          icon: const Icon(Icons.delete_outline)),
        IconButton(
          onPressed: () => setState(() => selected.clear()),
          icon: const Icon(Icons.close)),
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
            label: Text(tr(s, 'Открыть хранилище', 'Open storage'))),
        ],
      ),
    ),
  );

  Widget _list(List<FileEntry> v) => ListView.builder(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    itemCount: v.length,
    itemBuilder: (_, i) => _tile(v[i]));

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
        child: GlassCard(
          padding: const EdgeInsets.all(12),
          radius: 16,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _fileIcon(e, 48),
              const SizedBox(height: 8),
              Text(e.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    },
  );

  Widget _fileIcon(FileEntry e, double size) {
    if (e.directory) return Icon(Icons.folder_rounded, size: size, color: Colors.amber);
    final ext = e.name.substring(e.name.lastIndexOf('.')).toLowerCase();
    if (_imageExt.contains(ext)) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(File(e.path), width: size, height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                Icon(Icons.image_outlined, size: size)));
    }
    if (ext == '.sh') return Icon(Icons.terminal_rounded, size: size,
        color: const Color(0xff37d6c0));
    if (kAudioExt.contains(ext)) return Icon(Icons.music_note_rounded,
        size: size, color: const Color(0xffec407a));
    if (kVideoExt.contains(ext)) return Icon(Icons.movie_rounded,
        size: size, color: const Color(0xff7c4dff));
    if (ext == '.apk') return Icon(Icons.android_rounded, size: size,
        color: const Color(0xff4caf50));
    if (ext == '.zip' || ext == '.rar' || ext == '.7z') {
      return Icon(Icons.folder_zip_outlined, size: size,
          color: const Color(0xffab47bc));
    }
    return Icon(Icons.insert_drive_file_outlined, size: size);
  }

  Widget _tile(FileEntry e) {
    final s = widget.state;
    return ListTile(
      selected: selected.contains(e.path),
      leading: _fileIcon(e, 40),
      title: Text(e.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(e.directory
          ? tr(s, 'Папка', 'Folder')
          : '${formatBytes(e.size)} · ${e.modified.toLocal().toString().substring(0, 16)}'),
      onTap: () => selected.isEmpty
          ? _open(e)
          : setState(() => selected.contains(e.path)
              ? selected.remove(e.path)
              : selected.add(e.path)),
      onLongPress: () => setState(() => selected.add(e.path)),
      trailing: PopupMenuButton<String>(
        onSelected: (v) => _action(v, e),
        itemBuilder: (_) => [
          PopupMenuItem(value: 'favorite',
              child: Text(tr(s, 'Избранное', 'Favorite'))),
          PopupMenuItem(value: 'bookmark',
              child: Text(tr(s, 'Закладка пути', 'Path bookmark'))),
          PopupMenuItem(value: 'rename',
              child: Text(tr(s, 'Переименовать', 'Rename'))),
          PopupMenuItem(value: 'delete',
              child: Text(tr(s, 'В корзину', 'Move to trash'))),
          if (!e.directory && _textExt.contains(_ext(e.name)))
            PopupMenuItem(value: 'openroot',
                child: Text(tr(s, 'Открыть как Root', 'Open as Root'))),
          if (!e.directory && _ext(e.name) == '.sh' && s.rootAvailable)
            PopupMenuItem(value: 'runroot',
                child: Text(tr(s, 'Запустить через Root', 'Run via Root'))),
        ],
      ),
    );
  }

  String _ext(String name) =>
      name.contains('.') ? name.substring(name.lastIndexOf('.')).toLowerCase() : '';

  // ---------- OPENING FILES ----------

  Future<void> _open(FileEntry e) async {
    final s = widget.state;
    if (e.directory) {
      _load(e.path);
      return;
    }
    final ext = _ext(e.name);
    if (_imageExt.contains(ext)) {
      _viewImage(e);
    } else if (kMediaExt.contains(ext)) {
      s.log('${tr(s, 'Плеер', 'Player')}: ${e.path}');
      Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => MediaViewerPage(state: s, path: e.path)));
    } else if (_textExt.contains(ext)) {
      _viewText(e, asRoot: false);
    } else if (ext == '.apk') {
      _snack(tr(s, 'APK: устанавливайте через системный установщик', 'APK: install via the system installer'));
    } else {
      s.log('${tr(s, 'Открыт файл', 'Opened file')}: ${e.path}');
      _snack(tr(s, 'Предпросмотр этого типа пока недоступен', 'Preview for this type is not available yet'));
    }
  }

  void _viewImage(FileEntry e) {
    showDialog(
      context: context,
      builder: (x) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InteractiveViewer(
              maxScale: 5,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(File(e.path), fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(x),
                  child: Text(tr(widget.state, 'Закрыть', 'Close'),
                      style: const TextStyle(color: Colors.white))),
              ],
            ),
          ],
        ),
      ),
      barrierColor: Colors.black87,
    );
  }

  Future<void> _viewText(FileEntry e, {required bool asRoot}) async {
    final s = widget.state;
    String content;
    if (asRoot) {
      if (!s.rootAvailable) {
        _snack(tr(s, 'Root недоступен — проверьте в разделе Root', 'Root unavailable — check the Root section'));
        return;
      }
      final res = await NativeService.instance.readRootFile(e.path);
      content = res.ok ? res.stdout : res.stderr;
      s.log('root read: ${e.path}');
    } else {
      try {
        final f = File(e.path);
        if (await f.length() > 512 * 1024) {
          final raf = await f.open();
          final bytes = await raf.read(512 * 1024);
          await raf.close();
          content = String.fromCharCodes(bytes);
        } else {
          content = await f.readAsString();
        }
      } catch (err) {
        if (mounted) {
          _snack(tr(s, 'Нет доступа. Попробуйте «Открыть как Root»', 'No access. Try "Open as Root"'));
        }
        return;
      }
    }
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (x) => AlertDialog(
        title: Row(
          children: [
            Expanded(child: Text(e.name, overflow: TextOverflow.ellipsis)),
            if (asRoot) ...[
              const SizedBox(width: 8),
              const Icon(Icons.admin_panel_settings, size: 18, color: Colors.orange),
            ],
          ],
        ),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: SelectableText(content,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
          ),
        ),
        actions: [
          if (!asRoot && s.rootAvailable)
            TextButton(
              onPressed: () {
                Navigator.pop(x);
                _viewText(e, asRoot: true);
              },
              child: Text(tr(s, 'Открыть как Root', 'Open as Root'))),
          TextButton(
            onPressed: () => Navigator.pop(x),
            child: Text(tr(s, 'Закрыть', 'Close'))),
        ],
      ),
    );
  }

  Future<void> _runScriptAsRoot(FileEntry e) async {
    final s = widget.state;
    if (!s.rootAvailable) {
      _snack(tr(s, 'Root недоступен', 'Root unavailable'));
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (x) => AlertDialog(
        icon: const Icon(Icons.terminal_rounded, size: 40, color: Colors.orange),
        title: Text(tr(s, 'Запустить скрипт через Root?', 'Run script via Root?')),
        content: Text(tr(
          s,
          'Скрипт будет выполнен с правами суперпользователя:\n${e.path}\n\n'
              'Убедитесь, что вы понимаете, что делает этот скрипт. '
              'Вывод появится на экране и попадёт в журнал аудита.',
          'The script will run with superuser rights:\n${e.path}\n\n'
              'Make sure you understand what it does. Output appears on '
              'screen and lands in the audit log.')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(x, false),
              child: Text(tr(s, 'Отмена', 'Cancel'))),
          FilledButton.icon(
            icon: const Icon(Icons.play_arrow),
            onPressed: () => Navigator.pop(x, true),
            label: Text(tr(s, 'Запустить', 'Run'))),
        ],
      ),
    ) ?? false;
    if (!ok) return;
    final res = await NativeService.instance.runRootScript(e.path);
    s.log('root script: ${e.name} (ok=${res.ok})');
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (x) => AlertDialog(
        title: Text(e.name),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: SelectableText(
              '--- stdout ---\n${res.stdout}\n--- stderr ---\n${res.stderr}',
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(x),
              child: Text(tr(s, 'Закрыть', 'Close'))),
        ],
      ),
    );
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
    } else if (a == 'openroot') {
      _viewText(e, asRoot: true);
    } else if (a == 'runroot') {
      _runScriptAsRoot(e);
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
          FilledButton(onPressed: () => Navigator.pop(x, true),
              child: const Text('OK')),
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
          'Элементы будут перемещены в папку .fz_trash. При ошибке ничего не удаляется.',
          'Items move to the .fz_trash folder. Nothing is deleted if moving fails.')),
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
          '${Directory(widget.state.path).path}${Platform.pathSeparator}.fz_trash');
        await trash.create(recursive: true);
        final n = p.split(Platform.pathSeparator).last;
        final target =
            '${trash.path}${Platform.pathSeparator}${DateTime.now().millisecondsSinceEpoch}_$n';
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
