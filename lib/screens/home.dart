import 'dart:ui';
import 'package:flutter/material.dart';
import '../app.dart';
import '../widgets.dart';
import '../permission_service.dart';
import '../native_service.dart';
import 'files_page.dart';
import 'insights_page.dart';
import 'root_page.dart';
import 'kernel_page.dart';
import 'ai_page.dart';
import 'settings_page.dart';
import 'assistant_page.dart';

class Home extends StatefulWidget {
  const Home({super.key, required this.state});
  final AppState state;
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  int index = 0;
  late final AnimationController _bob;

  @override
  void initState() {
    super.initState();
    _bob = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final granted = await PermissionService.requestNotifications();
      if (granted && widget.state.musicIsland) {
        await NativeService.instance.startMusicEffect();
      }
    });
  }

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final pages = <Widget>[
      FilesPage(state: s),
      InsightsPage(state: s),
      AiPage(state: s),
      AssistantPage(state: s),
      SettingsPage(state: s),
    ];
    return LayoutBuilder(
      builder: (c, x) {
        final wide = x.maxWidth >= 800;
        final scheme = Theme.of(context).colorScheme;
        return Scaffold(
          body: SafeArea(
            child: Row(
              children: [
                if (wide)
                  NavigationRail(
                    extended: x.maxWidth > 1050,
                    leading: const Padding(
                      padding: EdgeInsets.all(12),
                      child: FzLogo(size: 48),
                    ),
                    destinations: [
                      _d(s, Icons.folder_outlined, Icons.folder, 'Файлы', 'Files'),
                      _d(s, Icons.donut_large, Icons.donut_large, 'Обзор', 'Insights'),
                      _d(s, Icons.psychology_outlined, Icons.psychology, 'ИИ Мозг', 'AI Brain'),
                      _d(s, Icons.auto_awesome_outlined, Icons.auto_awesome, 'Физзи', 'Fizzy'),
                      _d(s, Icons.settings_outlined, Icons.settings, 'Настройки', 'Settings'),
                      NavigationRailDestination(
                          icon: const Icon(Icons.more_horiz),
                          label: Text(tr(s, 'Ещё', 'More'))),
                    ],
                    selectedIndex: index,
                    onDestinationSelected: (v) {
                      if (v == 5) {
                        _showMoreSheet(s);
                        return;
                      }
                      setState(() => index = v);
                    },
                  ),
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          scheme.primaryContainer.withValues(alpha: 0.06),
                          scheme.surface,
                        ],
                      ),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.02),
                            end: Offset.zero,
                          ).animate(anim),
                          child: child,
                        ),
                      ),
                      child: KeyedSubtree(key: ValueKey(index), child: pages[index]),
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: wide
              ? null
              : LiquidGlassDock(
                  index: index,
                  onChanged: (v) => setState(() => index = v),
                  bob: _bob,
                  items: [
                    _DockItem(icon: Icons.folder_outlined, activeIcon: Icons.folder_rounded,
                        label: tr(s, 'Файлы', 'Files')),
                    _DockItem(icon: Icons.donut_large, activeIcon: Icons.donut_large,
                        label: tr(s, 'Обзор', 'Insights')),
                    _DockItem(icon: Icons.psychology_outlined, activeIcon: Icons.psychology_rounded,
                        label: tr(s, 'ИИ Мозг', 'AI Brain')),
                    _DockItem(icon: Icons.auto_awesome_outlined, activeIcon: Icons.auto_awesome_rounded,
                        label: tr(s, 'Физзи', 'Fizzy')),
                    _DockItem(icon: Icons.settings_outlined, activeIcon: Icons.settings_rounded,
                        label: tr(s, 'Настр.', 'Settings')),
                    _DockItem(icon: Icons.more_horiz_rounded, activeIcon: Icons.more_horiz_rounded,
                        label: tr(s, 'Ещё', 'More')),
                  ],
                  onMore: () => _showMoreSheet(s),
                ),
        );
      },
    );
  }

  void _showMoreSheet(AppState s) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (x) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.memory_rounded),
                title: Text(tr(s, 'Ядро', 'Kernel')),
                subtitle: Text(tr(s, 'Быстрые команды и /proc', 'Quick commands and /proc')),
                onTap: () {
                  Navigator.pop(x);
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => Scaffold(
                          appBar: AppBar(title: Text(tr(s, 'Ядро', 'Kernel'))),
                          body: KernelPage(state: s))));
                },
              ),
              ListTile(
                leading: const Icon(Icons.admin_panel_settings_rounded),
                title: Text('Root'),
                subtitle: Text(tr(s, 'Системные разделы и проверка', 'System partitions and probe')),
                onTap: () {
                  Navigator.pop(x);
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => Scaffold(
                          appBar: AppBar(title: const Text('Root')),
                          body: RootPage(state: s))));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  NavigationRailDestination _d(AppState s, IconData i, IconData si, String ru, String en) =>
      NavigationRailDestination(
        icon: Icon(i),
        selectedIcon: Icon(si),
        label: Text(tr(s, ru, en)),
      );
}

