import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mcb/server.dart';
import 'package:mcb/setting.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:mcb/function/log.dart';

// 日志
_initLogs() async {
  final PackageInfo packageInfo = await PackageInfo.fromPlatform();
  String appVersion = packageInfo.version;
  int buildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;
  await LogUtil.clearLogs();
  await LogUtil.log('启动MCB,版本: $appVersion,构建号: $buildNumber', level: 'INFO');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initLogs();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => MyAppState();

  // 提供一个静态方法来获取状态
  static MyAppState of(BuildContext context) {
    final MyAppState? result = context.findAncestorStateOfType<MyAppState>();
    if (result != null) return result;
    throw FlutterError.fromParts(
      <DiagnosticsNode>[
        ErrorSummary(
          'MyApp.of() 在找不到 MyApp 的上下文中被调用。',
        ),
      ],
    );
  }
}

class MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;
  Color _themeColor = Colors.blue;
  bool _autoThemeColor = true;

  ThemeMode get themeMode => _themeMode;
  Color get themeColor => _themeColor;
  bool get autoThemeColor => _autoThemeColor;

  @override
  void initState() {
    super.initState();
    _loadThemePrefs();
  }

  // 加载主题设置
  Future<void> _loadThemePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final modeStr = prefs.getString('themeMode');
    final colorInt = prefs.getInt('themeColor');
    final autoColor = prefs.getBool('autoThemeColor');
    if (autoColor != null) {
      _autoThemeColor = autoColor;
    }
    if (colorInt != null) {
      _themeColor = Color(colorInt);
    }
    if (modeStr != null) {
      switch (modeStr) {
        case 'dark':
          _themeMode = ThemeMode.dark;
          break;
        case 'light':
          _themeMode = ThemeMode.light;
          break;
        default:
          _themeMode = ThemeMode.system;
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> changeTheme(ThemeMode themeMode) async {
    setState(() {
      _themeMode = themeMode;
    });
    final prefs = await SharedPreferences.getInstance();
    String modeStr;
    switch (themeMode) {
      case ThemeMode.dark:
        modeStr = 'dark';
        break;
      case ThemeMode.light:
        modeStr = 'light';
        break;
      default:
        modeStr = 'system';
    }
    await prefs.setString('themeMode', modeStr);
  }

  Future<void> changeThemeColor(Color color) async {
    setState(() {
      _themeColor = color;
    });
    final prefs = await SharedPreferences.getInstance();
  int colorValue = (color.alpha << 24) |
          (color.red << 16) |
          (color.green << 8) |
          color.blue;
    await prefs.setInt('themeColor', colorValue);
  }

  Future<void> toggleAutoThemeColor(bool autoColor) async {
    setState(() {
      _autoThemeColor = autoColor;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('autoThemeColor', autoColor);
  }

  @override
  Widget build(BuildContext context) {
    ColorScheme lightColorScheme;
    ColorScheme darkColorScheme;
      lightColorScheme = ColorScheme.fromSeed(
        seedColor: _themeColor,
        brightness: Brightness.light,
      );
      darkColorScheme = ColorScheme.fromSeed(
        seedColor: _themeColor,
        brightness: Brightness.dark,
      );

    return MaterialApp(
      theme: ThemeData(
        colorScheme: lightColorScheme,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: darkColorScheme,
        useMaterial3: true,
      ),
      themeMode: _themeMode,
      home: const MyHomePage(),
    );
  }
}

// 导航项数据类
class NavigationItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const NavigationItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });
}

// 响应式布局的主页
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = [
    ServerPage(),
    SettingPage(),
  ];

  static const List<NavigationItem> _navigationItems = [
    NavigationItem(
      label: '服务器',
      icon: Icons.storage_outlined,
      selectedIcon: Icons.storage,
    ),
    NavigationItem(
      label: '设置',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
    ),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool useDrawer = screenWidth >= 450;

    if (useDrawer) {
      // 侧边栏导航
      if (screenWidth >= 900) {
        // 大屏幕
        return Scaffold(
          body: Row(
            children: [
              NavigationRail(
                extended: true,
                destinations: _navigationItems.map((item) {
                  return NavigationRailDestination(
                    icon: Icon(item.icon),
                    selectedIcon: Icon(item.selectedIcon),
                    label: Text(item.label),
                  );
                }).toList(),
                selectedIndex: _selectedIndex,
                onDestinationSelected: _onItemTapped,
                useIndicator: true,
                indicatorColor: Theme.of(context).colorScheme.secondaryContainer,
              ),
              Expanded(
                child: _pages[_selectedIndex],
              ),
            ],
          ),
        );
      } else {
        // 中等屏幕
        return Scaffold(
          body: Row(
            children: [
              NavigationRail(
                selectedIndex: _selectedIndex,
                onDestinationSelected: _onItemTapped,
                labelType: NavigationRailLabelType.all,
                useIndicator: true,
                indicatorColor: Theme.of(context).colorScheme.secondaryContainer,
                destinations: _navigationItems.map((item) {
                  return NavigationRailDestination(
                    icon: Icon(item.icon),
                    selectedIcon: Icon(item.selectedIcon),
                    label: Text(item.label),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  );
                }).toList(),
                backgroundColor: Theme.of(context).colorScheme.surface,
                minWidth: 80,
                minExtendedWidth: 180,
              ),
              Expanded(
                child: _pages[_selectedIndex],
              ),
            ],
          ),
        );
      }
    } else {
      // 底部导航栏
      return Scaffold(
        body: _pages[_selectedIndex],
        bottomNavigationBar: NavigationBar(
          destinations: _navigationItems.map((item) {
            return NavigationDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(item.selectedIcon),
              label: item.label,
            );
          }).toList(),
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onItemTapped,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        ),
      );
    }
  }
}