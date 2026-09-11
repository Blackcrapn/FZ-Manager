import 'package:flutter/material.dart';
import '../app.dart';
import '../widgets.dart';
import '../assistant.dart';
import '../fizzy_online.dart';
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
    if (q.isEmpty) return;
    input.clear();
    setState(() => msgs.add(_Bubble(q, true)));
    _scrollToEnd();

    final grounded = fizzy.ground(q);
    final fallback = fizzy.answer(q);

    if (s.fizzyOnline && s.provider.isNotEmpty) {
      try {
        final apiKey = await NativeService.instance.getApiKey() ?? '';
        final online = FizzyOnline(
          baseUrl: s.provider,
          model: s.model.isEmpty ? 'gpt-4o-mini' : s.model,
          apiKey: apiKey,
          systemPrompt: s.fizzyPrompt,
        );
        final answer = await online.ask(q, fizzy.context, grounded);
        if (answer.trim().isNotEmpty) {
          fizzy.rememberTurn(q, answer);
          setState(() => msgs.add(_Bubble(answer.trim(), false)));
          _scrollToEnd();
          return;
        }
      } catch (e) {
        final hint = '$e'.contains('401')
            ? (s.russian
                ? 'Онлайн Физзи: ошибка 401 — сохраните валидный API-ключ в ИИ Мозге. Отвечаю из локальной базы:\n'
                : 'Online Fizzy: 401 error — save a valid API key in AI Brain. Answering from the local base:\n')
            : (s.russian
                ? 'Онлайн недоступен ($e). Локальный ответ:\n'
                : 'Online unavailable ($e). Local answer:\n');
        fizzy.rememberTurn(q, hint + fallback.text);
        setState(() => msgs.add(_Bubble(hint + fallback.text, false, guide: fallback.guide)));
        _scrollToEnd();
        return;
      }
    }

    fizzy.rememberTurn(q, fallback.text);
    setState(() => msgs.add(_Bubble(fallback.text, false, guide: fallback.guide)));
    _scrollToEnd();
  }

  Future<void> _downloadModel() async {
    final s = widget.state;
    final ms = ModelService(url: s.modelUrl);
    final exists = await ms.exists();
    if (exists) {
      final size = await ms.size();
      _showModelDialog(formatBytes(size), ms);
      return;
    }
    setState(() => downloadProgress = 0);
    try {
      final size = await ms.download((p) {
        if (mounted) setState(() => downloadProgress = p);
      });
      if (mounted) {
        setState(() => downloadProgress = null);
        _showModelDialog(formatBytes(size), ms);
      }
    } catch (e) {
      if (mounted) {
        setState(() => downloadProgress = null);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(tr(s, 'Скачивание не удалось', 'Download failed') + ': $e')));
      }
    }
  }

  Future<void> _showModelDialog(String sizeLabel, ModelService ms) async {
    final s = widget.state;
    final path = await ms.localPath();
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (x) => AlertDialog(
        title: Text(tr(s, 'Модель готова', 'Model ready')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr(
              s,
              'Легчайшая практичная модель SmolLM2-135M (GGUF Q4_K_M) '
                  'скачана и почти не грузит телефон.\n\nРазмер: $sizeLabel\n'
                  'Путь: $path\n\n'
                  'Системный промпт Физзи уже настроен. Для автономного '
                  'инференса откройте этот файл в llama.cpp-клиенте '
                  '(Termux / LlamaPlay) или используйте онлайн-режим Физзи '
                  'через вашего провайдера.',
              'The lightest practical model SmolLM2-135M (GGUF Q4_K_M) is '
                  'downloaded and barely loads the phone.\n\nSize: '
                  '$sizeLabel\nPath: $path\n\nFizzy system prompt is ready. '
                  'For standalone inference open this file in a llama.cpp '
                  'client (Termux / LlamaPlay) or use Fizzy online mode via '
                  'your provider.')),
          ],
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
            child: Text(tr(s, 'Удалить модель', 'Delete model')),
          ),
          FilledButton(
              onPressed: () => Navigator.pop(x),
              child: Text(tr(s, 'ОК', 'OK'))),
        ],
      ),
    );
  }

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
                const SizedBox(height: 14),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.wifi_tethering_rounded),
                  title: Text(tr(s, 'Онлайн Физзи (через ИИ-провайдера)', 'Online Fizzy (via AI provider)')),
                  subtitle: Text(tr(s, 'Модель + контекст диалога + база знаний. Оффлайн — локальные ответы.',
                      'Model + chat context + knowledge base. Offline uses local answers.')),
                  value: s.fizzyOnline,
                  onChanged: (v) {
                    setSheet(() => s.fizzyOnline = v);
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.music_note_rounded),
                  title: Text(tr(s, 'Музыкальный островок', 'Music island effect')),
                  subtitle: Text(tr(s, 'Живое уведомление «♪ играет музыку», когда включены уведомления.',
                      'A live "♪ playing" notification while notifications are allowed.')),
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
                    s.log(v
                        ? 'Музыкальный островок включён'
                        : 'Музыкальный островок выключен');
                  },
                ),
                const Divider(height: 24),
                Text(tr(s, 'Системный промпт Физзи', 'Fizzy system prompt'),
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                PromptEditor(state: s),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(x);
                      _downloadModel();
                    },
                    icon: const Icon(Icons.download_rounded),
                    label: Text(tr(s, 'Скачать мини-модель', 'Download mini model')),
                  ),
                ),
                Text(tr(s, 'SmolLM2-135M GGUF ≈ 130 МБ — самая лёгкая практичная ИИ-модель для телефонов.',
                    'SmolLM2-135M GGUF ≈ 130 MB — the lightest practical AI model for phones.'),
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    fizzy = Fizzy(russian: s.russian);
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
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
                      Text(
                        s.fizzyOnline
                            ? tr(s, 'онлайн · знает всё о FZ Manager', 'online · knows all about FZ Manager')
                            : tr(s, 'локальный · знает всё о FZ Manager', 'local · knows all about FZ Manager'),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: s.fizzyOnline ? Colors.teal : null),
                      ),
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
          if (downloadProgress != null)
            LinearProgressIndicator(value: downloadProgress == 0 ? null : downloadProgress),
          Expanded(
            child: msgs.isEmpty ? _welcome(s) : _chat(),
          ),
          _inputBar(s),
        ],
      ),
    );
  }

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
          child: m.guide.isEmpty
              ? SelectableText(m.text)
              : _guideBubble(context, m),
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
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge),
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
            onPressed: () => _ask(),
            icon: const Icon(Icons.send_rounded),
          ),
        ],
      ),
    ),
  );
}

class PromptEditor extends StatefulWidget {
  const PromptEditor({super.key, required this.state});
  final AppState state;
  @override
  State<PromptEditor> createState() => _PromptEditorState();
}

class _PromptEditorState extends State<PromptEditor> {
  late final TextEditingController c;

  @override
  void initState() {
    super.initState();
    c = TextEditingController(text: widget.state.fizzyPrompt);
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
        controller: c,
        minLines: 4,
        maxLines: 8,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          isDense: true,
          suffixIcon: IconButton(
            tooltip: 'save',
            icon: const Icon(Icons.check),
            onPressed: () => widget.state.fizzyPrompt = c.text,
          ),
        ),
      );
}

class _Bubble {
  final String text;
  final bool fromUser;
  final List<String> guide;
  _Bubble(this.text, this.fromUser, {this.guide = const []});
}
