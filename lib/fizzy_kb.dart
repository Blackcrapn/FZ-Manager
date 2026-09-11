/// Fizzy — the built-in assistant of FZ Manager.
///
/// A large curated knowledge base with intent classification:
/// topics, step-by-step guides, FAQ, contextual tips, daily tips,
/// conversation context (follow-ups) and smalltalk — all bilingual.
library;

class FizzyEntry {
  final String id;
  final String ruTitle;
  final String enTitle;
  final List<String> ruKeywords;
  final List<String> enKeywords;
  final String ruBody;
  final String enBody;
  final String category;
  final List<String> ruGuide;
  final List<String> enGuide;
  const FizzyEntry({
    required this.id,
    required this.ruTitle,
    required this.enTitle,
    required this.ruKeywords,
    required this.enKeywords,
    required this.ruBody,
    required this.enBody,
    this.category = 'general',
    this.ruGuide = const [],
    this.enGuide = const [],
  });
}

const _kTopics = <FizzyEntry>[
  // ---------- FILES ----------
  FizzyEntry(
    id: 'files_browse',
    category: 'files',
    ruTitle: 'Просмотр файлов',
    enTitle: 'Browsing files',
    ruKeywords: ['просмотр', 'листать', 'папки', 'файлы', 'обзор файлов', 'лист'],
    enKeywords: ['browse', 'files', 'folders', 'list', 'view'],
    ruBody:
        'Раздел «Файлы» — сердце FZ Manager. Сверху — умное поле пути: оно '
        'проверяет существование каждой части и предлагает исправления. '
        'Под ним — мгновенный поиск по текущей папке. Ниже — файлы списком '
        'или сеткой. Долгое нажатие выделяет элемент, так можно выделить '
        'десятки файлов и применить массовые действия.',
    enBody:
        'The Files section is the heart of FZ Manager. At the top is the '
        'smart path field: it validates every part as you type and offers '
        'fixes. Below it is instant search within the current folder. Files '
        'appear as a list or grid. Long-press to select items for batch '
        'actions.',
    ruGuide: [
      'Откройте раздел «Файлы»',
      'Введите путь вверху или нажмите стрелку вверх для перехода к родителю',
      'Переключите вид список/сетка кнопкой справа вверху',
      'Сортировка — меню с тремя точками (имя, дата, размер)',
    ],
    enGuide: [
      'Open the Files section',
      'Type a path on top or tap the up-arrow to go to the parent folder',
      'Toggle list/grid with the button in the top right',
      'Sorting lives in the three-dot menu (name, date, size)',
    ],
  ),
  FizzyEntry(
    id: 'files_hidden',
    category: 'files',
    ruTitle: 'Скрытые файлы',
    enTitle: 'Hidden files',
    ruKeywords: ['скрытые', 'скрытые файлы', 'точка', 'dotfiles', 'показать скрытые'],
    enKeywords: ['hidden', 'dotfiles', 'show hidden'],
    ruBody:
        'Файлы, начинающиеся с точки (например .nomedia), по умолчанию '
        'скрыты. Включить их показ: Настройки → «Показывать скрытые '
        'файлы». Скрытые системные файлы важны для продвинутых задач — но '
        'их легко случайно удалить, поэтому будьте внимательны.',
    enBody:
        'Files starting with a dot (e.g. .nomedia) are hidden by default. '
        'Enable them: Settings → "Show hidden files". Hidden system files '
        'matter for advanced tasks — but they are easy to delete by '
        'accident, so stay careful.',
  ),
  FizzyEntry(
    id: 'smart_path',
    category: 'files',
    ruTitle: 'Умный поиск путей',
    enTitle: 'Smart path search',
    ruKeywords: ['путь', 'пути', 'умный', 'автодополнение', 'исправление пути', 'lokal', 'не существует', 'опечатк'],
    enKeywords: ['path', 'smart', 'autocomplete', 'typo', 'lokal', 'correction'],
    ruBody:
        'Поле пути — с IQ. На каждую букву FZ Manager находит самый длинный '
        'существующий префикс пути и подсказывает реальные папки, которые '
        'можно продолжить (чипы под полем). Если сегмента нет — система '
        'ищет похожие через расстояние Левенштейна и предлагает замену: '
        '/data/lokal → /data/local. Кнопка «Исправить» применяет замену '
        'одним касанием.',
    enBody:
        'The path field has an IQ. With every character FZ Manager finds '
        'the longest existing prefix and suggests real folders to continue '
        'with (chips under the field). If a segment does not exist, the '
        'system finds similar names via Levenshtein distance and offers a '
        'fix: /data/lokal → /data/local. The "Fix" chip applies it in one '
        'tap.',
    ruGuide: [
      'Начните печатать путь — под полем появятся подсказки',
      'Чипы показывают только реально существующие папки',
      'Если опечатка — появится чип «Исправить»',
      'Нажмите Enter для перехода',
    ],
    enGuide: [
      'Start typing a path — suggestions appear under the field',
      'Chips show only folders that really exist',
      'On a typo you get a "Fix" chip',
      'Press Enter to navigate',
    ],
  ),
  FizzyEntry(
    id: 'files_trash',
    category: 'files',
    ruTitle: 'Корзина и восстановление',
    enTitle: 'Trash and restore',
    ruKeywords: ['корзина', 'удалить', 'удаление', 'восстановить', 'восстановление', 'fz_trash', 'trash'],
    enKeywords: ['trash', 'delete', 'restore', 'recycle', 'fz_trash'],
    ruBody:
        'FZ Manager никогда не удаляет сразу. «Удалить» переносит файл в '
        'специальную папку .fz_trash в корне хранилища, добавляя метку '
        'времени, чтобы не было конфликтов имён. Обзор → Корзина: элементы '
        'можно восстановить (кнопка со стрелкой) — файл вернётся в '
        'исходную папку. Ничего не теряется, пока вы сами не очистите '
        'корзину.',
    enBody:
        'FZ Manager never deletes instantly. "Delete" moves the file to '
        'the .fz_trash folder at the storage root with a timestamp prefix '
        'to avoid name clashes. Insights → Trash: restore any item — it '
        'returns to its original folder. Nothing is lost until you empty '
        'the trash yourself.',
    ruGuide: [
      'Долгое нажатие → «В корзину» (или меню у файла)',
      'Обзор → Корзина — список удалённого',
      'Кнопка восстановления возвращает файл на место',
    ],
    enGuide: [
      'Long-press → "Move to trash" (or the menu on a file)',
      'Insights → Trash lists removed items',
      'The restore button returns the file to its place',
    ],
  ),
  FizzyEntry(
    id: 'files_favorites',
    category: 'files',
    ruTitle: 'Избранное, закладки и недавние',
    enTitle: 'Favorites, bookmarks and recents',
    ruKeywords: ['избранное', 'закладки', 'недавние', 'звезда', 'быстрый доступ'],
    enKeywords: ['favorites', 'bookmarks', 'recents', 'star', 'quick access'],
    ruBody:
        'Три вида быстрого доступа. Избранное (звезда) — конкретные файлы и '
        'папки; доступ из шапки раздела «Файлы». Закладки путей — быстрые '
        'переходы к каталогам, видны в «Обзоре». Недавние — 15 последних '
        'открытых папок, запоминается автоматически. Всё сохраняется '
        'между запусками.',
    enBody:
        'Three kinds of quick access. Favorites (star) — specific files and '
        'folders, reachable from the Files header. Path bookmarks — quick '
        'jumps to directories, listed in Insights. Recents — the last 15 '
        'folders you opened, remembered automatically. Everything persists '
        'between app restarts.',
  ),
  FizzyEntry(
    id: 'files_rename',
    category: 'files',
    ruTitle: 'Переименование и массовые действия',
    enTitle: 'Rename and batch actions',
    ruKeywords: ['переименовать', 'переименование', 'массовое', 'выделить', 'выделение'],
    enKeywords: ['rename', 'batch', 'select', 'multi'],
    ruBody:
        'Переименовать: меню у файла → «Переименовать». Для массовых '
        'действий: долгое нажатие включает режим выделения; тапайте файлы '
        'для добавления; панель снизу позволяет добавить все в избранное '
        'или удалить безопасно в корзину. Крестик отменяет выделение.',
    enBody:
        'Rename: the menu on a file → "Rename". Batch: long-press to enter '
        'selection mode; tap files to add them; the bottom bar lets you '
        'favorite or safely trash them all. The cross cancels the '
        'selection.',
  ),
  FizzyEntry(
    id: 'files_view',
    category: 'files',
    ruTitle: 'Просмотр файлов',
    enTitle: 'Viewing files',
    ruKeywords: ['открыть файл', 'просмотр файла', 'изображение', 'текст', 'картинка', 'не открывается файл'],
    enKeywords: ['open file', 'preview', 'image', 'text', 'viewer'],
    ruBody:
        'FZ Manager открывает изображения с зумом (растяните двумя '
        'пальцами), текстовые файлы (.txt, .md, .json, .log и др.) — '
        'в моно-редакторе с выделением текста (до 512 КБ). APK и архивы '
        'показывают размер и дату. Если файл не читается без root — '
        'используйте «Открыть как Root».',
    enBody:
        'FZ Manager opens images with pinch-zoom, and text files (.txt, '
        '.md, .json, .log etc.) in a monospace viewer with selectable text '
        '(up to 512 KB). APKs and archives show size and date. If a file '
        'is unreadable without root — use "Open as Root".',
  ),

  // ---------- ROOT ----------
  FizzyEntry(
    id: 'root_intro',
    category: 'root',
    ruTitle: 'Root: для чего это',
    enTitle: 'Root: what it is for',
    ruKeywords: ['root', 'су', 'суперюзер', 'системные файлы', 'ядро', 'kernel', 'раздел root', 'руут'],
    enKeywords: ['root', 'superuser', 'system files', 'kernel', 'partition'],
    ruBody:
        'Root — это доступ суперпользователя ко всему устройству: системным '
        'разделам (/system, /vendor, /data), ядру и файлам, которые Android '
        'обычно прячет. FZ Manager проверяет root безопасной командой '
        'su -c id — она ничего не меняет. Если root есть — в разделе Root '
        'открывается навигатор по системным файлам, а в разделе «Ядро» — '
        'быстрые ядровые команды.',
    enBody:
        'Root is superuser access to the whole device: system partitions '
        '(/system, /vendor, /data), the kernel and files Android normally '
        'hides. FZ Manager probes root with the safe su -c id command — it '
        'changes nothing. With root, the Root section becomes a navigator '
        'over system files and the Kernel section offers quick kernel '
        'commands.',
  ),
  FizzyEntry(
    id: 'root_browse',
    category: 'root',
    ruTitle: 'Навигация по системным файлам',
    enTitle: 'Navigating system files',
    ruKeywords: ['системные файлы', 'просмотр системных', 'build.prop', 'навигация root', 'system'],
    enKeywords: ['system files', 'view', 'build.prop', 'root browse'],
    ruBody:
        'В разделе Root файлы читаются через su: ls -la для папок, head -c '
        'для просмотра файлов (первые 64 КБ, только чтение). Так можно '
        'открыть /system/build.prop, логи ядра, конфигурации — без риска '
        'случайно что-то изменить. Запись в системные разделы из UI не '
        'выполняется: это защищает от окирпичивания.',
    enBody:
        'In the Root section files are read via su: ls -la for folders, '
        'head -c for file preview (first 64 KB, read-only). You can open '
        '/system/build.prop, kernel logs, configs — with zero risk of '
        'accidental modification. Writing to system partitions is not done '
        'from the UI: that keeps your device safe from bricking.',
    ruGuide: [
      'Root → «Проверить» (нужен подтверждённый root)',
      'Навигация: тап по папке, стрелка вверх — наверх',
      'Тап по файлу открывает просмотр содержимого',
      'Системные файлы открываются только для чтения',
    ],
    enGuide: [
      'Root → "Check" (verified root required)',
      'Navigate: tap a folder, the up-arrow goes up',
      'Tap a file to open its content viewer',
      'System files open read-only',
    ],
  ),
  FizzyEntry(
    id: 'root_shell',
    category: 'root',
    ruTitle: 'Открытие и запуск от имени Root',
    enTitle: 'Opening and running as Root',
    ruKeywords: ['от имени root', 'root-режим', 'запуск', 'sh', 'скрипт', 'выполнить', 'исполнить', 'shell', 'terminal'],
    enKeywords: ['as root', 'run', 'sh', 'script', 'execute', 'shell', 'terminal'],
    ruBody:
        'У каждого файла в «Файлах» есть пункт «Открыть как Root» — чтение '
        'через su для недоступных файлов. Для .sh доступен «Запустить '
        'через Root»: предупреждение → подтверждение → su -c sh path → '
        'вывод на экран + запись в журнал. Произвольные команды из UI не '
        'выполняются — только явно выбранный файл.',
    enBody:
        'Every file in Files has "Open as Root" — reading through su for '
        'inaccessible files. For .sh there is "Run via Root": warning → '
        'confirmation → su -c sh path → output on screen + audit entry. '
        'Arbitrary commands are not executed from the UI — only the '
        'explicitly chosen file.',
  ),
  FizzyEntry(
    id: 'kernel',
    category: 'root',
    ruTitle: 'Раздел «Ядро»',
    enTitle: 'The Kernel section',
    ruKeywords: ['ядро', 'kernel', 'proc', 'cpuinfo', 'meminfo', 'dmesg', 'uname', 'mounts'],
    enKeywords: ['kernel', 'proc', 'cpuinfo', 'meminfo', 'dmesg', 'uname', 'mounts'],
    ruBody:
        'Раздел «Ядро» (между Обзором и Root) — быстрый доступ к ядровой '
        'информации: версия ядра (uname -a), CPU, память, монтирования, '
        'dmesg, загрузочные параметры. Работает через root; без root — '
        'объясняет, как его проверить. Все выводы логируются.',
    enBody:
        'The Kernel section (between Insights and Root) offers quick '
        'kernel-level info: version (uname -a), CPU, memory, mounts, '
        'dmesg, boot params. It works over root; without it the section '
        'explains how to verify root. All outputs are logged.',
  ),
  FizzyEntry(
    id: 'root_safety',
    category: 'root',
    ruTitle: 'Безопасность Root',
    enTitle: 'Root safety model',
    ruKeywords: ['безопасность root', 'опасно', 'риск', 'окирпичить', 'предупреждение root'],
    enKeywords: ['root safety', 'danger', 'risk', 'brick', 'warning'],
    ruBody:
        'Правила простые: (1) проверка — только su -c id; (2) чтение '
        'системных файлов — да, запись — нет; (3) запуск .sh — только с '
        'вашего явного подтверждения и только для выбранного файла; (4) '
        'каждое root-действие пишется в журнал аудита.',
    enBody:
        'The rules are simple: (1) probing uses only su -c id; (2) reading '
        'system files — yes, writing — no; (3) running .sh requires your '
        'explicit confirmation and only for the chosen file; (4) every '
        'root action lands in the audit log.',
  ),

  // ---------- AI BRAIN ----------
  FizzyEntry(
    id: 'ai_intro',
    category: 'ai',
    ruTitle: 'ИИ Мозг: введение',
    enTitle: 'AI Brain: introduction',
    ruKeywords: ['ии', 'мозг', 'агент', 'ии мозг', 'зачем ии', 'искусственный интеллект', 'ai', 'brain'],
    enKeywords: ['ai', 'brain', 'agent', 'assistant ai', 'ai brain'],
    ruBody:
        'ИИ Мозг — опциональный полноценный агент внутри FZ Manager. Вы '
        'подключаете своего провайдера (URL, модель, API-ключ) — FZ Manager '
        'не навязывает облако и не отправляет данные неизвестно куда. '
        'Агент работает циклом: понимает задачу → вызывает инструменты → '
        'видит результат → продолжает, пока задача не решена. По '
        'умолчанию выключен. Включение: ИИ Мозг → переключатель сверху.',
    enBody:
        'AI Brain is an optional full agent inside FZ Manager. You connect '
        'your own provider (URL, model, API key) — FZ Manager forces no '
        'cloud and sends data only where you point it. The agent runs a '
        'loop: understand the task → call tools → observe results → '
        'continue until done. It is off by default. Enable: AI Brain → '
        'the switch on top.',
  ),
  FizzyEntry(
    id: 'ai_chats',
    category: 'ai',
    ruTitle: 'Чаты ИИ Мозга',
    enTitle: 'AI Brain chats',
    ruKeywords: ['чат', 'чаты', 'история', 'контекст', 'новый чат', 'переименовать чат', 'delete chat'],
    enKeywords: ['chat', 'chats', 'history', 'context', 'new chat'],
    ruBody:
        'ИИ Мозг ведёт отдельные чаты, как мессенджер: кнопка «Новый» '
        'создаёт чат, заголовок формируется из первой задачи, история и '
        'контекст сохраняются локально. В каждом запросе агент получает '
        'последние 40 сообщений чата — он помнит, что вы уже просили. '
        'Чат можно удалить в любой момент.',
    enBody:
        'AI Brain keeps separate chats like a messenger: "New" creates a '
        'chat, the title comes from the first task, and history and '
        'context are saved locally. Every request sends the last 40 chat '
        'messages — the agent remembers what you asked. A chat can be '
        'deleted any time.',
  ),
  FizzyEntry(
    id: 'ai_tools',
    category: 'ai',
    ruTitle: 'Инструменты агента',
    enTitle: 'Agent tools',
    ruKeywords: ['инструменты', 'инструмент', 'какие инструменты', 'tools', 'write', 'read', 'copy', 'search'],
    enKeywords: ['tools', 'write', 'read', 'copy', 'search', 'capabilities'],
    ruBody:
        'Полный набор: list (список папки), read (чтение до 100 КБ), write '
        '(запись файла), write_append (дозапись — так агент пишет '
        'неограниченно длинные файлы по частям), search (поиск по имени), '
        'copy (копирование файлов и папок), move (перемещение), rename, '
        'delete (только с отдельного разрешения), configure (настройки FZ '
        'Manager: тема, язык, акцент, плотность), list_tools, create_tool '
        '(агент создаёт свои инструменты из базовых операций).',
    enBody:
        'Full set: list (folder listing), read (up to 100 KB), write '
        '(write a file), write_append (append — how the agent writes '
        'arbitrarily long files in chunks), search (by name), copy (files '
        'and folders), move, rename, delete (separate opt-in only), '
        'configure (FZ Manager settings: theme, language, accent, '
        'density), list_tools, create_tool (the agent creates its own '
        'tools from basic operations).',
  ),
  FizzyEntry(
    id: 'ai_create_tool',
    category: 'ai',
    ruTitle: 'Самосоздание инструментов',
    enTitle: 'Self-creating tools',
    ruKeywords: ['создать инструмент', 'create_tool', 'новые инструменты', 'создаёт инструменты', 'скрипт агента'],
    enKeywords: ['create tool', 'create_tool', 'new tools', 'script'],
    ruBody:
        'Уникальная возможность: агент может определять собственные '
        'инструменты через create_tool. Задаётся имя, описание и сценарий '
        '— конвейер базовых операций, например "list:/sdcard|write:/sdcard/out.txt". '
        'Новый инструмент появляется в арсенале агента и вызывается как '
        'обычный. Он наследует те же разрешения — агент не может создать '
        'себе инструмент, обходящий ваши ограничения.',
    enBody:
        'A unique capability: the agent can define its own tools via '
        'create_tool. You give a name, description and script — a pipeline '
        'of basic operations, e.g. "list:/sdcard|write:/sdcard/out.txt". '
        'The new tool joins the arsenal and is callable like any other. It '
        'inherits the same permissions — the agent cannot craft itself a '
        'tool that bypasses your restrictions.',
  ),
  FizzyEntry(
    id: 'ai_security',
    category: 'ai',
    ruTitle: 'Безопасность ИИ Мозга',
    enTitle: 'AI Brain security',
    ruKeywords: ['безопасность ии', 'опасно ли ии', 'может ли ии удалить', 'разрешения ии', 'подтверждение ии'],
    enKeywords: ['ai safety', 'permissions', 'confirm', 'dangerous', 'delete'],
    ruBody:
        'Иерархия защиты: (1) агент выключен по умолчанию; (2) инструменты '
        'включаются по одному; (3) move/copy/delete/configure требуют '
        'подтверждения на каждое действие (диалог с деталями); (4) delete '
        'нуждается в двух разрешениях: общий инструмент + отдельный '
        'opt-in; (5) API-ключ шифруется Android Keystore; (6) произвольное '
        'выполнение кода заблокировано — только инструменты; (7) каждое '
        'действие в журнале аудита.',
    enBody:
        'Defense in depth: (1) the agent is off by default; (2) tools are '
        'enabled one by one; (3) move/copy/delete/configure require '
        'per-action confirmation dialogs with details; (4) delete needs two '
        'permissions: the tool itself + a separate opt-in; (5) the API key '
        'is encrypted in the Android Keystore; (6) arbitrary code '
        'execution is blocked — tools only; (7) every action is audited.',
  ),
  FizzyEntry(
    id: 'ai_provider',
    category: 'ai',
    ruTitle: 'Подключение провайдера',
    enTitle: 'Connecting a provider',
    ruKeywords: ['провайдер', 'url', 'модель', 'api ключ', 'подключить ии', 'openai', 'настроить агента', 'ключ не сохраняется', '401'],
    enKeywords: ['provider', 'url', 'model', 'api key', 'connect', 'openai', 'setup', '401', 'key not saved'],
    ruBody:
        'ИИ Мозг → карточка «Ваш провайдер»: URL (любой OpenAI-совместимый '
        'endpoint, например https://api.openai.com/v1), модель (например '
        'gpt-4o-mini), API-ключ. Сохраните — ключ шифруется Android '
        'Keystore и поле очищается (это нормально: ключ уже в сейфе). '
        'Ошибки 401: проверьте, что нажали «Сохранить», URL и модель '
        'корректны, а у ключа есть доступ к модели.',
    enBody:
        'AI Brain → the "Your provider" card: URL (any OpenAI-compatible '
        'endpoint, e.g. https://api.openai.com/v1), model (e.g. '
        'gpt-4o-mini), API key. Save it — the key is encrypted with '
        'Android Keystore and the field clears (that is fine: the key is '
        'in the vault). 401 errors: make sure you pressed "Save", the URL '
        'and model are correct, and the key can access the model.',
    ruGuide: [
      'ИИ Мозг → введите URL провайдера',
      'Введите модель',
      'Вставьте API-ключ → «Сохранить»',
      'Включите переключатель ИИ Мозга',
      'Создайте чат и напишите задачу',
    ],
    enGuide: [
      'AI Brain → enter the provider URL',
      'Enter the model',
      'Paste the API key → "Save"',
      'Enable the AI Brain switch',
      'Create a chat and type a task',
    ],
  ),
  FizzyEntry(
    id: 'ai_examples',
    category: 'ai',
    ruTitle: 'Примеры задач для агента',
    enTitle: 'Example tasks for the agent',
    ruKeywords: ['примеры', 'что попросить', 'задачи агенту', 'идеи'],
    enKeywords: ['examples', 'tasks', 'ideas', 'prompts'],
    ruBody:
        'Попробуйте: «Найди все .txt в Download и покажи список»; «Создай '
        'папку Отчёты с файлом readme.md внутри»; «Собери сводку: сколько '
        'файлов в каждой папке верхнего уровня»; «Переименуй все IMG_ в '
        'Photo_ в папке Camera» (подтвердите перемещения); «Сделай '
        'инструмент cleanup для поиска пустых папок». Чем конкретнее '
        'задача и путь — тем точнее результат.',
    enBody:
        'Try: "Find all .txt in Download and list them"; "Create a Reports '
        'folder with a readme.md inside"; "Summarize how many files each '
        'top-level folder has"; "Rename all IMG_ to Photo_ in Camera" '
        '(confirm the moves); "Make a cleanup tool that finds empty '
        'folders". The more specific the task and path, the better.',
  ),

  // ---------- STORAGE / PERMISSIONS ----------
  FizzyEntry(
    id: 'insights',
    category: 'storage',
    ruTitle: 'Обзор хранилища',
    enTitle: 'Storage insights',
    ruKeywords: ['обзор', 'хранилище', 'анализ', 'место', 'insights', 'большой файл', 'дубликат'],
    enKeywords: ['insights', 'storage', 'analyze', 'space', 'large files', 'duplicates'],
    ruBody:
        'Раздел «Обзор» — панель здоровья хранилища: сканер больших файлов '
        '(>50 МБ, топ-50), корзина с восстановлением, недавние папки, '
        'закладки. Сканеры категорий и дубликатов — каркасы: функция '
        'честно помечена как развивающаяся.',
    enBody:
        'Insights is your storage health dashboard: a large files scanner '
        '(>50 MB, top 50), trash with restore, recent folders and '
        'bookmarks. The category and duplicates scanners are scaffolds — '
        'honestly labeled as work-in-progress.',
  ),
  FizzyEntry(
    id: 'permissions',
    category: 'storage',
    ruTitle: 'Разрешения и «Все файлы»',
    enTitle: 'Permissions and All-files access',
    ruKeywords: ['разрешение', 'разрешения', 'все файлы', 'доступ', 'manage external storage', 'не видит файлы', 'уведомления'],
    enKeywords: ['permission', 'all files', 'access', 'manage external storage', 'cannot see files', 'notification'],
    ruBody:
        'FZ Manager запрашивает разрешения сам. Медиа и уведомления — '
        'стандартным системным диалогом. «Все файлы» (Android 11+) '
        'выдаётся только на системной странице — приложение открывает её '
        'само; включите тумблер и вернитесь, статус перепроверится. Без '
        'него доступны только медиа и общие папки.',
    enBody:
        'FZ Manager requests permissions on its own. Media and '
        'notifications use the standard system dialog. "All files" '
        '(Android 11+) is granted only on a system page — the app opens it '
        'for you; flip the toggle and come back, the status re-checks. '
        'Without it only media and shared folders are visible.',
  ),

  // ---------- SETTINGS / EXTRAS ----------
  FizzyEntry(
    id: 'customization',
    category: 'settings',
    ruTitle: 'Кастомизация интерфейса',
    enTitle: 'Interface customization',
    ruKeywords: ['кастомизация', 'тема', 'цвет', 'акцент', 'плотность', 'оформление', 'тёмная', 'докбар'],
    enKeywords: ['customization', 'theme', 'color', 'accent', 'density', 'dark', 'dock'],
    ruBody:
        'Настройки → Кастомизация: тёмная/светлая тема; 6 акцентных цветов '
        '(индиго, фиолетовый, изумрудный, оранжевый, розовый, золотой) с '
        'мгновенным применением; ползунок плотности интерфейса; язык; '
        'сетка по умолчанию; скрытые файлы. Внизу — liquid-glass докбар. '
        'Все изменения сохраняются навсегда.',
    enBody:
        'Settings → Customization: dark/light theme; 6 accent colors '
        '(indigo, violet, emerald, orange, pink, gold) applied instantly; '
        'a UI density slider; language; default grid; hidden files. A '
        'liquid-glass dock sits at the bottom. Everything persists.',
  ),
  FizzyEntry(
    id: 'music_island',
    category: 'settings',
    ruTitle: 'Музыкальный островок',
    enTitle: 'Music island effect',
    ruKeywords: ['музык', 'островок', 'остров', 'dynamic island', 'уведомление музык', 'island'],
    enKeywords: ['music', 'island', 'dynamic island', 'now playing', 'notification'],
    ruBody:
        'Настройки Физзи → «Музыкальный островок»: при включённых '
        'уведомлениях FZ Manager незаметно следит за системным аудио '
        '(AudioManager.isMusicActive) и показывает живое медиа-уведомление '
        '«♪ Музыка играет». На устройствах с околостоличными фичами '
        '(Dynamic Island, Mi Pill, Edge Lightning) оно появляется как '
        'анимированный островок с нотами. Ничего не воспроизводится и не '
        'записывается.',
    enBody:
        'Fizzy settings → "Music island": with notifications enabled FZ '
        'Manager quietly watches system audio (AudioManager.isMusicActive) '
        'and shows a live media notification "♪ Music playing". On '
        'devices with island-like features (Dynamic Island, Mi Pill, Edge '
        'Lightning) it appears as an animated note island. Nothing is '
        'played or recorded.',
  ),
  FizzyEntry(
    id: 'local_model',
    category: 'ai',
    ruTitle: 'Локальная мини-модель Физзи',
    enTitle: 'Fizzy local mini model',
    ruKeywords: ['локальная модель', 'скачать модель', 'gguf', 'оффлайн ии', 'smollm', 'без интернета', 'модель для телефона'],
    enKeywords: ['local model', 'download model', 'gguf', 'offline ai', 'smollm', 'without internet'],
    ruBody:
        'Настройки Физзи могут скачать самую лёгкую из практичных ИИ-'
        'моделей SmolLM2-135M (GGUF, квант Q4_K_M ≈ 130 МБ) — она '
        'разработана для телефонов и почти ничего не грузит. Кнопка '
        '«Скачать модель» кладёт файл в папку приложения, системный '
        'промпт Физзи уже настроен. Для автономного запуска используйте '
        'llama.cpp-клиент (Termux/LlamaPlay), указав путь к файлу, или '
        'онлайн-режим Физзи через вашего провайдера.',
    enBody:
        'Fizzy settings can download the lightest practical AI model — '
        'SmolLM2-135M (GGUF, Q4_K_M ≈ 130 MB) — built for phones and '
        'barely loads them. The "Download model" button saves it into the '
        'app folder, and Fizzy system prompt is ready. To run it locally, '
        'use a llama.cpp client (Termux/LlamaPlay) with the file path, or '
        'Fizzy online mode through your provider.',
    ruGuide: [
      'Физзи → кнопка «Скачать мини-модель»',
      'Дождитесь окончания загрузки (прогресс-бар)',
      'Путь к модели откроется в диалоге',
      'Онлайн-Физзи работает через вашего провайдера',
    ],
    enGuide: [
      'Fizzy → "Download mini model" button',
      'Wait for the download (progress bar)',
      'The model path is shown in the dialog',
      'Online Fizzy works through your provider',
    ],
  ),
  FizzyEntry(
    id: 'fizzy_context',
    category: 'app',
    ruTitle: 'Контекст Физзи',
    enTitle: 'Fizzy context',
    ruKeywords: ['контекст', 'помнишь', 'спросить ещё', 'а как это включить', 'подробнее'],
    enKeywords: ['context', 'remember', 'follow up', 'more details'],
    ruBody:
        'Физзи помнит диалог: если последний ответ касался конкретной '
        'функции, а вы спрашиваете «как это включить?» или «подробнее» — '
        'он продолжит ту же тему и покажет пошаговый гайд. В онлайне '
        'контекст передаётся модели (последние 12 реплик), поэтому Физзи '
        'ведёт осмысленный многошаговый разговор.',
    enBody:
        'Fizzy remembers the dialogue: if the last answer was about a '
        'specific feature and you ask "how to enable it?" or "more '
        'details", it continues the same topic and shows the step-by-step '
        'guide. Online mode passes context (last 12 turns), so Fizzy '
        'holds a meaningful multi-step conversation.',
  ),
  FizzyEntry(
    id: 'app_about',
    category: 'app',
    ruTitle: 'Что такое FZ Manager',
    enTitle: 'What FZ Manager is',
    ruKeywords: ['что такое', 'о приложении', 'fz manager', 'менеджер', 'описание', 'версия', 'зачем'],
    enKeywords: ['about', 'what is', 'fz manager', 'description', 'version'],
    ruBody:
        'FZ Manager — файловый менеджер нового поколения: быстрый локальный '
        'браузер файлов с умными путями, безопасный Root и ядро, '
        'подключаемый ИИ-агент с чатами и помощник Физзи — всё в одном. '
        'Философия: ваше устройство — ваши правила. Никакой телеметрии, '
        'никакой рекламы, никаких скрытых сетевых вызовов.',
    enBody:
        'FZ Manager is a next-generation file manager: a fast local file '
        'browser with smart paths, safe Root and Kernel sections, a '
        'pluggable AI agent with chats and the Fizzy assistant — all in '
        'one. Philosophy: your device, your rules. No telemetry, no ads, '
        'no hidden network calls.',
  ),
  FizzyEntry(
    id: 'app_updates',
    category: 'app',
    ruTitle: 'Обновления и релизы',
    enTitle: 'Updates and releases',
    ruKeywords: ['обновление', 'версия', 'релиз', 'apk', 'обновить', 'где скачать'],
    enKeywords: ['update', 'version', 'release', 'apk', 'download'],
    ruBody:
        'Новые версии собираются GitHub Actions и публикуются в Releases: '
        'подписанный FZ Manager APK + SHA256. Перед установкой обновления '
        'удалите старую версию, если сменился ключ подписи. Список '
        'изменений — в описании релиза.',
    enBody:
        'New versions are built by GitHub Actions and published in '
        'Releases: a signed FZ Manager APK + SHA256. Remove the old '
        'version before updating if the signing key changed. Changelogs '
        'live in the release notes.',
  ),
  FizzyEntry(
    id: 'settings_profile',
    category: 'settings',
    ruTitle: 'Профиль и приватность',
    enTitle: 'Profile and privacy',
    ruKeywords: ['профиль', 'имя', 'фамилия', 'данные', 'конфиденциальность', 'где хранятся', 'приватность'],
    enKeywords: ['profile', 'name', 'data', 'privacy', 'where stored'],
    ruBody:
        'Имя и фамилия из онбординга хранятся только на устройстве и '
        'нужны для персональных приветствий. FZ Manager не имеет '
        'аналитики и серверов — всё локально. Единственный сетевой трафик '
        '— запросы к вашему ИИ-провайдеру, только когда ИИ Мозг или '
        'онлайн-Физзи включены.',
    enBody:
        'The name and surname from onboarding live only on your device and '
        'power personalized greetings. FZ Manager ships no analytics or '
        'servers — everything is local. The only network traffic goes to '
        'your own AI provider, and only while AI Brain or online Fizzy is '
        'enabled.',
  ),
  FizzyEntry(
    id: 'settings_audit',
    category: 'settings',
    ruTitle: 'Журнал аудита',
    enTitle: 'Audit log',
    ruKeywords: ['журнал', 'аудит', 'лог', 'история действий', 'что делал ии'],
    enKeywords: ['audit', 'log', 'history', 'actions'],
    ruBody:
        'Каждое значимое действие — онбординг, удаление, root-проверка, '
        'запуск скрипта, операции агента — попадает в журнал с меткой '
        'времени. Журнал виден в ИИ Мозге в карточке «Разрешения и '
        'журнал». Это чёрный ящик: если что-то пошло не так — начните '
        'поиск отсюда.',
    enBody:
        'Every meaningful action — onboarding, deletion, root probing, '
        'script runs, agent operations — lands in the log with a '
        'timestamp. The log is in AI Brain inside the "permissions and '
        'log" card. Think of it as a black box: when something goes wrong, '
        'start here.',
  ),
];

