import 'package:flutter/material.dart';
import '../app.dart';
import '../widgets.dart';
import '../native_service.dart';
import '../ai_engine.dart';
import '../chat_service.dart';

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
  ChatService? chatService;
  List<AiChat> chats = [];
  AiChat? activeChat;
  bool running = false;
  bool keyStored = false;

  @override
  void initState() {
    super.initState();
    url.text = widget.state.provider;
    model.text = widget.state.model;
    _init();
  }

  Future<void> _init() async {
    chatService = await ChatService.load();
    final stored = await NativeService.instance.hasApiKey();
    if (mounted) {
      setState(() {
        chats = chatService!.loadChats();
        keyStored = stored;
      });
    }
  }

  @override
  void dispose() {
    chat.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final s = widget.state;
    s.provider = url.text.trim();
    s.model = model.text.trim();
    if (key.text.isNotEmpty) {
      try {
        await NativeService.instance.saveApiKey(key.text.trim());
        key.clear();
        if (mounted) {
          setState(() => keyStored = true);
        }
        s.log(tr(s, 'API-ключ сохранён в Android Keystore', 'API key saved in Android Keystore'));
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${tr(s, 'Ошибка сохранения ключа', 'Key save error')}: $e')));
        }
        return;
      }
    }
    s.change();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr(s, 'Настройки провайдера сохранены', 'Provider settings saved'))));
    }
  }

  void _newChat() {
    final c = AiChat(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: tr(widget.state, 'Новый чат', 'New chat'),
    );
    setState(() {
      chats.insert(0, c);
      activeChat = c;
    });
    _persist();
  }

  void _openChat(AiChat c) => setState(() => activeChat = c);

  Future<void> _deleteChat(AiChat c) async {
    final s = widget.state;
    final ok = await showDialog<bool>(
      context: context,
      builder: (x) => AlertDialog(
        title: Text(tr(s, 'Удалить чат?', 'Delete chat?')),
        content: Text('"${c.title}"'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(x, false), child: Text(tr(s, 'Отмена', 'Cancel'))),
          FilledButton(onPressed: () => Navigator.pop(x, true), child: Text(tr(s, 'Удалить', 'Delete'))),
        ],
      ),
    ) ?? false;
    if (!ok) return;
    setState(() {
      chats.remove(c);
      if (activeChat?.id == c.id) activeChat = null;
    });
    _persist();
  }

  void _persist() {
    chatService?.saveChats(chats);
  }

  void _addMessage(String text, {required bool fromUser, bool isTool = false}) {
    if (activeChat == null) return;
    setState(() {
      activeChat!.messages.add(AiMessage(
          role: isTool ? 'tool' : (fromUser ? 'user' : 'assistant'), content: text));
      if (activeChat!.messages.length == 1) {
        final t = text.length > 32 ? '${text.substring(0, 32)}…' : text;
        activeChat!.title = t;
      }
    });
    _persist();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final s = widget.state;
    final text = chat.text.trim();
    if (text.isEmpty || running) return;
    if (!s.aiEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(tr(s, 'Включите ИИ Мозг переключателем', 'Enable the AI Brain switch'))));
      return;
    }
    if (s.provider.isEmpty || s.model.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(tr(s, 'Сначала укажите URL и модель провайдера', 'Set provider URL and model first'))));
      return;
    }
    activeChat ??= AiChat(id: DateTime.now().millisecondsSinceEpoch.toString(), title: tr(s, 'Новый чат', 'New chat'));
    final current = activeChat!;
    if (!chats.contains(current)) chats.insert(0, current);
    chat.clear();
    _addMessage(text, fromUser: true);
    setState(() => running = true);
    try {
      final apiKey = await NativeService.instance.getApiKey() ?? '';
      final engine = AiEngine(
        baseUrl: s.provider,
        model: s.model,
        apiKey: apiKey,
        permissions: s.aiTools,
        deleteAllowed: s.aiDelete,
        onConfirm: _confirmAction,
      );
      final priorContext = current.messages
          .where((m) => m.role == 'user' || m.role == 'assistant')
          .take(40)
          .map((m) => ChatMessage(m.role, m.content))
          .toList();
      final result = await engine.chat(text, priorContext);
      for (final m in result.addedMessages) {
        if (m.role == 'tool') {
          _addMessage(m.content, fromUser: false, isTool: true);
        }
      }
      if (result.reply.isNotEmpty) {
        _addMessage(result.reply, fromUser: false);
      } else {
        _addMessage(tr(s, '(пустой ответ модели)', '(empty model reply)'), fromUser: false);
      }
    } catch (e) {
      final msg = '$e';
      _addMessage(msg.contains('401')
          ? tr(s, 'Ошибка 401: неверный API-ключ. Сохраните ключ заново в карточке провайдера.',
              'Error 401: invalid API key. Re-save the key in the provider card.')
          : msg, fromUser: false);
    } finally {
      if (mounted) setState(() => running = false);
    }
  }

  Future<bool> _confirmAction(String action, String detail) async {
    final s = widget.state;
    final ok = await showDialog<bool>(
      context: context,
      builder: (x) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded),
        title: Text(tr(s, 'Разрешить действие агента?', 'Allow agent action?')),
        content: Text('$action\n$detail'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(x, false), child: Text(tr(s, 'Отмена', 'Cancel'))),
          FilledButton(onPressed: () => Navigator.pop(x, true), child: Text(tr(s, 'Разрешить', 'Allow'))),
        ],
      ),
    );
    return ok ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    if (activeChat != null) return _chatView(s);
    return _lobby(s);
  }

  // ---------- LOBBY (chats list + provider) ----------

  Widget _lobby(AppState s) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Row(
        children: [
          const AssistantIcon(size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Text(tr(s, 'ИИ Мозг', 'AI Brain'),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          ),
          Switch(value: s.aiEnabled, onChanged: (v) => _toggle(v)),
        ],
      ),
      const SizedBox(height: 12),
      _providerCard(s),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: Text(tr(s, 'Чаты', 'Chats'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          ),
          FilledButton.icon(
            onPressed: _newChat,
            icon: const Icon(Icons.add_rounded),
            label: Text(tr(s, 'Новый', 'New')),
          ),
        ],
      ),
      const SizedBox(height: 8),
      if (chats.isEmpty)
        EmptyState(
          title: tr(s, 'Чатов пока нет', 'No chats yet'),
          subtitle: tr(s, 'Создайте чат и поставьте задачу агенту',
              'Create a chat and give the agent a task'),
        )
      else
        ...chats.map((c) => GlassCard(
              padding: EdgeInsets.zero,
              child: ListTile(
                leading: const Icon(Icons.chat_bubble_outline_rounded),
                title: Text(c.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(
                  c.messages.isEmpty
                      ? tr(s, 'пусто', 'empty')
                      : c.messages.last.content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _deleteChat(c),
                    ),
                  ],
                ),
                onTap: () => _openChat(c),
              ),
            )),
      const SizedBox(height: 12),
      _permissionsCard(s),
    ],
  );

  // ---------- CHAT VIEW ----------

  Widget _chatView(AppState s) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
        child: Row(
          children: [
            IconButton(
              onPressed: () => setState(() => activeChat = null),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            Expanded(
              child: Text(
                activeChat!.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Switch(value: s.aiEnabled, onChanged: (v) => _toggle(v)),
          ],
        ),
      ),
      Expanded(
        child: activeChat!.messages.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    tr(s,
                        'Напишите задачу агенту, например: «найди все .txt в Download» или «создай папку Тест с файлом readme.md».',
                        'Give the agent a task, e.g. "find all .txt in Download" or "create a Test folder with readme.md".'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              )
            : ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.all(16),
                itemCount: activeChat!.messages.length,
                itemBuilder: (_, i) {
                  final m = activeChat!.messages[i];
                  final fromUser = m.role == 'user';
                  final isTool = m.role == 'tool';
                  return Align(
                    alignment: fromUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(12),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
                      decoration: BoxDecoration(
                        color: isTool
                            ? Theme.of(context).colorScheme.tertiaryContainer
                            : fromUser
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(18),
                          topRight: const Radius.circular(18),
                          bottomLeft: Radius.circular(fromUser ? 18 : 4),
                          bottomRight: Radius.circular(fromUser ? 4 : 18),
                        ),
                      ),
                      child: SelectableText(
                        m.content,
                        style: isTool
                            ? const TextStyle(fontFamily: 'monospace', fontSize: 12)
                            : null,
                      ),
                    ),
                  );
                },
              ),
      ),
      if (running)
        const Padding(
          padding: EdgeInsets.all(8),
          child: Center(child: CircularProgressIndicator()),
        ),
      _inputBar(s),
    ],
  );

  Widget _inputBar(AppState s) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
    child: GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      radius: 26,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: chat,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                hintText: tr(s, 'Задача агенту…', 'Task for the agent…'),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
          IconButton.filled(
            onPressed: running ? null : _send,
            icon: const Icon(Icons.send_rounded),
          ),
        ],
      ),
    ),
  );

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
            helperText: keyStored
                ? tr(s, 'Ключ сохранён в Keystore. Введите новый, чтобы заменить.',
                    'Key stored in Keystore. Type a new one to replace.')
                : tr(s, 'Шифруется Android Keystore. Не хранится в коде и логах.',
                    'Encrypted with Android Keystore. Never stored in code or logs.'),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              onPressed: _testConnection,
              icon: const Icon(Icons.wifi_tethering_rounded),
              label: Text(tr(s, 'Проверить связь', 'Test connection')),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: save,
              icon: const Icon(Icons.save_outlined),
              label: Text(tr(s, 'Сохранить', 'Save')),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _permissionsCard(AppState s) => GlassCard(
    padding: EdgeInsets.zero,
    child: ExpansionTile(
      leading: const Icon(Icons.policy_outlined),
      title: Text(tr(s, 'Разрешения инструментов и журнал', 'Tool permissions and log')),
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
        ListTile(
          leading: const Icon(Icons.history_rounded),
          title: Text(tr(s, 'Журнал аудита', 'Audit log')),
          subtitle: s.audit.isEmpty
              ? Text(tr(s, 'Записей нет', 'No entries'))
              : Text(s.audit.first, maxLines: 2, overflow: TextOverflow.ellipsis),
          onTap: () => showDialog(
            context: context,
            builder: (x) => AlertDialog(
              title: Text(tr(s, 'Журнал аудита', 'Audit log')),
              content: SizedBox(
                width: 520,
                child: s.audit.isEmpty
                    ? Text(tr(s, 'Записей нет', 'No entries'))
                    : ListView(
                        shrinkWrap: true,
                        children: s.audit.take(100).map((a) => ListTile(dense: true, title: Text(a))).toList(),
                      ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(x), child: Text(tr(s, 'Закрыть', 'Close'))),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  /// Quick provider diagnostics: one minimal request, human verdict.
  Future<void> _testConnection() async {
    final s = widget.state;
    final base = url.text.trim().isNotEmpty ? url.text.trim() : s.provider;
    final mdl = model.text.trim().isNotEmpty ? model.text.trim() : s.model;
    if (base.isEmpty || mdl.isEmpty) {
      _snackMsg(tr(s, 'Заполните URL и модель', 'Fill URL and model'));
      return;
    }
    _snackMsg(tr(s, 'Проверяю связь…', 'Checking connection…'));
    final engine = AiEngine(
      baseUrl: base,
      model: mdl,
      apiKey: await NativeService.instance.getApiKey() ?? '',
      permissions: {'read': true},
      deleteAllowed: false,
      onConfirm: (_, __) async => false,
    );
    try {
      await engine.chat('ping', const []);
      _snackMsg(tr(s, 'Связь в порядке ✓', 'Connection OK ✓'));
    } catch (e) {
      final msg = e is AiProviderException ? e.human(s.russian) : '$e';
      _snackMsg(msg);
    }
  }

  void _snackMsg(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

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
