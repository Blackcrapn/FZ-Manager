/// Fizzy - the built-in mini assistant for FZ Manager.
///
/// Fizzy knows everything about FZ Manager features, safety and tips.
/// It answers questions from a curated knowledge base and offers
/// contextual hints across the app.
class Fizzy {
  final bool russian;
  Fizzy({required this.russian});

  String get greeting => russian
      ? 'Привет! Я Физзи — твой помощник в FZ Manager. Спроси меня о '
          'файлах, Root, ИИ Мозге или настройках — я всё объясню.'
      : 'Hi! I am Fizzy, your assistant in FZ Manager. Ask me about '
          'files, Root, AI Brain or settings — I will explain everything.';

  /// Returns a list of topics Fizzy knows about.
  List<KnowledgeTopic> get topics => [
        KnowledgeTopic(
          id: 'root',
          ruTitle: 'Root и системные файлы',
          enTitle: 'Root and system files',
          ruKeywords: const ['root', 'суперпользователь', 'системные', 'su'],
          enKeywords: const ['root', 'superuser', 'system'],
          ruBody:
              'Раздел Root открывает доступ к корневому разделу и системным файлам. '
                  'FZ Manager проверяет наличие root только безопасной командой `su -c id`. '
                  'Изменяющие root-команды всегда требуют подтверждения и записываются в журнал. '
                  'Без root-доступа системные каталоги остаются только для чтения.',
          enBody:
              'The Root section opens access to the root partition and system files. '
                  'FZ Manager probes root only with the safe `su -c id` command. '
                  'Mutating root commands always require confirmation and are audited. '
                  'Without root, system directories stay read-only.',
        ),
        KnowledgeTopic(
          id: 'aibrain',
          ruTitle: 'ИИ Мозг',
          enTitle: 'AI Brain',
          ruKeywords: const ['ии', 'мозг', 'агент', 'искусственный', 'ai'],
          enKeywords: const ['ai', 'brain', 'agent', 'assistant'],
          ruBody:
              'ИИ Мозг — это агент, который может работать с файлами через инструменты. '
                  'Чтобы включить его, задай своего провайдера (URL, модель, API-ключ) в настройках. '
                  'Агент использует только разрешённые инструменты, а опасные действия '
                  '(удаление, перемещение) всегда подтверждаются отдельно.',
          enBody:
              'AI Brain is an agent that can work with files through tools. '
                  'Enable it by providing your own provider (URL, model, API key) in settings. '
                  'The agent uses only permitted tools; dangerous actions (delete, move) '
                  'always require separate confirmation.',
        ),
        KnowledgeTopic(
          id: 'smartpath',
          ruTitle: 'Умный поиск путей',
          enTitle: 'Smart path search',
          ruKeywords: const ['путь', 'поиск', 'путей', 'автодополнение', 'исправление'],
          enKeywords: const ['path', 'search', 'autocomplete'],
          ruBody:
              'В поле пути FZ Manager подсказывает существующие каталоги по мере ввода. '
                  'Если какой-то сегмент не существует, система ищет ближайший похожий '
                  'и предлагает исправление — например /data/lokal станет /data/local.',
          enBody:
              'In the path field FZ Manager suggests existing folders while you type. '
                  'If a segment does not exist, the system finds the closest match '
                  'and offers a correction — e.g. /data/lokal becomes /data/local.',
        ),
        KnowledgeTopic(
          id: 'trash',
          ruTitle: 'Корзина',
          enTitle: 'Trash',
          ruKeywords: const ['корзина', 'удаление', 'восстановить', 'trash'],
          enKeywords: const ['trash', 'delete', 'restore'],
          ruBody:
              'Удаление не уничтожает файлы сразу: они перемещаются в папку .fz_trash. '
                  'Оттуда их можно восстановить или очистить корзину окончательно. '
                  'Это защищает от случайной потери данных.',
          enBody:
              'Deleting does not destroy files right away: they move to the .fz_trash folder. '
                  'From there you can restore them or empty the trash for good. '
                  'This protects against accidental data loss.',
        ),
        KnowledgeTopic(
          id: 'favorites',
          ruTitle: 'Избранное и закладки',
          enTitle: 'Favorites and bookmarks',
          ruKeywords: const ['избранное', 'закладки', 'закладка', 'favorite', 'bookmark'],
          enKeywords: const ['favorite', 'bookmark'],
          ruBody:
              'Избранное хранит отдельные файлы и папки, а закладки путей — быстрые '
                  'переходы к каталогам. И то и другое доступно из раздела Файлы и Обзор.',
          enBody:
              'Favorites store individual files and folders; path bookmarks give quick '
                  'jumps to directories. Both are available from the Files and Insights sections.',
        ),
        KnowledgeTopic(
          id: 'custom',
          ruTitle: 'Кастомизация',
          enTitle: 'Customization',
          ruKeywords: const ['кастомизация', 'тема', 'цвет', 'плотность', 'настройка'],
          enKeywords: const ['theme', 'color', 'density', 'custom'],
          ruBody:
              'В настройках можно сменить тему (тёмная/светлая), акцентный цвет, '
                  'плотность интерфейса, язык и вид по умолчанию (список/сетка).',
          enBody:
              'In settings you can change the theme (dark/light), accent color, '
                  'UI density, language and the default view (list/grid).',
        ),
        KnowledgeTopic(
          id: 'permissions',
          ruTitle: 'Разрешения',
          enTitle: 'Permissions',
          ruKeywords: const ['разрешение', 'доступ', 'файлам', 'все файлы', 'permission'],
          enKeywords: const ['permission', 'access', 'all files'],
          ruBody:
              'Для полного доступа ко всем файлам FZ Manager направляет в системные '
                  'настройки, где можно выдать разрешение «Все файлы». Без него доступ '
                  'ограничен вашими медиафайлами и общими каталогами.',
          enBody:
              'For full all-files access FZ Manager points to system settings where you '
                  'can grant the "All files" permission. Without it access is limited '
                  'to your media files and shared folders.',
        ),
      ];