const _kFaq = <FizzyEntry>[
  FizzyEntry(
    id: 'q_no_files',
    ruTitle: 'Не видно файлов / папка пустая',
    enTitle: 'Files not visible / folder empty',
    ruKeywords: ['не видит', 'пусто', 'пустая папка', 'не открывается', 'ошибка доступа'],
    enKeywords: ['not visible', 'empty', 'cannot open', 'access error', 'no files'],
    ruBody:
        'Если папка пустая или ошибка доступа: (1) проверьте разрешение '
        '«Все файлы» — Настройки → Разрешения; (2) возможно, файлы '
        'скрытые — включите показ скрытых; (3) системные папки без root '
        'недоступны — это нормально; (4) кнопка «Открыть хранилище» на '
        'экране ошибки вернёт в доступный корень.',
    enBody:
        'If a folder is empty or access fails: (1) check the All-files '
        'permission — Settings → Permissions; (2) files may be hidden — '
        'enable hidden files; (3) system folders need root — that is '
        'normal; (4) "Open storage" on the error screen returns you to an '
        'accessible root.',
  ),
  FizzyEntry(
    id: 'q_path_fix',
    ruTitle: 'Поле пути исправляет не то',
    enTitle: 'Path field fixes the wrong thing',
    ruKeywords: ['исправляет', 'не тот путь', 'неправильно исправляет', 'подсказки пути'],
    enKeywords: ['fixes wrong', 'wrong path', 'suggestions wrong'],
    ruBody:
        'Автоисправление срабатывает по расстоянию Левенштейна ≤ 2 и '
        'только для последнего сегмента. Если предложенное не подходит — '
        'просто игнорируйте чипы и продолжайте печатать: подсказки никогда '
        'не вмешиваются в текст сами, всё применяется только по вашему '
        'тапу.',
    enBody:
        'Auto-fix uses Levenshtein distance ≤ 2 and only for the last '
        'segment. If the suggestion is wrong — ignore the chips and keep '
        'typing: suggestions never touch your text; everything applies '
        'only on your tap.',
  ),
  FizzyEntry(
    id: 'q_ai_off',
    ruTitle: 'ИИ Мозг не отвечает / 401',
    enTitle: 'AI Brain fails / 401',
    ruKeywords: ['ии не работает', '401', 'ошибка ии', 'агент молчит', 'ключ не сохраняется', 'unauthorized'],
    enKeywords: ['ai not working', '401', 'ai error', 'agent silent', 'key not saved', 'unauthorized'],
    ruBody:
        'Ошибка 401 = неверный API-ключ. Проверьте: (1) ключ введён и '
        'нажато «Сохранить» (после сохранения поле очищается — ключ уже в '
        'Keystore, так и должно быть); (2) URL — базовый адрес без '
        '/chat/completions на конце (он добавится сам); (3) модель '
        'доступна ключу; (4) у ключа есть кредиты. Чат показывает полный '
        'текст ошибки — скиньте его мне или разработчику.',
    enBody:
        '401 = invalid API key. Check: (1) the key is entered and "Save" '
        'was pressed (the field clears after saving — the key is already '
        'in the Keystore, that is expected); (2) the URL is a base address '
        'without a trailing /chat/completions (it is appended '
        'automatically); (3) the model is accessible to the key; (4) the '
        'key has credits. Chat shows the full error text.',
  ),
  FizzyEntry(
    id: 'q_root_absent',
    ruTitle: 'Root не обнаружен',
    enTitle: 'Root not found',
    ruKeywords: ['root нет', 'root не обнаружен', 'нет рута'],
    enKeywords: ['no root', 'root not found'],
    ruBody:
        '«Root не обнаружен» означает, что su -c id не вернула uid=0. '
        'Причины: устройство не рутировано; Magisk/Superuser не выдал '
        'разрешение FZ Manager — проверьте в его интерфейсе; su есть, но '
        'не в PATH. Всё остальное работает без root.',
    enBody:
        '"Root not found" means su -c id did not return uid=0. Causes: the '
        'device is not rooted; Magisk/Superuser did not grant FZ Manager — '
        'check its interface; su exists but is not on PATH. Everything '
        'else works without root.',
  ),
  FizzyEntry(
    id: 'q_sh_run',
    ruTitle: 'Запуск .sh',
    enTitle: 'Running .sh',
    ruKeywords: ['запустить sh', 'скрипт без root', 'выполнить скрипт', 'run sh'],
    enKeywords: ['run sh', 'script without root', 'execute script'],
    ruBody:
        'FZ Manager запускает .sh через su -c sh — то есть нужен root. '
        'Без root приложения Android не могут исполнять файлы из общего '
        'хранилища (noexec). Просмотр .sh доступен всегда: «Открыть как '
        'Root» или обычный просмотр текстовика.',
    enBody:
        'FZ Manager runs .sh via su -c sh — so it needs root. Without '
        'root, Android apps cannot execute files from shared storage '
        '(noexec). Viewing .sh always works: "Open as Root" or the plain '
        'text viewer.',
  ),
];

