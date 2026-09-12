import 'package:flutter/material.dart';
import '../app.dart';
import '../widgets.dart';
import '../assistant.dart';
import '../fizzy_online.dart';
import '../model_catalog.dart';
import '../model_service.dart';
import '../native_service.dart';
import '../permission_service.dart';

class AssistantPage extends StatefulWidget {
  const AssistantPage({super.key, required this.state});
  final AppState state;
  @override
  State<AssistantPage> createState() => _AssistantPageState();
}

class _AssistantPageState extends State<AssistantPage> {
  final input = TextEditingController();
  final _scroll = ScrollController();
  final List<_Bubble> msgs = [];
  late Fizzy fizzy;
  double? downloadProgress;
  String downloadingId = '';

  @override
  void dispose() {
    input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _ask([String? preset]) async {
    final s = widget.state;
    fizzy = Fizzy(russian: s.russian);
    final q = (preset ?? input.text).trim();
    if (q.isEmpty || s.fizzyBusy) return;
    input.clear();
    setState(() => msgs.add(_Bubble(q, true)));
    _scrollToEnd();

    final grounded = fizzy.ground(q);
    final fallback = fizzy.answer(q);

    final mode = s.fizzyMode;
    final useOnline = mode == 'online' && s.provider.isNotEmpty;
    final useLocal = mode == 'local';

    if (useOnline || useLocal) {
      s.fizzyBusy = true;
      setState(() {});
      try {
        final online = useLocal
            ? FizzyOnline(
                baseUrl: s.localServerUrl,
                model: s.localServerModel,
                isLocal: true)
            : FizzyOnline(
                baseUrl: s.provider,
                model: s.model.isEmpty ? 'gpt-4o-mini' : s.model,
                apiKey: await NativeService.instance.getApiKey() ?? '',
              );
        final answer = await online.ask(q, fizzy.context, grounded);
        if (answer.trim().isNotEmpty) {
          fizzy.rememberTurn(q, answer);
          s.fizzyBusy = false;
          setState(() => msgs.add(_Bubble(answer.trim(), false)));
          _scrollToEnd();
          return;
        }
        throw Exception('empty reply');
      } catch (e) {
        s.fizzyBusy = false;
        final hint = useLocal
            ? (s.russian
                ? 'Локальная модель недоступна ($e). Проверьте, что llama.cpp-сервер запущен и URL верный. Отвечаю из базы знаний:\n'
                : 'Local model unavailable ($e). Ensure the llama.cpp server runs and the URL is right. KB answer:\n')
            : (s.russian
                ? 'Онлайн Физзи недоступен ($e). Отвечаю из локальной базы:\n'
                : 'Online Fizzy unavailable ($e). Answering from the local base:\n');
        fizzy.rememberTurn(q, hint + fallback.text);
        setState(() => msgs.add(_Bubble(hint + fallback.text, false, guide: fallback.guide)));
        _scrollToEnd();
        return;
      } finally {
        s.fizzyBusy = false;
        if (mounted) setState(() {});
      }
    }

    fizzy.rememberTurn(q, fallback.text);
    setState(() => msgs.add(_Bubble(fallback.text, false, guide: fallback.guide)));
    _scrollToEnd();
  }

  LocalModel _selectedModel() {
    final s = widget.state;
    return kLocalModels.firstWhere(
      (m) => m.id == s.recommendedModelId,
      orElse: () => kLocalModels[1],
    );
  }

  Future<void> _downloadModel() async {
    final s = widget.state;
    final m = _selectedModel();
    final ms = ModelService(url: m.url, fileName: m.file);
    if (await ms.exists()) {
      _showModelDialog(m, await ms.size());
      return;
    }
    setState(() {
      downloadProgress = 0;
      downloadingId = m.id;
    });
    try {
      final size = await ms.download((p) {
        if (mounted) setState(() => downloadProgress = p);
      });
      if (mounted) {
        setState(() {
          downloadProgress = null;
          downloadingId = '';
        });
        s.downloadedModelFile = m.file;
        s.modelUrl = m.url;
        s.modelName = m.file;
        _showModelDialog(m, size);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          downloadProgress = null;
          downloadingId = '';
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(tr(s, 'Скачивание не удалось', 'Download failed') + ': $e')));
      }
    }
  }

  Future<void> _showModelDialog(LocalModel m, int size) async {
    final s = widget.state;
    final ms = ModelService(url: m.url, fileName: m.file);
    final path = await ms.localPath();
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (x) => AlertDialog(
        title: Text(tr(s, 'Модель готова', 'Model ready')),
        content: SingleChildScrollView(
          child: Text(tr(
            s,
            '${m.file}\n'
            'Размер: ${formatBytes(size)}\n'
            'Оценка памяти: ~${m.estRamMb} МБ RAM\n'
            'Путь: $path\n\n'
            'Как запустить локально без нагрузки на приложение:\n'
            '1) Установите llama.cpp-клиент (Termux: pkg install llama-cpp) '
            'или PocketPal / LlamaPlay из Play Store.\n'
            '2) Откройте в нём этот GGUF-файл.\n'
            '3) В настройках Физзи выберите режим «Локальная модель» и '
            'укажите URL сервера (по умолчанию http://127.0.0.1:8080/v1).\n\n'
            'Системный промпт для мини-моделей уже встроен и скрыт — '
            'Физзи настроит модель сам.',
            '${m.file}\n'
            'Size: ${formatBytes(size)}\n'
            'RAM estimate: ~${m.estRamMb} MB\n'
            'Path: $path\n\n'
            'Run locally without loading the app process:\n'
            '1) Install a llama.cpp client (Termux: pkg install llama-cpp) '
            'or PocketPal / LlamaPlay from Play.\n'
            '2) Open this GGUF in it.\n'
            '3) In Fizzy settings pick "Local model" and set the server URL '
            '(default http://127.0.0.1:8080/v1).\n\n'
            'The mini-model system prompt is built-in and hidden — Fizzy '
            'configures the model itself.')),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(x);
              await ms.delete();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(tr(s, 'Модель удалена', 'Model deleted'))));
              }
            },
            child: Text(tr(s, 'Удалить', 'Delete')),
          ),
          FilledButton(
              onPressed: () => Navigator.pop(x),
              child: Text(tr(s, 'ОК', 'OK'))),
        ],
      ),
    );
  }

  // ---------- Recommended local AI ----------

  Future<void> _openRecommendations() async {
    final s = widget.state;
    final dev = await NativeService.instance.deviceInfo();
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (x) => _RecommenderSheet(state: s, device: dev, onPicked: (m) {
        s.recommendedModelId = m.id;
        Navigator.pop(x);
        _downloadModel();
      }),
    );
  }

  // ---------- Settings ----------

  Future<void> _openSettings() async {
    final s = widget.state;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (x) => StatefulBuilder(
        builder: (x, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(x).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(tr(s, 'Настройки Физзи', 'Fizzy settings'),
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 10),
                _modeTile('kb', Icons.psychology_alt_rounded,
                    tr(s, 'База знаний (офлайн, 0 нагрузки)', 'Knowledge base (offline, zero load)'),
                    tr(s, 'Мгновенные ответы из встроенной базы FZ Manager', 'Instant answers from the built-in FZ Manager base')),
                _modeTile('online', Icons.cloud_rounded,
                    tr(s, 'Онлайн (через вашего провайдера)', 'Online (via your provider)'),
                    tr(s, 'ИИ-модель + контекст диалога + RAG по базе знаний', 'AI model + chat context + RAG over the knowledge base')),
                _modeTile('local', Icons.phone_android_rounded,
                    tr(s, 'Локальная мини-модель', 'Local mini model'),
                    tr(s, 'Через llama.cpp-сервер на телефоне (GGUF ниже)', 'Via a llama.cpp GGUF server on the phone')),
                if (s.fizzyMode == 'local') ...[
                  const SizedBox(height: 6),
                  TextField(
                    controller: TextEditingController(text: s.localServerUrl),
                    onSubmitted: (v) => setSheet(() => s.localServerUrl = v.trim()),
                    decoration: InputDecoration(
                      labelText: tr(s, 'URL локального сервера', 'Local server URL'),
                      hintText: 'http://127.0.0.1:8080/v1',
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: TextEditingController(text: s.localServerModel),
                    onSubmitted: (v) => setSheet(() => s.localServerModel = v.trim()),
                    decoration: InputDecoration(
                      labelText: tr(s, 'Имя модели на сервере', 'Model name on server'),
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ],
                const Divider(height: 26),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.music_note_rounded),
                  title: Text(tr(s, 'Музыкальный островок', 'Music island effect')),
                  subtitle: Text(tr(s, 'Живое уведомление «♪ играет музыку»', 'A live "♪ playing" notification')),
                  value: s.musicIsland,
                  onChanged: (v) async {
                    if (v) {
                      final granted = await PermissionService.requestNotifications();
                      if (!granted) {
                        setSheet(() => s.musicIsland = false);
                        return;
                      }
                      await NativeService.instance.startMusicEffect();
                    } else {
                      await NativeService.instance.stopMusicEffect();
                    }
                    setSheet(() => s.musicIsland = v);
                  },
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(x);
                    _openRecommendations();
                  },
                  icon: const Icon(Icons.auto_awesome_motion_rounded),
                  label: Text(tr(s, 'Рекомендованные локальные ИИ', 'Recommended local AI')),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(x);
                      _downloadModel();
                    },
                    icon: const Icon(Icons.download_rounded),
                    label: Text(tr(s, 'Скачать выбранную модель', 'Download selected model')),
                  ),
                ),
                Text(
                  '${_selectedModel().file} ≈ ${(_selectedModel().sizeMb / 1024).toStringAsFixed(1)} ГБ'
                      .replaceAll('.0 ГБ', ' ГБ'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _modeTile(String mode, IconData icon, String title, String sub) => RadioListTile<String>(
        contentPadding: EdgeInsets.zero,
        value: mode,
        groupValue: widget.state.fizzyMode,
        onChanged: (v) => setState(() => widget.state.fizzyMode = v!),
        title: Text(title),
        subtitle: Text(sub, style: const TextStyle(fontSize: 12)),
        secondary: Icon(icon),
      );

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    fizzy = Fizzy(russian: s.russian);
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
            child: Row(
              children: [
                const AssistantIcon(size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tr(s, 'Физзи', 'Fizzy'),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                      Text(s.fizzyBusy
                          ? tr(s, 'думает…', 'thinking…')
                          : switch (s.fizzyMode) {
                              'online' => tr(s, 'онлайн-мозг активен', 'online brain active'),
                              'local' => tr(s, 'локальная модель', 'local mini model'),
                              _ => tr(s, 'локальная база знаний', 'local knowledge base'),
                            },
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: tr(s, 'Настройки Физзи', 'Fizzy settings'),
                  onPressed: _openSettings,
                  icon: const Icon(Icons.tune_rounded),
                ),
                IconButton(
                  tooltip: tr(s, 'Очистить', 'Clear'),
                  onPressed: () => setState(() {
                    msgs.clear();
                    fizzy.history.clear();
                  }),
                  icon: const Icon(Icons.cleaning_services_outlined),
                ),
              ],
            ),
          ),
          _modeSwitch(s),
          if (downloadProgress != null)
            LinearProgressIndicator(value: downloadProgress == 0 ? null : downloadProgress),
          Expanded(child: msgs.isEmpty ? _welcome(s) : _chat()),
          _inputBar(s),
        ],
      ),
    );
  }

  /// Mode chips right inside the chat: KB / Online / Local.
  Widget _modeSwitch(AppState s) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 2),
        child: Row(
          children: [
            for (final m in ['kb', 'online', 'local'])
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  selected: s.fizzyMode == m,
                  onSelected: (_) => setState(() => s.fizzyMode = m),
                  avatar: Icon(switch (m) {
                    'online' => Icons.cloud_rounded,
                    'local' => Icons.phone_android_rounded,
                    _ => Icons.psychology_alt_rounded,
                  }, size: 16),
                  label: Text(switch (m) {
                    'online' => tr(s, 'Онлайн', 'Online'),
                    'local' => tr(s, 'Локал', 'Local'),
                    _ => tr(s, 'База', 'KB'),
                  }),
                ),
              ),
            const Spacer(),
          ],
        ),
      );

  Widget _chat() => ListView.builder(
    controller: _scroll,
    padding: const EdgeInsets.all(16),
    itemCount: msgs.length,
    itemBuilder: (_, i) {
      final m = msgs[i];
      return Align(
        alignment: m.fromUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(12),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
          decoration: BoxDecoration(
            color: m.fromUser
                ? Theme.of(context).colorScheme.primaryContainer
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(m.fromUser ? 18 : 4),
              bottomRight: Radius.circular(m.fromUser ? 4 : 18),
            ),
          ),
          child: m.guide.isEmpty ? SelectableText(m.text) : _guideBubble(context, m),
        ),
      );
    },
  );

  Widget _guideBubble(BuildContext context, _Bubble m) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SelectableText(m.text),
      if (m.guide.isNotEmpty) ...[
        const SizedBox(height: 10),
        Text(tr(widget.state, 'Как сделать:', 'How to:'),
            style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        ...List.generate(m.guide.length, (i) => Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  child: Text('${i + 1}',
                      style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(m.guide[i])),
              ]),
            )),
      ],
    ],
  );

  Widget _welcome(AppState s) {
    final cats = <String, List<FizzyEntry>>{};
    for (final t in fizzy.topics) {
      cats.putIfAbsent(t.category, () => []).add(t);
    }
    final catLabels = {
      'files': tr(s, 'Файлы', 'Files'),
      'root': 'Root',
      'ai': tr(s, 'ИИ Мозг', 'AI Brain'),
      'storage': tr(s, 'Хранилище', 'Storage'),
      'settings': tr(s, 'Настройки', 'Settings'),
      'app': tr(s, 'Приложение', 'App'),
    };
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 8),
        const Center(child: AssistantIcon(size: 104)),
        const SizedBox(height: 16),
        Text(fizzy.greeting,
            textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 20),
        ...cats.entries.map((cat) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(catLabels[cat.key] ?? cat.key,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.primary)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: cat.value
                      .map((t) => ActionChip(
                            label: Text(s.russian ? t.ruTitle : t.enTitle),
                            onPressed: () => _ask(s.russian ? t.ruTitle : t.enTitle),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 16),
              ],
            )),
      ],
    );
  }

  Widget _inputBar(AppState s) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
    child: GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      radius: 26,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: input,
              onSubmitted: (_) => _ask(),
              decoration: InputDecoration(
                hintText: tr(s, 'Спроси Физзи…', 'Ask Fizzy…'),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
          IconButton.filled(
            onPressed: s.fizzyBusy ? null : () => _ask(),
            icon: s.fizzyBusy
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.send_rounded),
          ),
        ],
      ),
    ),
  );
}

