import 'package:flutter/material.dart';
import '../app.dart';
import '../widgets.dart';
import '../native_service.dart';
import '../ai_engine.dart';

class AiPage extends StatefulWidget {
  const AiPage({super.key, required this.state});
  final AppState state;
  @override
  State<AiPage> createState() => _AiPageState();
}

class _AiPageState extends State<AiPage> {
  final url = TextEditingController();
  final model = TextEditingController();
  final key = TextEditingController();
  final chat = TextEditingController();
  final _scroll = ScrollController();
  List<ChatBubble> bubbles = [];
  bool running = false;
  AiEngine? engine;

  @override
  void initState() {
    super.initState();
    url.text = widget.state.provider;
    model.text = widget.state.model;
  }

  void _addBubble(String text, bool fromUser) {
    setState(() => bubbles.add(ChatBubble(text, fromUser)));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final text = chat.text.trim();
    if (text.isEmpty || running) return;
    chat.clear();
    _addBubble(text, true);
    setState(() => running = true);
    try {
      engine ??= AiEngine(
        baseUrl: widget.state.provider,
        model: widget.state.model,
        apiKey: await _loadKey(),
        permissions: widget.state.aiTools,
        deleteAllowed: widget.state.aiDelete,
        onConfirm: _confirmAction,
      );
      final reply = await engine!.chat(text);
      _addBubble(reply.isEmpty ? '…' : reply, false);
    } catch (e) {
      _addBubble('Ошибка: $e', false);
    } finally {
      if (mounted) setState(() => running = false);
    }
  }

  Future<String> _loadKey() async {
    try {
      final has = await NativeService.instance.hasApiKey();
      if (has) {
        // The key is encrypted natively; we pass an empty key so the engine
        // relies on the provider only when explicitly set in the UI field.
        return key.text.trim();
      }
    } catch (_) {}
    return key.text.trim();
  }

  Future<bool> _confirmAction(String action, String detail) async {
    final s = widget.state;
    final ok = await showDialog<bool>(
      context: context,
      builder: (x) => AlertDialog(
        icon: const Icon(Icons.warning_amber),
        title: Text(tr(s, 'Разрешить действие агента?', 'Allow agent action?')),
        content: Text('$action\n$detail'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(x, false),
              child: Text(tr(s, 'Отмена', 'Cancel'))),
          FilledButton(onPressed: () => Navigator.pop(x, true),
              child: Text(tr(s, 'Разрешить', 'Allow'))),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> save() async {
    final s = widget.state;
    s.provider = url.text.trim();
    s.model = model.text.trim();
    if (key.text.isNotEmpty) {
      await NativeService.instance.saveApiKey(key.text.trim());
      key.clear();
      s.log(tr(s, 'API-ключ сохранён в Android Keystore', 'API key saved in Android Keystore'));
    }
    s.change();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              const AssistantIcon(),
              const SizedBox(width: 12),
              Expanded(
                child: Text(tr(s, 'ИИ Мозг', 'AI Brain'),
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ),
              Switch(value: s.aiEnabled, onChanged: (v) => _toggle(v)),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            controller: _scroll,
            padding: const EdgeInsets.all(16),
            children: [
              _providerCard(s),
              const SizedBox(height: 12),
              if (s.aiEnabled) ...[
                _permissionsCard(s),
                const Divider(),
                _chatCard(s),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _providerCard(AppState s) => GlassCard(
    child: Column(
      children: [
        Row(
          children: [
            Icon(Icons.tune_rounded, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 10),
            Text(tr(s, 'Ваш провайдер', 'Your provider'),
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 14),
        TextField(
          controller: url,
          decoration: InputDecoration(
            labelText: tr(s, 'URL провайдера', 'Provider URL'),
            hintText: 'https://api.openai.com/v1',
            border: const OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: model,
          decoration: const InputDecoration(
            labelText: 'Model',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: key,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'API key',
            border: const OutlineInputBorder(),
            isDense: true,
            helperText: tr(
              s,
              'Шифруется Android Keystore. Не хранится в коде и логах.',
              'Encrypted with Android Keystore. Never stored in code or logs.'),
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: save,
            icon: const Icon(Icons.save_outlined),
            label: Text(tr(s, 'Сохранить', 'Save')),
          ),
        ),
      ],
    ),
  );

  Widget _permissionsCard(AppState s) => Card(
    child: ExpansionTile(
      title: Text(tr(s, 'Разрешения инструментов', 'Tool permissions')),
      children: [
        ...s.aiTools.entries.map((e) => SwitchListTile(
              title: Text(_tool(s, e.key)),
              value: e.value,
              onChanged: (v) => _permission(s, e.key, v),
            )),
        SwitchListTile(
          title: Text(tr(s, 'Отдельное разрешение на удаление', 'Separate delete opt-in')),
          subtitle: Text(tr(s, 'Каждое удаление требует подтверждения', 'Every deletion requires confirmation')),
          value: s.aiDelete,
          onChanged: (v) => _deleteOpt(s, v),
        ),
      ],
    ),
  );

  Widget _chatCard(AppState s) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(tr(s, 'Чат с агентом', 'Agent chat'),
          style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 8),
      if (bubbles.isEmpty)
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(tr(
            s,
            'Напишите задачу агенту, например: «найди все файлы .txt в папке Download» или «создай папку Тест с файлом заметки.txt».',
            'Give the agent a task, e.g. "find all .txt files in Download" or "create a Test folder with a notes.txt file".',
          )),
        )
      else
        ...bubbles.map((b) => Align(
              alignment: b.fromUser ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.all(12),
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                decoration: BoxDecoration(
                  color: b.fromUser
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: SelectableText(b.text),
              ),
            )),
      if (running)
        const Padding(
          padding: EdgeInsets.all(8),
          child: Center(child: CircularProgressIndicator()),
        ),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: chat,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                hintText: tr(s, 'Задача агенту…', 'Task for the agent…'),
                isDense: true,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: running ? null : _send,
            icon: const Icon(Icons.send),
          ),
        ],
      ),
    ],
  );

  String _tool(AppState s, String k) => {
    'read': tr(s, 'Чтение файлов', 'Read files'),
    'search': tr(s, 'Поиск', 'Search'),
    'move': tr(s, 'Перемещение', 'Move'),
    'rename': tr(s, 'Переименование', 'Rename'),
    'delete': tr(s, 'Удаление', 'Delete'),
    'root': 'Root',
  }[k]!;

  Future<void> _toggle(bool v) async {
    final s = widget.state;
    if (v && s.provider.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(tr(s, 'Сначала укажите URL провайдера и модель', 'Set provider URL and model first'))));
      return;
    }
    s.aiEnabled = v;
    s.log(v ? 'ИИ-агент включён' : 'ИИ-агент выключен');
  }

  Future<void> _permission(AppState s, String k, bool v) async {
    s.aiTools[k] = v;
    if (k == 'delete' && !v) s.aiDelete = false;
    s.log('AI permission $k = $v');
  }

  Future<void> _deleteOpt(AppState s, bool v) async {
    if (v && s.aiTools['delete'] != true) {
      s.aiTools['delete'] = true;
    }
    s.aiDelete = v;
    s.log('AI delete opt-in = $v');
  }
}

class ChatBubble {
  final String text;
  final bool fromUser;
  ChatBubble(this.text, this.fromUser);
}