const _kTips = <String, String>{
  'files': 'Совет: долгое нажатие — выделение; меню у файла скрывает '
      'переименование, избранное, закладку, корзину и «Открыть как Root».',
  'root': 'Совет: каждое root-действие требует подтверждения и попадает '
      'в журнал аудита.',
  'ai': 'Совет: начните с read-only инструментов (list, read, search) — '
      'убедитесь в качестве агента, прежде чем включать изменяющие.',
  'insights': 'Совет: сканер больших файлов находит «тяжеловесов» >50 МБ — '
      'начинайте очистку с верха списка.',
  'settings': 'Совет: акцентный цвет применяется мгновенно — попробуйте '
      'изумрудный или золотой.',
  'kernel': 'Совет: «Быстрые команды» в Ядре — самый безопасный способ '
      'посмотреть версию ядра и память.',
  'fizzy': 'Совет: Физзи помнит контекст — спрашивайте «подробнее» и '
      '«как это включить».',
};

const _kTipsEn = <String, String>{
  'files': 'Tip: long-press selects; the file menu holds rename, favorite, '
      'bookmark, trash and "Open as Root".',
  'root': 'Tip: every root action needs confirmation and lands in the '
      'audit log.',
  'ai': 'Tip: start with read-only tools (list, read, search) — gauge the '
      'agent before enabling mutating ones.',
  'insights': 'Tip: the large-file scanner finds >50 MB heavyweights — '
      'start cleaning from the top.',
  'settings': 'Tip: the accent color applies instantly — try emerald or '
      'gold.',
  'kernel': 'Tip: Kernel quick commands are the safest way to check '
      'kernel version and memory.',
  'fizzy': 'Tip: Fizzy keeps context — ask "more details" or "how to '
      'enable it".',
};

