import 'package:flutter/material.dart';
import '../app.dart';
import '../widgets.dart';
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
  bool _startedAnim = false;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              _topBar(s),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _body(s),
                ),
              ),
              _navButtons(s),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar(AppState s) => Row(
    children: [
      const FzLogo(size: 44),
      const SizedBox(width: 12),
      Text(
        'FZ Manager',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
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
    if (page >= 3) {
      if (!_startedAnim) {
        _startedAnim = true;
        _anim.forward(from: 0);
      }
      return _tutorial(s);
    }
    switch (page) {
      case 0:
        return _welcome(s);
      case 1:
        return _profile(s);
      default:
        return _permissions(s);
    }
  }

  Widget _welcome(AppState s) => Column(
    key: const ValueKey(0),
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const FzLogo(size: 120),
      const SizedBox(height: 28),
      Text(
        tr(s, 'Ваши файлы. Под вашим контролем.', 'Your files. Under your control.'),
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 12),
      Text(
        tr(
          s,
          'Быстрый файловый менеджер нового поколения с безопасным Root и мощным ИИ Мозгом.',
          'A next-generation fast file manager with safe Root and a powerful AI Brain.',
        ),
        textAlign: TextAlign.center,
      ),
    ],
  );

  Widget _profile(AppState s) => ListView(
    key: const ValueKey(1),
    children: [
      const SizedBox(height: 24),
      Text(
        tr(s, 'Давайте познакомимся', 'Let\'s get acquainted'),
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: 24),
      TextField(
        controller: name,
        decoration: InputDecoration(
          labelText: tr(s, 'Имя *', 'First name *'),
          prefixIcon: const Icon(Icons.person),
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: surname,
        decoration: InputDecoration(
          labelText: tr(s, 'Фамилия (необязательно)', 'Last name (optional)'),
        ),
      ),
    ],
  );

  Widget _permissions(AppState s) => ListView(
    key: const ValueKey(2),
    children: [
      const SizedBox(height: 16),
      const Center(child: AssistantIcon(size: 90)),
      const SizedBox(height: 12),
      Text(
        tr(s, 'Выдайте разрешения', 'Grant permissions'),
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: 12),
      Text(
        tr(
          s,
          'Физзи поможет настроить доступ. Для работы с системными файлами '
              'нужно разрешение «Все файлы».',
          'Fizzy will help you set up access. Working with system files '
              'requires the "All files" permission.',
        ),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 20),
      _permCard(
        icon: Icons.folder_open,
        title: tr(s, 'Доступ ко всем файлам', 'Access to all files'),
        desc: tr(
          s,
          'Проверит и направит в системные настройки для полного доступа.',
          'Checks and points to system settings for full access.',
        ),
        onTap: () => _requestAllFiles(s),
      ),
      const SizedBox(height: 10),
      _permCard(
        icon: Icons.shield_outlined,
        title: 'Root',
        desc: tr(
          s,
          'Проверит наличие root-доступа для системных файлов.',
          'Checks for root access to system files.',
        ),
        onTap: () => _checkRoot(s),
      ),
    ],
  );

  Widget _permCard({
    required IconData icon,
    required String title,
    required String desc,
    required VoidCallback onTap,
  }) => Card(
    child: ListTile(
      leading: Icon(icon, size: 32),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(desc),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );

  Future<void> _requestAllFiles(AppState s) async {
    final has = await NativeService.instance.isAllFilesAccess();
    if (has) {
      _snack(tr(s, 'Доступ ко всем файлам уже выдан', 'All-files access already granted'));
    } else {
      _snack(
        tr(
          s,
          'Разрешите «Все файлы» в настройках: Приложения → FZ Manager → '
              'Файлы и мультимедиа → Все файлы → Разрешить.',
          'Allow "All files" in settings: Apps → FZ Manager → Files and media '
              '→ All files → Allow.',
        ),
      );
    }
  }

  Future<void> _checkRoot(AppState s) async {
    s.rootChecked = true;
    s.rootAvailable = await NativeService.instance.isRootAvailable();
    _snack(
      s.rootAvailable
          ? tr(s, 'Root подтверждён', 'Root verified')
          : tr(s, 'Root не обнаружен', 'Root not found'),
    );
  }

  Widget _tutorial(AppState s) {
    final steps = _tutorialSteps(s);
    final idx = (page - 3).clamp(0, steps.length - 1);
    final step = steps[idx];
    return FadeTransition(
      opacity: _fade,
      child: ListView(
        key: ValueKey(page),
        children: [
          const SizedBox(height: 16),
          Center(child: AssistantIcon(size: 96)),
          const SizedBox(height: 16),
          Text(
            step.title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(step.body, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          LinearProgressIndicator(value: (idx + 1) / steps.length),
        ],
      ),
    );
  }

  List<_Step> _tutorialSteps(AppState s) => [
    _Step(
      tr(s, 'Знакомьтесь: Физзи', 'Meet Fizzy'),
      tr(
        s,
        'Я твой помощник. Объясню любую функцию FZ Manager и никогда не '
            'сделаю ничего без твоего решения.',
        'I am your assistant. I explain any FZ Manager feature and never act '
            'without your decision.',
      ),
    ),
    _Step(
      tr(s, 'Умный поиск путей', 'Smart path search'),
      tr(
        s,
        'Начни вводить путь — я подскажу существующие папки и исправлю '
            'неверные части. /data/lokal станет /data/local.',
        'Start typing a path — I suggest existing folders and fix wrong parts. '
            '/data/lokal becomes /data/local.',
      ),
    ),
    _Step(
      tr(s, 'Безопасное удаление', 'Safe delete'),
      tr(
        s,
        'Удаление перемещает файлы в корзину .fz_trash, откуда их можно '
            'восстановить. Ничего не теряется.',
        'Deleting moves files to the .fz_trash folder, where they can be '
            'restored. Nothing is lost.',
      ),
    ),
    _Step(
      tr(s, 'ИИ Мозг', 'AI Brain'),
      tr(
        s,
        'Подключи своего провайдера и агент сможет работать с файлами: '
            'искать, читать, создавать, перемещать — с твоего разрешения.',
        'Connect your provider and the agent can work with files: search, '
            'read, create, move — with your permission.',
      ),
    ),
  ];

  Widget _navButtons(AppState s) {
    final totalTutorial = 3 + _tutorialSteps(s).length - 1;
    final last = page == totalTutorial;
    return Row(
      children: [
        if (page > 0 && page != 1)
          TextButton(
            onPressed: () => setState(() => page--),
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
          onPressed: () => _next(s, totalTutorial),
          icon: Icon(last ? Icons.check : Icons.arrow_forward),
          label: Text(
            last ? tr(s, 'Начать', 'Start') : tr(s, 'Далее', 'Next'),
          ),
        ),
      ],
    );
  }

  void _next(AppState s, int last) {
    if (page == 1 && name.text.trim().isEmpty) {
      _snack(tr(s, 'Введите имя', 'Enter your name'));
      return;
    }
    if (page == last) {
      s.name = name.text.trim();
      s.surname = surname.text.trim();
      s.onboarded = true;
      s.log(tr(s, 'Обучение завершено', 'Tutorial completed'));
      return;
    }
    setState(() => page++);
  }

  void _skip(AppState s) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(tr(s, 'Пропустить обучение?', 'Skip tutorial?')),
        content: Text(
          tr(
            s,
            'Если пропустить обучение, вы можете запутаться в некоторых '
                'разделах (Root, ИИ Мозг, безопасное удаление). Важные '
                'предупреждения всё равно появятся перед опасными действиями.',
            'If you skip the tutorial you may get confused in some sections '
                '(Root, AI Brain, safe delete). Important warnings will still '
                'appear before dangerous actions.',
          ),
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
