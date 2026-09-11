import 'package:flutter/material.dart';
import '../app.dart';
import '../widgets.dart';
import '../permission_service.dart';
import '../native_service.dart';

class Onboarding extends StatefulWidget {
  const Onboarding({super.key, required this.state});
  final AppState state;
  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding>
    with SingleTickerProviderStateMixin {
  int page = 0;
  final name = TextEditingController();
  final surname = TextEditingController();
  late final AnimationController _anim;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  bool _permsAllFiles = false;
  bool _permsChecked = false;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 480));
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _slide = Tween(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic));
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _to(int p) {
    setState(() => page = p);
    _anim.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xff0d1020), Color(0xff141a35), Color(0xff0d1020)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _topBar(s),
                Expanded(
                  child: SlideTransition(
                    position: _slide,
                    child: FadeTransition(
                      opacity: _fade,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 240),
                        child: _body(s),
                      ),
                    ),
                  ),
                ),
                _navButtons(s),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _topBar(AppState s) => Row(
    children: [
      const FzLogo(size: 44),
      const SizedBox(width: 12),
      Text('FZ Manager',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800, letterSpacing: -0.5)),
      const Spacer(),
      SegmentedButton<bool>(
        segments: const [
          ButtonSegment(value: true, label: Text('RU')),
          ButtonSegment(value: false, label: Text('EN')),
        ],
        selected: {s.russian},
        onSelectionChanged: (v) => s.russian = v.first,
      ),
    ],
  );

  Widget _body(AppState s) {
    if (page >= 3) return _tutorial(s);
    switch (page) {
      case 0:
        return _welcome(s);
      case 1:
        return _profile(s);
      default:
        return _permissions(s);
    }
  }

  Widget _welcome(AppState s) => ListView(
    key: const ValueKey(0),
    children: [
      const SizedBox(height: 40),
      Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Image.asset('assets/hero/hero_files.jpg',
              height: 220, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const FzLogo(size: 120)),
        ),
      ),
      const SizedBox(height: 32),
      Text(
        tr(s, 'Ваши файлы.\nПод вашим контролем.', 'Your files.\nUnder your control.'),
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800, height: 1.25, letterSpacing: -0.5),
      ),
      const SizedBox(height: 14),
      Text(
        tr(
          s,
          'Файловый менеджер нового поколения: умные пути, безопасный Root '
              'и подключаемый ИИ Мозг.',
          'A next-generation file manager: smart paths, safe Root and a '
              'pluggable AI Brain.'),
        textAlign: TextAlign.center,
        style: Theme.of(context)
            .textTheme
            .bodyLarge
            ?.copyWith(color: Colors.white70),
      ),
    ],
  );

  Widget _profile(AppState s) => ListView(
    key: const ValueKey(1),
    children: [
      const SizedBox(height: 28),
      Text(tr(s, 'Давайте познакомимся', 'Let\'s get acquainted'),
          style: Theme.of(context)
              .textTheme
              .headlineMedium
              ?.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Text(tr(s, 'Данные хранятся только на вашем устройстве.',
              'Data is stored only on your device.'),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white54)),
      const SizedBox(height: 24),
      TextField(
        controller: name,
        decoration: InputDecoration(
          labelText: tr(s, 'Имя *', 'First name *'),
          prefixIcon: const Icon(Icons.person_outline_rounded),
          border: const OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 14),
      TextField(
        controller: surname,
        decoration: InputDecoration(
          labelText: tr(s, 'Фамилия (необязательно)', 'Last name (optional)'),
          prefixIcon: const Icon(Icons.badge_outlined),
          border: const OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 24),
      Text(tr(s, 'Язык интерфейса', 'Interface language'),
          style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 10),
      SegmentedButton<bool>(
        segments: [
          ButtonSegment(value: true, label: Text(tr(s, 'Русский', 'Russian'))),
          ButtonSegment(value: false, label: Text(tr(s, 'Английский', 'English'))),
        ],
        selected: {s.russian},
        onSelectionChanged: (v) => s.russian = v.first,
      ),
    ],
  );

  Widget _permissions(AppState s) => ListView(
    key: const ValueKey(2),
    children: [
      const SizedBox(height: 8),
      const Center(child: AssistantIcon(size: 92)),
      const SizedBox(height: 16),
      Text(tr(s, 'Выдайте разрешения', 'Grant permissions'),
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .headlineMedium
              ?.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height: 10),
      Text(
        tr(
          s,
          'Привет! Я Физзи. Для полноценной работы мне нужен доступ к файлам. '
              'Нажмите кнопку ниже — Android откроет системные настройки, '
              'включите «Все файлы» и вернитесь.',
          'Hi! I am Fizzy. For full operation I need file access. Tap the '
              'button below — Android opens system settings, enable "All '
              'files" and come back.'),
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
      ),
      const SizedBox(height: 20),
      _permTile(
        icon: _permsChecked && _permsAllFiles
            ? Icons.check_circle_rounded
            : Icons.folder_open_rounded,
        color: _permsChecked && _permsAllFiles ? Colors.green : null,
        title: tr(s, 'Доступ ко всем файлам', 'Access to all files'),
        subtitle: tr(s,
            'Без него видны только медиа и общие папки.',
            'Without it only media and shared folders are visible.'),
        onTap: () async {
          await PermissionService.requestAllFiles();
          if (mounted) {
            final has = await NativeService.instance.isAllFilesAccess();
            setState(() {
              _permsChecked = true;
              _permsAllFiles = has;
            });
            _snack(has
                ? tr(s, 'Доступ ко всем файлам выдан!', 'All-files access granted!')
                : tr(s, 'Включите «Все файлы» в открывшихся настройках',
                    'Enable "All files" in the opened settings'));
          }
        },
      ),
      const SizedBox(height: 10),
      _permTile(
        icon: Icons.shield_outlined,
        title: 'Root',
        subtitle: tr(s,
            'Необязательно: проверит наличие root для системных файлов.',
            'Optional: checks root availability for system files.'),
        onTap: () async {
          s.rootChecked = true;
          s.rootAvailable = await NativeService.instance.isRootAvailable();
          _snack(s.rootAvailable
              ? tr(s, 'Root подтверждён', 'Root verified')
              : tr(s, 'Root не обнаружен — это нормально', 'Root not found — that is fine'));
        },
      ),
    ],
  );

  Widget _permTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? color,
  }) =>
      GlassCard(
        padding: EdgeInsets.zero,
        child: ListTile(
          leading: Icon(icon, size: 34, color: color),
          title: Text(title,
              style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: onTap,
        ),
      );

  Widget _tutorial(AppState s) {
    final steps = _tutorialSteps(s);
    final idx = (page - 3).clamp(0, steps.length - 1);
    final step = steps[idx];
    return ListView(
      key: ValueKey(page),
      children: [
        const SizedBox(height: 8),
        Center(child: AssistantIcon(size: 100)),
        const SizedBox(height: 18),
        Text(step.title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        const SizedBox(height: 12),
        Text(step.body,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: Colors.white70, height: 1.4)),
        const SizedBox(height: 26),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: (idx + 1) / steps.length,
            minHeight: 8,
            backgroundColor: Colors.white12,
          ),
        ),
        const SizedBox(height: 10),
        Text('${idx + 1} / ${steps.length}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  List<_Step> _tutorialSteps(AppState s) => [
    _Step(
      tr(s, 'Знакомьтесь: Физзи', 'Meet Fizzy'),
      tr(
        s,
        'Я твой личный помощник и знаю о FZ Manager всё: файлы, Root, ИИ '
            'Мозг, безопасность. Найдёте меня в разделе с моим именем.',
        'I am your personal assistant and I know everything about FZ '
            'Manager: files, Root, AI Brain, security. Find me in my own '
            'section.'),
    ),
    _Step(
      tr(s, 'Умный поиск путей', 'Smart path search'),
      tr(
        s,
        'Поле пути подсказывает существующие папки на лету и исправляет '
            'опечатки: /data/lokal станет /data/local одним касанием.',
        'The path field suggests existing folders on the fly and fixes '
            'typos: /data/lokal becomes /data/local in one tap.'),
    ),
    _Step(
      tr(s, 'Root и системные файлы', 'Root and system files'),
      tr(
        s,
        'В разделе Root — навигатор по системным разделам, просмотр файлов '
            'и запуск .sh от имени суперпользователя (с подтверждением).',
        'The Root section holds a navigator over system partitions, file '
            'viewing and running .sh as superuser (with confirmation).'),
    ),
    _Step(
      tr(s, 'ИИ Мозг', 'AI Brain'),
      tr(
        s,
        'Подключите своего провайдера — и агент сможет искать, читать, '
            'писать, копировать и даже создавать собственные инструменты. '
            'Всё — только с вашего разрешения.',
        'Connect your provider — the agent can search, read, write, copy '
            'and even create its own tools. Everything with your '
            'permission.'),
    ),
    _Step(
      tr(s, 'Корзина и безопасность', 'Trash and safety'),
      tr(
        s,
        'Удаление перемещает файлы в .fz_trash, откуда их можно вернуть. '
            'Опасные действия всегда требуют подтверждения.',
        'Deleting moves files to .fz_trash where they can be restored. '
            'Dangerous actions always require confirmation.'),
    ),
  ];

  Widget _navButtons(AppState s) {
    final last = page == 3 + _tutorialSteps(s).length - 1;
    return Row(
      children: [
        if (page > 0 && page != 1)
          TextButton(
            onPressed: () => _to(page - 1),
            child: Text(tr(s, 'Назад', 'Back')),
          ),
        const Spacer(),
        if (page >= 3)
          TextButton(
            onPressed: () => _skip(s),
            child: Text(tr(s, 'Пропустить', 'Skip')),
          ),
        const SizedBox(width: 8),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          ),
          onPressed: () => _next(s, last),
          icon: Icon(last ? Icons.rocket_launch_rounded : Icons.arrow_forward_rounded),
          label: Text(last ? tr(s, 'Начать', 'Start') : tr(s, 'Далее', 'Next')),
        ),
      ],
    );
  }

  void _next(AppState s, bool last) {
    if (page == 1 && name.text.trim().isEmpty) {
      _snack(tr(s, 'Введите имя', 'Enter your name'));
      return;
    }
    if (last) {
      s.name = name.text.trim();
      s.surname = surname.text.trim();
      s.onboarded = true;
      s.log(tr(s, 'Обучение завершено', 'Tutorial completed'));
      return;
    }
    _to(page + 1);
  }

  void _skip(AppState s) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Row(
          children: [
            const AssistantIcon(size: 34),
            const SizedBox(width: 12),
            Expanded(child: Text(tr(s, 'Пропустить обучение?', 'Skip tutorial?'))),
          ],
        ),
        content: Text(
          tr(
            s,
            'Если пропустить обучение, можно запутаться в некоторых разделах — '
                'Root, ИИ Мозг, безопасное удаление. Важные предупреждения '
                'всё равно появятся перед опасными действиями.',
            'If you skip the tutorial you may get confused in some sections — '
                'Root, AI Brain, safe delete. Important warnings will still '
                'appear before dangerous actions.'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: Text(tr(s, 'Продолжить обучение', 'Continue tutorial')),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(c);
              s.name = name.text.trim();
              s.surname = surname.text.trim();
              s.onboarded = true;
              s.log(tr(s, 'Обучение пропущено', 'Tutorial skipped'));
            },
            child: Text(tr(s, 'Завершить обучение', 'Finish tutorial')),
          ),
        ],
      ),
    );
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
}

class _Step {
  final String title;
  final String body;
  _Step(this.title, this.body);
}
