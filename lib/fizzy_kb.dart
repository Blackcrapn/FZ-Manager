/// Fizzy — the built-in assistant of FZ Manager.
///
/// A large curated knowledge base with intent classification:
/// topics, step-by-step guides, FAQ, contextual tips, daily tips
/// and smalltalk — all bilingual (RU/EN).
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
        'The Files section is the heart of FZ Manager. At the top is the smart '
        'path field: it validates every part as you type and offers fixes. '
        'Below it is instant search within the current folder. Files appear '
        'as a list or grid. Long-press to select items for batch actions.',
    ruGuide: [
      'Откройте раздел «Файлы»',
      'Введите путь вверху или нажмите ⬆ для перехода к родительской папке',
      'Переключите вид список/сетка кнопкой справа вверху',
      'Сортировка — меню ⋮ (имя, дата, размер)',
    ],
    enGuide: [
      'Open the Files section',
      'Type a path on top or tap ⬆ to go to the parent folder',
      'Toggle list/grid with the button in the top right',
      'Sorting lives in the ⋮ menu (name, date, size)',
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
        'Файлы, начинающиеся с точки (например .nomedia), по умолчанию скрыты. '
        'Включить их показ: Настройки → «Показывать скрытые файлы». '
        'Скрытые системные файлы важны для продвинутых задач — но их легко '
        'случайно удалить, поэтому будьте внимательны.',
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
    ruKeywords: ['путь', 'пути', 'умный', 'автодополнение', 'исправление пути', 'lokal', 'не существует'],
    enKeywords: ['path', 'smart', 'autocomplete', 'typo', 'lokal', 'correction'],
    ruBody:
        'Поле пути — с IQ. На каждую букву FZ Manager находит самый длинный '
        'существующий префикс пути и подсказывает реальные папки, которые '
        'можно продолжить (чипы под полем). Если сегмента нет — система ищет '
        'похожие через расстояние Левенштейна и предлагает замену: /data/lokal '
        '→ /data/local. Кнопка «Исправить» применяет замену одним касанием.',
    enBody:
        'The path field has an IQ. With every character FZ Manager finds the '
        'longest existing prefix and suggests real folders to continue with '
        '(chips under the field). If a segment does not exist, the system '
        'finds similar names via Levenshtein distance and offers a fix: '
        '/data/lokal → /data/local. The "Fix" chip applies it in one tap.',
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
    ruKeywords: ['корзина', 'удалить', 'удаление', 'восстановить', 'восстановление', 'fz_trash', '.fz_trash'],
    enKeywords: ['trash', 'delete', 'restore', 'recycle', 'fz_trash'],
    ruBody:
        'FZ Manager никогда не удаляет сразу. «Удалить» переносит файл в '
        'специальную папку .fz_trash в корне хранилища, добавляя метку '
        'времени, чтобы не было конфликтов имён. Обзор → Корзина: элементы '
        'можно восстановить (кнопка ↩) — файл вернётся в исходную папку. '
        'Ничего не теряется, пока вы сами не очистите корзину.',
    enBody:
        'FZ Manager never deletes instantly. "Delete" moves the file to the '
        'special .fz_trash folder at the storage root with a timestamp '
        'prefix to avoid name clashes. Insights → Trash: restore any item '
        'with the ↩ button — it returns to its original folder. Nothing is '
        'lost until you empty the trash yourself.',
    ruGuide: [
      'Долгое нажатие → «В корзину» (или меню ⋮ у файла)',
      'Обзор → Корзина — список удалённого',
      'Кнопка ↩ возвращает файл на место',
    ],
    enGuide: [
      'Long-press → "Move to trash" (or the ⋮ menu on a file)',
      'Insights → Trash lists removed items',
      'The ↩ button restores the file',
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
        'Три вида быстрого доступа. Избранное (★) — конкретные файлы и папки; '
        'доступ из шапки раздела «Файлы». Закладки путей — быстрые прыжки к '
        'каталогам, видны в «Обзоре». Недавние — 15 последних открытых '
        'папок, запоминается автоматически. Всё сохраняется между запусками.',
    enBody:
        'Three kinds of quick access. Favorites (★) — specific files and '
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
        'Переименовать: меню ⋮ у файла → «Переименовать». Для массовых '
        'действий: долгое нажатие включает режим выделения; тапайте файлы '
        'для добавления; панель снизу позволяет добавить все в избранное '
        'или удалить безопасно в корзину. Крестик отменяет выделение.',
    enBody:
        'Rename: the ⋮ menu on a file → "Rename". Batch: long-press to enter '
        'selection mode; tap files to add them; the bottom bar lets you '
        'favorite or safely trash them all. The ✕ cancels the selection.',
  ),

  // ---------- ROOT ----------
  FizzyEntry(
    id: 'root_intro',
    category: 'root',
    ruTitle: 'Root: для чего это',
    enTitle: 'Root: what it is for',
    ruKeywords: ['root', 'руут', 'суперюзер', 'системные файлы', 'ядро', 'kernel', 'раздел root'],
    enKeywords: ['root', 'superuser', 'system files', 'kernel', 'partition'],
    ruBody:
        'Root — это доступ суперпользователя ко всему устройству: системным '
        'разделам (/system, /vendor, /data), ядру и файлам, которые Android '
        'обычно прячет. FZ Manager проверяет root безопасной командой '
        'su -c id — она ничего не меняет. Если root есть — в разделе Root '
        'открывается полноценный навигатор по системным файлам.',
    enBody:
        'Root is superuser access to the whole device: system partitions '
        '(/system, /vendor, /data), the kernel and files Android normally '
        'hides. FZ Manager probes root with the safe su -c id command — it '
        'changes nothing. With root, the Root section becomes a full '
        'navigator over system files.',
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
        'случайно что-то изменить. Запись в системные разделы не выполняется '
        'из UI: это защищает вас от окирпичивания устройства.',
    enBody:
        'In the Root section files are read via su: ls -la for folders, '
        'head -c for file preview (first 64 KB, read-only). You can open '
        '/system/build.prop, kernel logs, configs — with zero risk of '
        'accidental modification. Writing to system partitions is not done '
        'from the UI: that keeps your device safe from bricking.',
    ruGuide: [
      'Root → «Проверить» (нужен подтверждённый root)',
      'Навигация: тап по папке, ⬆ — наверх',
      'Тап по файлу открывает просмотр содержимого',
      'Системные файлы открываются только для чтения',
    ],
    enGuide: [
      'Root → "Check" (verified root required)',
      'Navigate: tap a folder, ⬆ goes up',
      'Tap a file to open its content viewer',
      'System files open read-only',
    ],
  ),
  FizzyEntry(
    id: 'root_shell',
    category: 'root',
    ruTitle: 'Открытие файлов от имени Root',
    enTitle: 'Opening files as Root',
    ruKeywords: ['от имени root', 'root-режим', 'запуск', 'sh', 'скрипт', 'выполнить', 'исполнить', 'shell'],
    enKeywords: ['as root', 'run', 'sh', 'script', 'execute', 'shell'],
    ruBody:
        'В разделе «Файлы» у каждого файла есть пункт «Открыть как Root» — '
        'он читает файл через su (для системных файлов, недоступных обычным '
        'путём). Для .sh-скриптов доступен запуск через su с обязательным '
        'предупреждением и подтверждением. Вывод скрипта показывается на '
        'экране и пишется в журнал аудита. Запуск произвольных команд '
        'остаётся заблокированным — только явный запуск выбранного вами '
        'файла.',
    enBody:
        'In Files, every file has an "Open as Root" action — it reads the '
        'file through su (handy for system files). For .sh scripts there is '
        'a run-as-root option with a mandatory warning and confirmation. '
        'Script output is shown on screen and written to the audit log. '
        'Arbitrary command execution stays blocked — only the explicit '
        'script file you chose can be run.',
  ),
  FizzyEntry(
    id: 'root_safety',
    category: 'root',
    ruTitle: 'Безопасность Root',
    enTitle: 'Root safety model',
    ruKeywords: ['безопасность root', 'опасно', 'риск', 'окирпичить', 'предупреждение'],
    enKeywords: ['root safety', 'danger', 'risk', 'brick', 'warning'],
    ruBody:
        'Правила простые: (1) проверка — только su -c id; (2) чтение системных '
        'файлов — да, запись — нет; (3) запуск .sh — только с вашего явного '
        'подтверждения и только для выбранного файла; (4) каждое root-действие '
        'пишется в журнал аудита. Даже при включённом root UI не даёт '
        'возможности молча изменить /system — не потому что нельзя, а потому '
        'что это самая частая причина окирпиченных устройств.',
    enBody:
        'The rules are simple: (1) probing uses only su -c id; (2) reading '
        'system files — yes, writing — no; (3) running .sh requires your '
        'explicit confirmation and only for the chosen file; (4) every root '
        'action lands in the audit log. Even with root the UI never lets a '
        'silent /system modification slip through — not because it is '
        'impossible, but because it is the top cause of bricked phones.',
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
        'не навязывает облако и не отправляет данные неизвестно куда. Агент '
        'работает циклом: понимает задачу → вызывает инструменты → видит '
        'результат → продолжает, пока задача не решена. По умолчанию '
        'выключен. Включение: ИИ Мозг → переключатель сверху.',
    enBody:
        'AI Brain is an optional full agent inside FZ Manager. You connect '
        'your own provider (URL, model, API key) — FZ Manager forces no '
        'cloud and sends data only where you point it. The agent runs a '
        'loop: understand the task → call tools → observe results → '
        'continue until done. It is off by default. Enable: AI Brain → '
        'the switch on top.',
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
        'copy (копирование файлов и папок), move (перемещение), rename '
        '(переименование), delete (только с отдельного разрешения), '
        'configure (настройки FZ Manager: тема, язык, акцент, плотность), '
        'list_tools (агент видит свой арсенал), create_tool (агент создаёт '
        'свои инструменты из базовых операций).',
    enBody:
        'Full set: list (folder listing), read (up to 100 KB), write '
        '(write a file), write_append (append — how the agent writes '
        'arbitrarily long files in chunks), search (by name), copy (files '
        'and folders), move, rename, delete (separate opt-in only), '
        'configure (FZ Manager settings: theme, language, accent, density), '
        'list_tools (the agent sees its arsenal), create_tool (the agent '
        'creates its own tools from basic operations).',
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
        'инструменты через create_tool. Задаётся имя, описание и сценарий — '
        'конвейер базовых операций, например "list:/sdcard|write:/sdcard/out.txt". '
        'Новый инструмент появляется в арсенале агента и может '
        'вызываться как обычный. Он наследует те же разрешения — агент не '
        'может создать себе инструмент, обходящий ваши ограничения.',
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
    ruKeywords: ['безопасность ии', 'опасно', 'может ли ии удалить', 'разрешения ии', 'подтверждение'],
    enKeywords: ['ai safety', 'permissions', 'confirm', 'dangerous', 'delete'],
    ruBody:
        'Иерархия защиты: (1) агент выключен по умолчанию; (2) инструменты '
        'включаются по одному; (3) move/copy/delete/configure требуют '
        'подтверждения на каждое действие (диалог с деталями); (4) delete '
        'нуждается в двух разрешениях: общий инструмент + отдельный opt-in; '
        '(5) API-ключ хранится зашифрованным в Android Keystore; (6) '
        'произвольное выполнение кода заблокировано — только инструменты; '
        '(7) каждое действие в журнале аудита.',
    enBody:
        'Defense in depth: (1) the agent is off by default; (2) tools are '
        'enabled one by one; (3) move/copy/delete/configure require '
        'per-action confirmation dialogs with details; (4) delete needs two '
        'permissions: the tool itself + a separate opt-in; (5) the API key '
        'is encrypted in the Android Keystore; (6) arbitrary code execution '
        'is blocked — tools only; (7) every action is audited.',
  ),
  FizzyEntry(
    id: 'ai_provider',
    category: 'ai',
    ruTitle: 'Подключение провайдера',
    enTitle: 'Connecting a provider',
    ruKeywords: ['провайдер', 'url', 'модель', 'api ключ', 'подключить ии', 'openai', 'настроить агента'],
    enKeywords: ['provider', 'url', 'model', 'api key', 'connect', 'openai', 'setup'],
    ruBody:
        'ИИ Мозг → карточка провайдера: URL (любой OpenAI-совместимый '
        'endpoint, например https://api.openai.com/v1), модель (например '
        'gpt-4o-mini), API-ключ. Ключ шифруется Android Keystore и никогда '
        'не попадает в код или логи. После сохранения включите агент '
        'переключателем и напишите первую задачу в чат ниже.',
    enBody:
        'AI Brain → the provider card: URL (any OpenAI-compatible endpoint, '
        'e.g. https://api.openai.com/v1), model (e.g. gpt-4o-mini), API '
        'key. The key is encrypted with Android Keystore and never lands in '
        'code or logs. After saving, flip the switch and type your first '
        'task into the chat below.',
    ruGuide: [
      'ИИ Мозг → введите URL провайдера',
      'Введите модель',
      'Вставьте API-ключ → «Сохранить»',
      'Включите переключатель ИИ Мозга',
      'Напишите задачу в чат',
    ],
    enGuide: [
      'AI Brain → enter the provider URL',
      'Enter the model',
      'Paste the API key → "Save"',
      'Enable the AI Brain switch',
      'Type a task into the chat',
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

  // ---------- STORAGE ----------
  FizzyEntry(
    id: 'insights',
    category: 'storage',
    ruTitle: 'Обзор хранилища',
    enTitle: 'Storage insights',
    ruKeywords: ['обзор', 'хранилище', 'анализ', 'место', 'insights', 'большой файл', 'дубликаты'],
    enKeywords: ['insights', 'storage', 'analyze', 'space', 'large files', 'duplicates'],
    ruBody:
        'Раздел «Обзор» — панель здоровья хранилища: сканер больших файлов '
        '(>50 МБ, топ-50), корзина с восстановлением, недавние папки, '
        'закладки. Сканеры анализа категорий и дубликатов — каркасы: '
        'функция помечена как развивающаяся, чтобы честно показывать '
        'готовность, а не делать вид.',
    enBody:
        'The Insights section is your storage health dashboard: a large '
        'files scanner (>50 MB, top 50), trash with restore, recent folders '
        'and bookmarks. The category analysis and duplicates scanners are '
        'scaffolds — honestly labeled as work-in-progress instead of '
        'pretending.',
  ),
  FizzyEntry(
    id: 'permissions',
    category: 'storage',
    ruTitle: 'Разрешения и «Все файлы»',
    enTitle: 'Permissions and All-files access',
    ruKeywords: ['разрешение', 'разрешения', 'все файлы', 'доступ', 'manage external storage', 'не видит файлы'],
    enKeywords: ['permission', 'all files', 'access', 'manage external storage', 'cannot see files'],
    ruBody:
        'Современный Android держит файлы в песочнице. Для полноценной '
        'работы нужен флаг «Все файлы»: он выдаётся не через диалог, а на '
        'специальной странице системных настроек. FZ Manager сам открывает '
        'эту страницу (Разрешения в онбординге или Настройки → Разрешения): '
        'переключите тумблер и вернитесь — приложение перепроверит статус '
        'автоматически. Без него доступны только ваши медиа и общие папки.',
    enBody:
        'Modern Android sandboxes your files. Full operation needs the '
        '"All files" flag: it is granted not via a dialog but on a special '
        'system settings page. FZ Manager opens it for you (Permissions in '
        'onboarding or Settings → Permissions): flip the toggle and come '
        'back — the app re-checks automatically. Without it only your '
        'media and shared folders are visible.',
  ),

  // ---------- SETTINGS ----------
  FizzyEntry(
    id: 'customization',
    category: 'settings',
    ruTitle: 'Кастомизация интерфейса',
    enTitle: 'Interface customization',
    ruKeywords: ['кастомизация', 'тема', 'цвет', 'акцент', 'плотность', 'оформление', 'тёмная'],
    enKeywords: ['customization', 'theme', 'color', 'accent', 'density', 'dark'],
    ruBody:
        'Настройки → Кастомизация: тёмная/светлая тема; 6 акцентных цветов '
        '(индиго, фиолетовый, изумрудный, оранжевый, розовый, золотой); '
        'ползунок плотности интерфейса (компактно↔просторно); язык; сетка '
        'по умолчанию; скрытые файлы. Все изменения применяются мгновенно '
        'и сохраняются навсегда.',
    enBody:
        'Settings → Customization: dark/light theme; 6 accent colors '
        '(indigo, violet, emerald, orange, pink, gold); a UI density '
        'slider (compact↔spacious); language; default grid; hidden files. '
        'Changes apply instantly and persist forever.',
  ),
  FizzyEntry(
    id: 'settings_profile',
    category: 'settings',
    ruTitle: 'Профиль и данные',
    enTitle: 'Profile and data',
    ruKeywords: ['профиль', 'имя', 'фамилия', 'данные', 'конфиденциальность', 'где хранятся'],
    enKeywords: ['profile', 'name', 'data', 'privacy', 'where stored'],
    ruBody:
        'Имя и фамилия из онбординга хранятся только на устройстве '
        '(SharedPreferences) и используются для персональных приветствий. '
        'FZ Manager не имеет аналитики, телеметрии и серверов — все данные '
        'локальны. Единственный сетевой трафик — запросы к вашему '
        'собственному ИИ-провайдеру, и только когда ИИ Мозг включён.',
    enBody:
        'The name and surname from onboarding live only on your device '
        '(SharedPreferences) and power personalized greetings. FZ Manager '
        'ships no analytics, telemetry or servers — all data is local. The '
        'only network traffic goes to your own AI provider, and only while '
        'AI Brain is enabled.',
  ),
  FizzyEntry(
    id: 'settings_audit',
    category: 'settings',
    ruTitle: 'Журнал аудита',
    enTitle: 'Audit log',
    ruKeywords: ['журнал', 'аудит', 'лог', 'история действий'],
    enKeywords: ['audit', 'log', 'history', 'actions'],
    ruBody:
        'Каждое значимое действие — онбординг, удаление, root-проверка, '
        'запуск скрипта, операции агента — попадает в журнал с меткой '
        'времени. Журнал виден в разделе ИИ Мозга (раскрывающаяся карточка). '
        'Это ваш личный чёрный ящик: если что-то пошло не так — сначала '
        'смотрите сюда.',
    enBody:
        'Every meaningful action — onboarding, deletion, root probing, '
        'script runs, agent operations — lands in the log with a timestamp. '
        'The log lives in the AI Brain section (expandable card). Consider '
        'it your personal black box: when something went wrong, look here '
        'first.',
  ),

  // ---------- APP ----------
  FizzyEntry(
    id: 'app_about',
    category: 'app',
    ruTitle: 'Что такое FZ Manager',
    enTitle: 'What FZ Manager is',
    ruKeywords: ['что такое', 'о приложении', 'fz manager', 'менеджер', 'описание', 'версия'],
    enKeywords: ['about', 'what is', 'fz manager', 'description', 'version'],
    ruBody:
        'FZ Manager — файловый менеджер нового поколения: быстрый локальный '
        'браузер файлов, безопасный Root-навигатор, подключаемый ИИ-агент и '
        'помощник Физзи — всё в одном. Философия: ваше устройство — ваши '
        'правила. Никакой телеметрии, никакой рекламы, никаких скрытых '
        'сетевых вызовов — только то, что вы сами настроили.',
    enBody:
        'FZ Manager is a next-generation file manager: a fast local file '
        'browser, a safe Root navigator, a pluggable AI agent and the '
        'Fizzy assistant — all in one. Philosophy: your device, your '
        'rules. No telemetry, no ads, no hidden network calls — only what '
        'you configure yourself.',
  ),
  FizzyEntry(
    id: 'app_updates',
    category: 'app',
    ruTitle: 'Обновления и релизы',
    enTitle: 'Updates and releases',
    ruKeywords: ['обновление', 'версия', 'релиз', 'apk', 'обновить'],
    enKeywords: ['update', 'version', 'release', 'apk', 'upgrade'],
    ruBody:
        'Новые версии собираются автоматически и публикуются в разделе '
        'Releases на GitHub: подписанный APK + контрольная сумма SHA256. '
        'Перед установкой обновления удалите старую версию, если сменился '
        'ключ подписи. Список изменений каждого релиза — в описании тега.',
    enBody:
        'New versions build automatically and appear in the GitHub Releases '
        'section: a signed APK plus an SHA256 checksum. Remove the old '
        'version before installing if the signing key changed. Changelogs '
        'live in each release description.',
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
        '«Все файлы» — Настройки → Разрешения; (2) возможно, файлы скрытые — '
        'включите показ скрытых; (3) системные папки без root недоступны — '
        'это нормально; (4) попробуйте «Открыть хранилище» на экране ошибки, '
        'чтобы вернуться в доступный корень.',
    enBody:
        'If a folder is empty or access fails: (1) check the All-files '
        'permission — Settings → Permissions; (2) files may be hidden — '
        'enable hidden files; (3) system folders need root — that is '
        'normal; (4) use "Open storage" on the error screen to get back to '
        'an accessible root.',
  ),
  FizzyEntry(
    id: 'q_path_fix',
    ruTitle: 'Поле пути исправляет не то',
    enTitle: 'Path field fixes the wrong thing',
    ruKeywords: ['исправляет', 'не тот путь', 'неправильно исправляет', 'подсказки пути'],
    enKeywords: ['fixes wrong', 'wrong path', 'suggestions wrong'],
    ruBody:
        'Автоисправление срабатывает по расстоянию Левенштейна ≤ 2 и только '
        'для последнего сегмента. Если предложенное не подходит — просто '
        'игнорируйте чипы и продолжайте печатать: подсказки никогда не '
        'вмешиваются в текст сами, всё применяется только по вашему тапу.',
    enBody:
        'Auto-fix uses Levenshtein distance ≤ 2 and only for the last '
        'segment. If the suggestion is wrong — ignore the chips and keep '
        'typing: suggestions never touch your text; everything applies only '
        'on your tap.',
  ),
  FizzyEntry(
    id: 'q_ai_off',
    ruTitle: 'ИИ Мозг не включается',
    enTitle: 'AI Brain will not enable',
    ruKeywords: ['ии не работает', 'не включается ии', 'ошибка ии', 'агент молчит'],
    enKeywords: ['ai not working', 'will not enable', 'ai error', 'agent silent'],
    ruBody:
        'Чек-лист: (1) заполнены URL, модель и ключ; (2) URL — '
        'OpenAI-совместимый базовый адрес (без /chat/completions — он '
        'добавится сам, но и с ним работает); (3) провайдер доступен с '
        'устройства; (4) у ключа есть лимиты/кредиты; (5) агент включён '
        'переключателем. Ошибка запроса показывается в чате целиком.',
    enBody:
        'Checklist: (1) URL, model and key are filled; (2) the URL is an '
        'OpenAI-compatible base (without /chat/completions — it is appended '
        'automatically, but a full one works too); (3) the provider is '
        'reachable from the device; (4) the key has quota/credits; (5) the '
        'agent switch is on. Full request errors appear in the chat.',
  ),
  FizzyEntry(
    id: 'q_root_absent',
    ruTitle: 'Root не обнаружен',
    enTitle: 'Root not found',
    ruKeywords: ['root нет', 'root не обнаружен', 'нет рута'],
    enKeywords: ['no root', 'root not found'],
    ruBody:
        '«Root не обнаружен» означает, что команда su -c id не вернула '
        'uid=0. Возможные причины: устройство не рутировано; su-менеджер '
        '(Magisk и т.п.) не выдал разрешение приложению — проверьте в его '
        'настройках; рутированы, но su отсутствует в PATH. Всё остальное '
        'FZ Manager работает и без root.',
    enBody:
        '"Root not found" means su -c id did not return uid=0. Causes: the '
        'device is not rooted; your su manager (Magisk etc.) has not granted '
        'the app — check its settings; rooted but su missing from PATH. '
        'Everything else in FZ Manager works without root.',
  ),
  FizzyEntry(
    id: 'q_sh_run',
    ruTitle: 'Можно ли запустить .sh без root',
    enTitle: 'Can I run .sh without root',
    ruKeywords: ['запустить sh', 'скрипт без root', 'выполнить скрипт'],
    enKeywords: ['run sh', 'script without root', 'execute script'],
    ruBody:
        'Да, но с ограничениями Android: приложения не могут напрямую '
        'исполнять файлы из общего хранилища (noexec). FZ Manager запускает '
        'скрипты через su -c sh — то есть для запуска нужен root. Просмотр '
        '.sh доступен всегда: «Открыть как Root» читает содержимое.',
    enBody:
        'Yes, with Android caveats: apps cannot directly execute files from '
        'shared storage (noexec). FZ Manager runs scripts via su -c sh — '
        'so running requires root. Viewing .sh always works: "Open as Root" '
        'reads the content.',
  ),
];

const _kTips = <String, String>{
  'files':
      'Совет: долгое нажатие — выделение; ⋮ у файла — переименовать, '
      'в избранное, закладка или корзина.',
  'root':
      'Совет: держите телефон спокойно — каждое root-действие требует '
      'явного подтверждения и попадает в журнал аудита.',
  'ai':
      'Совет: начните с read-only инструментов (list, read, search) — '
      'убедитесь в качестве агента, прежде чем включать изменяющие.',
  'insights':
      'Совет: сканер больших файлов находит «тяжеловесов» >50 МБ — '
      'начинайте очистку с топа списка.',
  'settings':
      'Совет: акцентный цвет применяется мгновенно — попробуйте изумрудный '
      'или золотой.',
};

const _kTipsEn = <String, String>{
  'files': 'Tip: long-press selects; the ⋮ menu renames, favorites, '
      'bookmarks or trashes.',
  'root': 'Tip: stay calm — every root action needs explicit confirmation '
      'and lands in the audit log.',
  'ai': 'Tip: start with read-only tools (list, read, search) — gauge the '
      'agent before enabling mutating ones.',
  'insights': 'Tip: the large-file scanner finds >50 MB heavyweights — '
      'start cleaning from the top.',
  'settings': 'Tip: the accent color applies instantly — try emerald or '
      'gold.',
};

const _kSmalltalk = <String, (String, String)>{
  'привет': ('Привет! Я Физзи. Спроси меня про файлы, Root, ИИ Мозг — или попроси совет.', ''),
  'здравствуй': ('Приветствую! Чем помочь в FZ Manager сегодня?', ''),
  'hello': ('Hello! Ask me about files, Root or the AI Brain — or ask for a tip.', ''),
  'hi': ('Hi! What can Fizzy explain today?', ''),
  'спасибо': ('Всегда пожалуйста! Если что — я рядом.', ''),
  'thanks': ('Anytime! I am around if you need me.', ''),
  'как дела': ('Работаю без сбоев, база знаний подгружена. А у вас как? Чем займёмся?', ''),
  'how are you': ('Running smooth, knowledge base loaded. What shall we do?', ''),
  'кто ты': ('Я Физзи — встроенный помощник FZ Manager. Знаю все функции менеджера, безопасность, Root и ИИ Мозг.', ''),
  'who are you': ('I am Fizzy — the built-in assistant of FZ Manager. I know every feature, the security model, Root and the AI Brain.', ''),
};

class Fizzy {
  final bool russian;
  Fizzy({required this.russian});

  String get greeting => russian
      ? 'Привет! Я Физзи — твой помощник в FZ Manager. Могу объяснить любую '
          'функцию: файлы, умный поиск путей, Root, ИИ Мозг, корзину, '
          'настройки. Просто спроси!'
      : 'Hi! I am Fizzy, your FZ Manager assistant. I can explain any '
          'feature: files, smart paths, Root, the AI Brain, trash, '
          'settings. Just ask!';

  List<FizzyEntry> get topics => _kTopics;
  List<FizzyEntry> get faq => _kFaq;

  String tipFor(String screen) =>
      (russian ? _kTips : _kTipsEn)[screen] ?? greeting;

  /// Classify intent: smalltalk, faq or topic.
  FizzyAnswer answer(String question) {
    final q = question.toLowerCase().trim();

    // 1) Smalltalk.
    for (final entry in _kSmalltalk.entries) {
      if (q.contains(entry.key)) {
        return FizzyAnswer(
            text: russian ? entry.value.$1 : _enSmalltalkMap[entry.key] ?? entry.value.$1,
            entry: null);
      }
    }

    // 2) FAQ and topics: score by keyword hits (longer keywords weigh more).
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
      return FizzyAnswer(
        text: russian ? best.ruBody : best.enBody,
        entry: best,
        guide: russian ? best.ruGuide : best.enGuide,
      );
    }
    return FizzyAnswer(
      text: russian
          ? 'Хм, точного ответа у меня пока нет. Спроси про: файлы, умный '
              'поиск путей, корзину, Root, системные файлы, запуск .sh, '
              'ИИ Мозг, инструменты агента, разрешения, кастомизацию или '
              'журнал аудита.'
          : 'Hmm, no exact answer yet. Ask about: files, smart paths, '
              'trash, Root, system files, running .sh, AI Brain, agent '
              'tools, permissions, customization or the audit log.',
      entry: null,
    );
  }

const _enSmalltalkMap = <String, String>{
  'привет': 'Hello! I am Fizzy. Ask me about files, Root or the AI Brain — or ask for a tip.',
  'здравствуй': 'Greetings! What can I help with in FZ Manager today?',
  'приветствие': 'Hi there!',
  'спасибо': 'You are welcome! I am here whenever you need me.',
  'как дела': 'Running smooth, knowledge base loaded. What shall we do?',
  'кто ты': 'I am Fizzy — the built-in FZ Manager assistant.',
};

class FizzyAnswer {
  final String text;
  final FizzyEntry? entry;
  final List<String> guide;
  const FizzyAnswer({required this.text, this.entry, this.guide = const []});
}
