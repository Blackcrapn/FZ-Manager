import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Simple typed persistence on top of SharedPreferences.
class StorageService {
  static const _onboarded = 'onboarded';
  static const _russian = 'russian';
  static const _dark = 'dark';
  static const _grid = 'grid';
  static const _assistant = 'assistant';
  static const _name = 'name';
  static const _surname = 'surname';
  static const _provider = 'provider';
  static const _model = 'model';
  static const _aiEnabled = 'aiEnabled';
  static const _aiDelete = 'aiDelete';
  static const _rootChecked = 'rootChecked';
  static const _rootAvailable = 'rootAvailable';
  static const _favorites = 'favorites';
  static const _bookmarks = 'bookmarks';
  static const _recent = 'recent';
  static const _aiTools = 'aiTools';
  static const _path = 'path';
  static const _accent = 'accent';
  static const _density = 'density';
  static const _showHidden = 'showHidden';

  final SharedPreferences _p;
  StorageService._(this._p);

  static Future<StorageService> load() async =>
      StorageService._(await SharedPreferences.getInstance());

  bool get onboarded => _p.getBool(_onboarded) ?? false;
  set onboarded(bool v) => _p.setBool(_onboarded, v);

  bool get russian => _p.getBool(_russian) ?? false;
  set russian(bool v) => _p.setBool(_russian, v);

  bool get dark => _p.getBool(_dark) ?? true;
  set dark(bool v) => _p.setBool(_dark, v);

  bool get grid => _p.getBool(_grid) ?? false;
  set grid(bool v) => _p.setBool(_grid, v);

  bool get assistant => _p.getBool(_assistant) ?? true;
  set assistant(bool v) => _p.setBool(_assistant, v);

  String get name => _p.getString(_name) ?? '';
  set name(String v) => _p.setString(_name, v);

  String get surname => _p.getString(_surname) ?? '';
  set surname(String v) => _p.setString(_surname, v);

  String get provider => _p.getString(_provider) ?? '';
  set provider(String v) => _p.setString(_provider, v);

  String get model => _p.getString(_model) ?? '';
  set model(String v) => _p.setString(_model, v);

  bool get aiEnabled => _p.getBool(_aiEnabled) ?? false;
  set aiEnabled(bool v) => _p.setBool(_aiEnabled, v);

  bool get aiDelete => _p.getBool(_aiDelete) ?? false;
  set aiDelete(bool v) => _p.setBool(_aiDelete, v);

  bool get rootChecked => _p.getBool(_rootChecked) ?? false;
  set rootChecked(bool v) => _p.setBool(_rootChecked, v);

  bool get rootAvailable => _p.getBool(_rootAvailable) ?? false;
  set rootAvailable(bool v) => _p.setBool(_rootAvailable, v);

  String get path => _p.getString(_path) ?? '/storage/emulated/0';
  set path(String v) => _p.setString(_path, v);

  String get accent => _p.getString(_accent) ?? '465cff';
  set accent(String v) => _p.setString(_accent, v);

  double get density => _p.getDouble(_density) ?? 1.0;
  set density(double v) => _p.setDouble(_density, v);

  bool get showHidden => _p.getBool(_showHidden) ?? false;
  set showHidden(bool v) => _p.setBool(_showHidden, v);

  Set<String> get favorites => (_p.getStringList(_favorites) ?? []).toSet();
  set favorites(Set<String> v) => _p.setStringList(_favorites, v.toList());

  Set<String> get bookmarks => (_p.getStringList(_bookmarks) ?? []).toSet();
  set bookmarks(Set<String> v) => _p.setStringList(_bookmarks, v.toList());

  List<String> get recent => _p.getStringList(_recent) ?? [];
  set recent(List<String> v) => _p.setStringList(_recent, v);

  Map<String, bool> get aiTools {
    final raw = _p.getString(_aiTools);
    if (raw == null) return {'read': true, 'search': true};
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(k, v == true));
  }

  set aiTools(Map<String, bool> v) =>
      _p.setString(_aiTools, jsonEncode(v));
}