class _DockItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  _DockItem({required this.icon, required this.activeIcon, required this.label});
}

/// Liquid Glass dock: real blur + specular sheen + droplet indicator.
/// Compact: smaller height, icons 24, labels 10px.
class LiquidGlassDock extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  final List<_DockItem> items;
  final VoidCallback onMore;
  final Animation<double> bob;
  const LiquidGlassDock({
    super.key,
    required this.index,
    required this.onChanged,
    required this.items,
    required this.onMore,
    required this.bob,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
        child: SizedBox(
          height: 62,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: scheme.surface.withValues(alpha: 0.55),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: scheme.brightness == Brightness.dark ? 0.10 : 0.25),
                      width: 1),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.22), blurRadius: 30, offset: const Offset(0, 12)),
                    BoxShadow(color: scheme.primary.withValues(alpha: 0.12), blurRadius: 22, offset: const Offset(0, -2)),
                  ],
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Specular sheen across the glass (top highlight line).
                    Positioned(
                      top: 1, left: 24, right: 24, height: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          gradient: LinearGradient(colors: [
                            Colors.transparent,
                            Colors.white.withValues(alpha: 0.5),
                            Colors.transparent,
                          ]),
                        ),
                      ),
                    ),
                    // Moving droplet (капелька) under the active item.
                    AnimatedAlign(
                      duration: const Duration(milliseconds: 380),
                      curve: Curves.easeOutBack,
                      alignment: Alignment(
                        (-1 + (2.0 / (items.length - 1)) * index).clamp(-1, 1), 0),
                      child: AnimatedBuilder(
                        animation: bob,
                        builder: (_, child) => Transform.translate(
                          offset: Offset(0, -bob.value * 2),
                          child: child,
                        ),
                        child: Container(
                          width: 46,
                          height: 46,
                          margin: const EdgeInsets.only(top: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              center: const Alignment(-0.35, -0.4),
                              colors: [
                                scheme.primary.withValues(alpha: 0.55),
                                scheme.primary.withValues(alpha: 0.18),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(color: scheme.primary.withValues(alpha: 0.45), blurRadius: 18, spreadRadius: 2),
                            ],
                          ),
                          child: CustomPaint(painter: _DropletHighlight()),
                        ),
                      ),
                    ),
                    Row(
                      children: List.generate(items.length, (i) {
                        final active = i == index;
                        return Expanded(
                          child: InkWell(
                            onTap: i == items.length - 1 ? onMore : () => onChanged(i),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AnimatedScale(
                                  scale: active ? 1.14 : 1,
                                  duration: const Duration(milliseconds: 260),
                                  curve: Curves.easeOutBack,
                                  child: Icon(
                                    active ? items[i].activeIcon : items[i].icon,
                                    size: 23,
                                    color: active ? scheme.primary : scheme.onSurfaceVariant,
                                  ),
                                ),
                                AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 220),
                                  style: TextStyle(
                                    fontSize: active ? 10.5 : 9.5,
                                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                                    color: active ? scheme.primary : scheme.onSurfaceVariant,
                                  ),
                                  child: Text(items[i].label,
                                      maxLines: 1, overflow: TextOverflow.ellipsis),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tiny glossy highlight that makes the droplet look like liquid glass.
class _DropletHighlight extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Path()
      ..addOval(Rect.fromLTWH(size.width * 0.18, size.height * 0.10,
          size.width * 0.34, size.height * 0.22));
    canvas.drawPath(p, Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