  /// Answers a free-form question using simple keyword matching.
  /// Returns null when no topic matched.
  String? answer(String question) {
    final q = question.toLowerCase();
    for (final t in topics) {
      final words = russian ? t.ruKeywords : t.enKeywords;
      for (final w in words) {
        if (q.contains(w)) return russian ? t.ruBody : t.enBody;
      }
    }
    return null;
  }

  /// Contextual tip for the current screen.
  String tipFor(String screen) {
    final tips = <String, String>{
      'files': russian
          ? 'Подсказка: долгое нажатие на элемент выделяет его для массовых действий.'
          : 'Tip: long-press an item to select it for batch actions.',
      'root': russian
          ? 'Помни: изменяющие root-команды всегда подтверждаются отдельно.'
          : 'Remember: mutating root commands are always confirmed separately.',
      'ai': russian
          ? 'Включи ИИ Мозг и укажи своего провайдера, чтобы агент работал с файлами.'
          : 'Enable AI Brain and set your provider so the agent can work with files.',
      'insights': russian
          ? 'Обзор показывает корзину, закладки и инструменты анализа хранилища.'
          : 'Insights shows the trash, bookmarks and storage analysis tools.',
      'settings': russian
          ? 'Тут можно настроить тему, цвет, плотность и язык под себя.'
          : 'Here you can tune the theme, color, density and language.',
    };
    return tips[screen] ?? greeting;
  }
}

class KnowledgeTopic {
  final String id;
  final String ruTitle;
  final String enTitle;
  final List<String> ruKeywords;
  final List<String> enKeywords;
  final String ruBody;
  final String enBody;
  KnowledgeTopic({
    required this.id,
    required this.ruTitle,
    required this.enTitle,
    required this.ruKeywords,
    required this.enKeywords,
    required this.ruBody,
    required this.enBody,
  });
}
