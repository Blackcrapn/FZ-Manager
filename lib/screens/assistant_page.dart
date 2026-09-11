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
  final List<Map<String, String>> msgs = [];

  @override
  void dispose() {
    input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _ask() {
    final q = input.text.trim();
    if (q.isEmpty) return;
    input.clear();
    final fizzy = Fizzy(russian: widget.state.russian);
    final answer = fizzy.answer(q) ?? (widget.state.russian
        ? 'Хм, я пока не знаю ответа на это. Спроси меня о Root, ИИ Мозге, '
              'умном поиске путей, корзине, избранном или настройках.'
        : 'Hmm, I do not know that yet. Ask me about Root, AI Brain, smart '
              'path search, trash, favorites or settings.');
    setState(() {
      msgs.add({'who': 'me', 'text': q});
      msgs.add({'who': 'fizzy', 'text': answer});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final fizzy = Fizzy(russian: s.russian);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              const AssistantIcon(),
              const SizedBox(width: 12),
              Expanded(
                child: Text(tr(s, 'Физзи — помощник', 'Fizzy — assistant'),
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            controller: _scroll,
            padding: const EdgeInsets.all(16),
            children: [
              if (msgs.isEmpty)
                _welcome(s, fizzy)
              else
                ...msgs.map((m) => Align(
                      alignment: m['who'] == 'me'
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(12),
                        constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.8),
                        decoration: BoxDecoration(
                          color: m['who'] == 'me'
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: SelectableText(m['text']!),
                      ),
                    )),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: input,
                  onSubmitted: (_) => _ask(),
                  decoration: InputDecoration(
                    hintText: tr(s, 'Спроси Физзи…', 'Ask Fizzy…'),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _ask,
                icon: const Icon(Icons.send),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _welcome(AppState s, Fizzy fizzy) => Column(
    children: [
      const Center(child: AssistantIcon(size: 96)),
      const SizedBox(height: 16),
      Text(fizzy.greeting, textAlign: TextAlign.center),
      const SizedBox(height: 16),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: fizzy.topics
            .map((t) => ActionChip(
                  avatar: const Icon(Icons.help_outline, size: 18),
                  label: Text(s.russian ? t.ruTitle : t.enTitle),
                  onPressed: () {
                    setState(() {
                      msgs.add({'who': 'fizzy', 'text': s.russian ? t.ruBody : t.enBody});
                    });
                  },
                ))
            .toList(),
      ),
    ],
  );
}
