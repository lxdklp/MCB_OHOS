import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  AboutPageState createState() => AboutPageState();
}

class AboutPageState extends State<AboutPage> {

  String _appVersion = "unknown";

  Future<void> _loadAppVersion() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String appVersion = packageInfo.version;
    setState(() {
      _appVersion = appVersion;
    });
  }

  // 打开URL
  Future<void> _launchURL(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('无法打开链接: $url')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('发生错误: $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('关于'),
      ),
      body: ListView(
        children: [
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Column(
                  children: [
                    Text(
                      '\n本项目使用GPL3.0协议开源,使用过程中请遵守GPL3.0协议\n',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Image.asset(
                            'assets/img/icon/icon.png',
                            height: 150,
                          ),
                        ),
                        const SizedBox(width: 70), // 两张图片之间的间距
                        Flexible(
                          child: Image.asset(
                            'assets/img/logo/flutter.png',
                            height: 150,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16), // 图片和文字之间的间距
                    Text(
                      'Minecraft Box Version $_appVersion OHOS',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      'Copyright © 2025 lxdklp. All rights reserved\n',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: const Text('官网'),
              subtitle: const Text('https://mcb.lxdklp.top'),
              trailing: const Icon(Icons.open_in_new),
              onTap: () => _launchURL('https://mcb.lxdklp.top'),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: const Text('Github'),
              subtitle: const Text('https://github.com/lxdklp/MCB_OHOS'),
              trailing: const Icon(Icons.open_in_new),
              onTap: () => _launchURL('https://github.com/lxdklp/MCB_OHOS'),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: const Text('BUG反馈与APP建议'),
              subtitle: const Text('https://github.com/lxdklp/MCB_OHOS/issues'),
              trailing: const Icon(Icons.open_in_new),
              onTap: () => _launchURL('https://github.com/lxdklp/MCB_OHOS/issues'),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                const ListTile(
                  title: Text('鸣谢'),
                  subtitle: Text('没有你们就没有这个项目!'),
                ),
                ListTile(
                  title: const Text('Minecraft Wiki'),
                  subtitle: const Text('编写API文档与提供游戏规则中文描述\nhttps://minecraft.wiki'),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => _launchURL('https://minecraft.wiki'),
                ),
                ListTile(
                  title: const Text('Sawaratsuki'),
                  subtitle: const Text('Flutter LOGO 绘制\nhttps://github.com/SAWARATSUKI/KawaiiLogos'),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => _launchURL('https://github.com/SAWARATSUKI/KawaiiLogos'),
                ),
                ListTile(
                  title: const Text('Noto CJK fonts'),
                  subtitle: const Text('软件字体\nhttps://github.com/notofonts/noto-cjk'),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => _launchURL('https://github.com/notofonts/noto-cjk'),
                ),
                ListTile(
                  title: const Text('GNU General Public License Version 3'),
                  subtitle: const Text('开源协议\nhttps://www.gnu.org/licenses/gpl-3.0.html'),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => _launchURL('https://www.gnu.org/licenses/gpl-3.0.html'),
                ),
                const ListTile(
                  title: Text('本项目使用的开源库'),
                ),
                ListTile(
                  title: const Text('flutter'),
                  subtitle: const Text('https://github.com/flutter/flutter'),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => _launchURL('https://github.com/flutter/flutter'),
                ),
                ListTile(
                  title: const Text('cupertino_icons'),
                  subtitle: const Text('https://github.com/flutter/packages/tree/main/third_party/packages/cupertino_icons'),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => _launchURL('https://github.com/flutter/packages/tree/main/third_party/packages/cupertino_icons'),
                ),
                ListTile(
                  title: const Text('dynamic_color'),
                  subtitle: const Text('https://github.com/material-foundation/flutter-packages/tree/main/packages/dynamic_color'),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => _launchURL('https://github.com/material-foundation/flutter-packages/tree/main/packages/dynamic_color'),
                ),
                ListTile(
                  title: const Text('shared_preferences'),
                  subtitle: const Text('https://github.com/flutter/packages/tree/main/packages/shared_preferences/shared_preferences'),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => _launchURL('https://github.com/flutter/packages/tree/main/packages/shared_preferences/shared_preferences'),
                ),
                ListTile(
                  title: const Text('crypto'),
                  subtitle: const Text('https://github.com/dart-lang/core/tree/main/pkgs/crypto'),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => _launchURL('https://github.com/dart-lang/core/tree/main/pkgs/crypto'),
                ),
                ListTile(
                  title: const Text('json_rpc_2'),
                  subtitle: const Text('https://github.com/dart-lang/tools/tree/main/pkgs/json_rpc_2'),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => _launchURL('https://github.com/dart-lang/tools/tree/main/pkgs/json_rpc_2'),
                ),
                ListTile(
                  title: const Text('web_socket_channel'),
                  subtitle: const Text('https://github.com/dart-lang/http/tree/master/pkgs/web_socket_channel'),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => _launchURL('https://github.com/dart-lang/http/tree/master/pkgs/web_socket_channel'),
                ),
                ListTile(
                  title: const Text('flutter_launcher_icons'),
                  subtitle: const Text('https://github.com/fluttercommunity/flutter_launcher_icons'),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => _launchURL('https://github.com/fluttercommunity/flutter_launcher_icons'),
                ),
                ListTile(
                  title: const Text('url_launcher'),
                  subtitle: const Text('https://github.com/flutter/packages/tree/main/packages/url_launcher/url_launcher'),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => _launchURL('https://github.com/flutter/packages/tree/main/packages/url_launcher/url_launcher'),
                ),ListTile(
                  title: const Text('flutter_colorpicker'),
                  subtitle: const Text('https://github.com/mchome/flutter_colorpicker'),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => _launchURL('https://github.com/mchome/flutter_colorpicker'),
                ),ListTile(
                  title: const Text('package_info_plus'),
                  subtitle: const Text('https://github.com/fluttercommunity/plus_plugins/tree/main/packages/package_info_plus/package_info_plus'),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => _launchURL('https://github.com/fluttercommunity/plus_plugins/tree/main/packages/package_info_plus/package_info_plus'),
                ),
                ListTile(
                  title: const Text('flutter_launcher_icons'),
                  subtitle: const Text('https://github.com/fluttercommunity/flutter_launcher_icons'),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => _launchURL('https://github.com/fluttercommunity/flutter_launcher_icons'),
                ),
                const ListTile(
                  title: Text('Github的各位'),
                  subtitle: Text('谢谢大家'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}