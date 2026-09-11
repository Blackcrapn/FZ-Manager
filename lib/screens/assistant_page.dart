import 'package:flutter/material.dart';
import '../app.dart';
import '../widgets.dart';
import '../assistant.dart';

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

  @override
  void initState() {
    super.initState();
    fizzy = Fizzy(russian: widget.state.russian);
  }

  @override
  void dispose() {
    input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _addBubble(_Bubble b) {
    setState(() => msgs.add(b));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _ask([String? preset]) {
    final q = (preset ?? input.text).trim();
    if (q.isEmpty) return;
    input.clear();
    _addBubble(_Bubble(q, true));
    final a = fizzy.answer(q);
    _addBubble(_Bubble.withGuide(a, false));
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    fizzy = Fizzy(russian: s.russian);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              const AssistantIcon(size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr(s, 'Физзи', 'Fizzy'),
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    Text(tr(s, 'знает всё о FZ Manager', 'knows all about FZ Manager'),
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              IconButton(
                tooltip: tr(s, 'Очистить', 'Clear'),
                onPressed: () => setState(() => msgs.clear()),
                icon: const Icon(Icons.cleaning_services_outlined),
              ),
            ],
          ),
        ),
        Expanded(
          child: msgs.isEmpty
              ? _welcome(s)
              : ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(16),
                  itemCount: msgs.length,
                  itemBuilder: (_, i) {
                    final m = msgs[i];
                    return Align(
                      alignment: m.fromUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: m.guide.isEmpty
                            ? const EdgeInsets.all(12)
                            : const EdgeInsets.all(14),
                        constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.82),
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
                ),
        ),
        _inputBar(s),
      ],
    );
  }

  Widget _guideBubble(BuildContext context, _Bubble m) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText(m.text),
          if (m.guide.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(tr(widget.state, 'Как сделать:', 'How to:'),
                style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            ...List.generate(
              m.guide.length,
              (i) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      child: Text('${i + 1}',
                          style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(m.guide[i])),
                  ],
                ),
              ),
            ),
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
      'root': tr(s, 'Root', 'Root'),
      'ai': tr(s, 'ИИ Мозг', 'AI Brain'),
      'storage': tr(s, 'Хранилище', 'Storage'),
      'settings': tr(s, 'Настройки', 'Settings'),
      'app': tr(s, 'Приложение', 'App'),
    };
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 8),
        Center(child: AssistantIcon(size: 104)),
        const SizedBox(height: 16),
        Text(fizzy.greeting, textAlign: TextAlign.center,
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

class _Bubble {
  final String text;
  final bool fromUser;
  final List<String> guide;
  _Bubble(this.text, this.fromUser, {this.guide = const []});
  factory _Bubble.withGuide(FizzyAnswer a, bool fromUser) =>
      _Bubble(a.text, fromUser, guide: a.guide);
}