const _kSmalltalkRu = <String, String>{
  'привет': 'Привет! Я Физзи. Спроси про файлы, умные пути, Root, Ядро, ИИ Мозг, корзину или настройки.',
  'здравствуй': 'Приветствую! Чем помочь в FZ Manager сегодня?',
  'хай': 'Хэй! Готов рассказать про любую фичу.',
  'спасибо': 'Всегда пожалуйста! Если что — я рядом.',
  'как дела': 'Работаю без сбоев, база знаний загружена. Чем займёмся?',
  'кто ты': 'Я Физзи — встроенный помощник FZ Manager. Знаю все функции, безопасность, Root, Ядро и ИИ Мозг.',
  'помощь': 'Я могу: объяснить любую функцию, показать пошаговый гайд, подсказать решение. Спросите обычными словами.',
  'пока': 'До встречи! FZ Manager и я всегда на связи.',
};

const _kSmalltalkEn = <String, String>{
  'hi': 'Hi! I am Fizzy. Ask about files, smart paths, Root, Kernel, the AI Brain, trash or settings.',
  'hello': 'Hello! How can I help with FZ Manager today?',
  'hey': 'Hey! Ready to explain any feature.',
  'thanks': 'You are welcome! I am here whenever you need me.',
  'thank': 'You are welcome! I am here whenever you need me.',
  'how are you': 'Running smooth, knowledge base loaded. What shall we do?',
  'who are you': 'I am Fizzy — the built-in FZ Manager assistant. I know every feature, Root, Kernel and the AI Brain.',
  'help': 'I can: explain any feature, show a step-by-step guide, suggest a fix. Ask in plain words.',
  'bye': 'See you! FZ Manager and I are always around.',
};

