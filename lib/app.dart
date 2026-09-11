import 'package:flutter/material.dart';
import 'storage_service.dart';
import 'screens/onboarding.dart';
import 'screens/home.dart';

/// Global application state, persisted through [StorageService].
class AppState extends ChangeNotifier {
  final StorageService store;

  bool _onboarded;
  bool _russian;
  bool _dark;
  bool _grid;
  bool _assistant;
  String _name;
  String _surname;
  String _provider;
  String _model;
  bool _aiEnabled;
  bool _aiDelete;
  bool _rootChecked;
  bool _rootAvailable;
  String _path;
  String _accent;
  double _density;
  Set<String> _favorites;
  Set<String> _bookmarks;
  List<String> _recent;
  Map<String, bool> _aiTools = {'read': true, 'search': true};
  final List<String> audit = [];

  AppState(this.store)
      : _onboarded = store.onboarded,
        _russian = store.russian,
        _dark = store.dark,
        _grid = store.grid,
        _assistant = store.assistant,
        _name = store.name,
        _surname = store.surname,
        _provider = store.provider,
        _model = store.model,
        _aiEnabled = store.aiEnabled,
        _aiDelete = store.aiDelete,
        _rootChecked = store.rootChecked,
        _rootAvailable = store.rootAvailable,
        _path = store.path,
        _accent = store.accent,
        _density = store.density,
        _favorites = store.favorites,
        _bookmarks = store.bookmarks,
        _recent = store.recent,
        _aiTools = store.aiTools;

  bool get onboarded => _onboarded;
  set onboarded(bool v) {
    _onboarded = v;
    store.onboarded = v;
    notifyListeners();
  }

  bool get russian => _russian;
  set russian(bool v) {
    _russian = v;
    store.russian = v;
    notifyListeners();
  }

  bool get dark => _dark;
  set dark(bool v) {
    _dark = v;
    store.dark = v;
    notifyListeners();
  }

  bool get grid => _grid;
  set grid(bool v) {
    _grid = v;
    store.grid = v;
    notifyListeners();
  }

  bool get assistant => _assistant;
  set assistant(bool v) {
    _assistant = v;
    store.assistant = v;
    notifyListeners();
  }

  String get name => _name;
  set name(String v) {
    _name = v;
    store.name = v;
    notifyListeners();
  }

  String get surname => _surname;
  set surname(String v) {
    _surname = v;
    store.surname = v;
    notifyListeners();
  }

  String get provider => _provider;
  set provider(String v) {
    _provider = v;
    store.provider = v;
    notifyListeners();
  }

  String get model => _model;
  set model(String v) {
    _model = v;
    store.model = v;
    notifyListeners();
  }

  bool get aiEnabled => _aiEnabled;
  set aiEnabled(bool v) {
    _aiEnabled = v;
    store.aiEnabled = v;
    notifyListeners();
  }

  bool get aiDelete => _aiDelete;
  set aiDelete(bool v) {
    _aiDelete = v;
    store.aiDelete = v;
    notifyListeners();
  }

  bool get rootChecked => _rootChecked;
  set rootChecked(bool v) {
    _rootChecked = v;
    store.rootChecked = v;
    notifyListeners();
  }

  bool get rootAvailable => _rootAvailable;
  set rootAvailable(bool v) {
    _rootAvailable = v;
    store.rootAvailable = v;
    notifyListeners();
  }

  String get path => _path;
  set path(String v) {
    _path = v;
    store.path = v;
  }

  String get accent => _accent;
  set accent(String v) {
    _accent = v;
    store.accent = v;
    notifyListeners();
  }

  double get density => _density;
  set density(double v) {
    _density = v;
    store.density = v;
    notifyListeners();
  }

  Set<String> get favorites => _favorites;
  set favorites(Set<String> v) {
    _favorites = v;
    store.favorites = v;
    notifyListeners();
  }

  Set<String> get bookmarks => _bookmarks;
  set bookmarks(Set<String> v) {
    _bookmarks = v;
    store.bookmarks = v;
    notifyListeners();
  }

  List<String> get recent => _recent;
  set recent(List<String> v) {
    _recent = v;
    store.recent = v;
  }

  Map<String, bool> get aiTools => _aiTools;
  set aiTools(Map<String, bool> v) {
    _aiTools = v;
    store.aiTools = v;
    notifyListeners();
  }

  void rememberRecent(String p) {
    _recent.remove(p);
    _recent.insert(0, p);
    if (_recent.length > 15) _recent = _recent.sublist(0, 15);
    store.recent = _recent;
  }

  void change() => notifyListeners();

  void log(String value) {
    audit.insert(0, '${DateTime.now().toLocal().toString().substring(0, 19)}  $value');
    notifyListeners();
  }

  Color get accentColor => _parseColor(_accent);

  static Color _parseColor(String hex) {
    var h = hex.replaceAll('#', '');
    if (h.length == 6) h = 'ff$h';
    final v = int.tryParse(h, radix: 16);
    return v == null ? const Color(0xff465cff) : Color(v);
  }
}

String tr(AppState s, String ru, String en) => s.russian ? ru : en;

class FzApp extends StatelessWidget {
  const FzApp({super.key});
  static Future<AppState> createState() async {
    final store = await StorageService.load();
    return AppState(store);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppState>(
      future: createState(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }
        final state = snap.data!;
        return ListenableBuilder(
          listenable: state,
          builder: (_, __) => MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'FZ Manager',
            themeMode: state.dark ? ThemeMode.dark : ThemeMode.light,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: state.accentColor),
              useMaterial3: true,
              visualDensity: _density(state.density),
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: state.accentColor,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
              visualDensity: _density(state.density),
              scaffoldBackgroundColor: const Color(0xff0d1020),
              cardTheme: const CardThemeData(color: Color(0xff171b31)),
            ),
            home: state.onboarded ? Home(state: state) : Onboarding(state: state),
          ),
        );
      },
    );
  }

  static VisualDensity _density(double d) {
    final v = ((d - 1.0) * 2.0).clamp(-1.0, 1.0);
    return VisualDensity(horizontal: v, vertical: v);
  }
}
