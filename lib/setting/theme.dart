import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart' show BlockPicker;

import 'package:mcb/main.dart'; // 引入 MyApp 类

// ThemePage 类定义了主题设置页面的内容
class ThemePage extends StatefulWidget {
  const ThemePage({super.key});

  @override
  ThemePageState createState() => ThemePageState();
}

class ThemePageState extends State<ThemePage> {
  bool _isDarkMode = false; // 亮暗色模式开关状态
  bool _followSystem = false; // 暗色模式跟随系统开关状态
  Color _themeColor = Colors.blue; // 默认主题色
  bool _autoThemeColor = true; // 自动取色开关状态

  @override
  void initState() {
    super.initState();
    _isDarkMode = MyApp.of(context).themeMode == ThemeMode.dark;
    _followSystem = MyApp.of(context).themeMode == ThemeMode.system;
    _themeColor = MyApp.of(context).themeColor;
    _autoThemeColor = MyApp.of(context).autoThemeColor;
  }

  void _selectColor() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('选择主题色'),
          content: BlockPicker(
            pickerColor: _themeColor,
            onColorChanged: (Color color) {
              setState(() {
                _themeColor = color; // 更新主题色
                // 更新应用主题色
                MyApp.of(context).changeThemeColor(_themeColor);
              });
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('确定'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('主题设置'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SwitchListTile(
                title: const Text('暗色模式跟随系统'),
                secondary: const Icon(Icons.brightness_6),
                value: _followSystem,
                onChanged: (bool value) {
                  setState(() {
                    _followSystem = value;
                    MyApp.of(context).changeTheme(_followSystem ? ThemeMode.system : (_isDarkMode ? ThemeMode.dark : ThemeMode.light));
                  });
                },
              ),
            ),
            if (!_followSystem)
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SwitchListTile(
                  title: const Text('暗色模式'),
                  secondary: const Icon(Icons.dark_mode),
                  value: _isDarkMode,
                  onChanged: (bool value) {
                    setState(() {
                      _isDarkMode = value;
                      MyApp.of(context).changeTheme(_isDarkMode ? ThemeMode.dark : ThemeMode.light);
                    });
                  },
                ),
              ),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SwitchListTile(
                title: const Text('自动取色'),
                subtitle: const Text('使用系统主题色'),
                secondary: const Icon(Icons.color_lens_outlined),
                value: _autoThemeColor,
                onChanged: (bool value) {
                  setState(() {
                    _autoThemeColor = value;
                    MyApp.of(context).toggleAutoThemeColor(value);
                  });
                },
              ),
            ),
            if (!_autoThemeColor)
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: const Text('自定义主题色'),
                  leading: const Icon(Icons.palette),
                  trailing: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: _themeColor,
                      border: Border.all(color: Theme.of(context).dividerColor),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  onTap: _selectColor,
                ),
              ),
          ],
        ),
      ),
    );
  }
}