const _kFollowupWords = <String>[
  'подробнее', 'детальнее', 'как это включить', 'как включить', 'как настроить',
  'где это', 'где найти', 'расскажи еще', 'расскажи ещё', 'more', 'details',
  'how to enable', 'where',
];

class Fizzy {
  final bool russian;
  FizzyEntry? _lastEntry;
  final List<List<String>> history = [];

  Fizzy({required this.russian});

  String get greeting => russian
      ? 'Привет! Я Физзи — твой помощник в FZ Manager. Могу объяснить любую '
          'функцию: файлы, умный поиск путей, Root, Ядро, ИИ Мозг, корзину, '
          'музыкальный островок, настройки. Просто спроси!'
      : 'Hi! I am Fizzy, your FZ Manager assistant. I can explain any '
          'feature: files, smart paths, Root, Kernel, the AI Brain, trash, '
          'the music island, settings. Just ask!';

  List<FizzyEntry> get topics => _kTopics;
  List<FizzyEntry> get faq => _kFaq;

  String tipFor(String screen) =>
      (russian ? _kTips : _kTipsEn)[screen] ?? greeting;

  /// Adds a user/assistant turn to the session context.
  void rememberTurn(String userText, String answerText) {
    history.add(['user', userText]);
    history.add(['assistant', answerText]);
    if (history.length > 24) {
      history.removeRange(0, history.length - 24);
    }
  }