/// The "Recommended local AI" sheet: analyzes RAM/CPU/device, ranks
/// verified GGUF models online, never loads anything into memory.
class _RecommenderSheet extends StatefulWidget {
  const _RecommenderSheet({
    required this.state,
    required this.device,
    required this.onPicked,
  });
  final AppState state;
  final DeviceInfo? device;
  final ValueChanged<LocalModel> onPicked;
  @override
  State<_RecommenderSheet> createState() => _RecommenderSheetState();
}

class _RecommenderSheetState extends State<_RecommenderSheet> {
  List<ModelRecommendation>? recs;
  bool analyzing = true;

  @override
  void initState() {
    super.initState();
    _analyze();
  }

  Future<void> _analyze() async {
    final dev = widget.device ?? DeviceInfo({});
    final r = await ModelRecommender.recommend(dev);
    if (mounted) setState(() {
      recs = r;
      analyzing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final dev = widget.device;
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.4,
      expand: false,
      builder: (_, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        children: [
          Text(tr(s, 'Рекомендованные локальные ИИ', 'Recommended local AI'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          if (dev != null)
            Text(
              '${dev.fullName} · ${dev.ramTotalGb.toStringAsFixed(1)} ГБ RAM · '
              '${dev.cores} ядер${dev.maxFreqKHz > 0 ? ' · ${(dev.maxFreqKHz / 1000000).toStringAsFixed(1)} ГГц' : ''} · Android ${dev.release}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          const SizedBox(height: 4),
          Text(
            tr(s,
                'Проверка: живой URL файла на HuggingFace + точное соответствие RAM/CPU/модели. Инференс на телефоне НЕ запускается — никакого лишнего loads.',
                'Checks: live HuggingFace URL + exact RAM/CPU/device fit. Inference is NOT run on the phone — zero extra load.'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          if (analyzing)
            const Padding(
              padding: EdgeInsets.all(30),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            ...List.generate(recs!.length, (i) {
              final r = recs![i];
              final m = r.model;
              final best = i == 0;
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  leading: CircleAvatar(
                    backgroundColor: best
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: best
                        ? const Icon(Icons.emoji_events_rounded, color: Colors.white)
                        : Text('${i + 1}', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                  ),
                  title: Text('${m.id}${best ? '  ⭐ ${tr(s, "лучший выбор", "top pick")}' : ''}',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${(m.sizeMb / 1024).toStringAsFixed(1)} ГБ · ~${m.estRamMb} МБ RAM · '
                        '${(m.quality * 100).round()}% качества · '
                        '${r.verified ? (s.russian ? "URL проверен ✓" : "URL verified ✓") : (s.russian ? "URL недоступен ✗" : "URL unreachable ✗")}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      Text(s.russian ? m.noteRu : m.noteEn, style: const TextStyle(fontSize: 11)),
                      if ((s.russian ? r.reasonRu : r.reasonEn).isNotEmpty)
                        Text(s.russian ? r.reasonRu : r.reasonEn,
                            style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic)),
                    ],
                  ),
                  isThreeLine: true,
                  onTap: r.verified ? () => widget.onPicked(m) : null,
                  trailing: r.verified
                      ? FilledButton.tonal(
                          onPressed: () => widget.onPicked(m),
                          child: Text(tr(s, 'Выбрать', 'Pick')),
                        )
                      : const Icon(Icons.cloud_off_rounded, size: 18),
                ),
              );
            }),
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              onPressed: () => setState(() {
                analyzing = true;
                _analyze();
              }),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(tr(s, 'Перепроверить заново', 'Re-check')),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble {
  final String text;
  final bool fromUser;
  final List<String> guide;
  _Bubble(this.text, this.fromUser, {this.guide = const []});
}