  /// Grounded context for online mode (recent turns as plain text).
  List<List<String>> get context => history;

  String ground(String question) {
    final q = question.toLowerCase();
    final scored = <(int, FizzyEntry)>[];
    for (final e in [..._kFaq, ..._kTopics]) {
      var score = 0;
      for (final w in (russian ? e.ruKeywords : e.enKeywords)) {
        if (q.contains(w)) score += w.length;
      }
      if (score > 0) scored.add((score, e));
    }
    scored.sort((a, b) => b.$1.compareTo(a.$1));
    final picked = scored.take(3).map((s) => s.$2);
    if (picked.isEmpty) {
      return _kTopics.map((t) => '- ${t.ruTitle}: ${t.ruBody}').join('\n');
    }
    final parts = picked.map((e) {
      final body = russian ? e.ruBody : e.enBody;
      final title = russian ? e.ruTitle : e.enTitle;
      return '# $title\n$body';
    }).toList();
    return parts.join('\n\n');
  }

  FizzyAnswer answer(String question) {
    final q = question.toLowerCase().trim();

    // 1) Follow-up on the previous topic (context awareness).
    if (_lastEntry != null &&
        _kFollowupWords.any((w) => q.contains(w)) &&
        q.length <= 40) {
      return FizzyAnswer(
        text: russian ? _lastEntry!.ruBody : _lastEntry!.enBody,
        entry: _lastEntry,
        guide: russian ? _lastEntry!.ruGuide : _lastEntry!.enGuide,
        isFollowup: true,
      );
    }

    // 2) Smalltalk.
    final smalltalk = russian ? _kSmalltalkRu : _kSmalltalkEn;
    for (final entry in smalltalk.entries) {
      if (q.contains(entry.key)) {
        return FizzyAnswer(text: entry.value, entry: null);
      }
    }

    // 3) FAQ and topics: score by keyword hits (longer keywords weigh more).
    FizzyEntry? best;
    var bestScore = 0;
    for (final e in [..._kFaq, ..._kTopics]) {
      var score = 0;
      for (final w in (russian ? e.ruKeywords : e.enKeywords)) {
        if (q.contains(w)) score += w.length;
      }
      if (score > bestScore) {
        bestScore = score;
        best = e;
      }
    }
    if (best != null && bestScore >= 3) {
      _lastEntry = best;
      return FizzyAnswer(
        text: russian ? best.ruBody : best.enBody,
        entry: best,
        guide: russian ? best.ruGuide : best.enGuide,
      );
    }

    // 4) Unknown — offer categories.
    return FizzyAnswer(
      text: russian
          ? 'Хм, точного ответа у меня пока нет. Спроси про: файлы, умный '
              'поиск путей, корзину, Root, Ядро, запуск .sh, ИИ Мозг, '
              'чаты, инструменты агента, музыкальный островок, разрешения, '
              'кастомизацию или журнал аудита.'
          : 'Hmm, no exact answer yet. Ask about: files, smart paths, '
              'trash, Root, Kernel, running .sh, AI Brain, chats, agent '
              'tools, music island, permissions, customization or the '
              'audit log.',
      entry: null,
    );
  }
}

class FizzyAnswer {
  final String text;
  final FizzyEntry? entry;
  final List<String> guide;
  final bool isFollowup;
  const FizzyAnswer({
    required this.text,
    this.entry,
    this.guide = const [],
    this.isFollowup = false,
  });
}
