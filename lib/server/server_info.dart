import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mcb/function/log.dart';
import 'package:mcb/function/network.dart';
import 'package:mcb/server/server_info/management.dart';
import 'package:mcb/server/server_info/send.dart';
import 'package:mcb/server/server_info/setting.dart';

class ServerInfoPage extends StatefulWidget {
  const ServerInfoPage({
    super.key,
    required this.name,
    required this.address,
    required this.port,
    required this.token,
    required this.tls,
    required this.unsafe,
    this.rconPort = '',
    this.password = '',
    this.rcon = 'false',
  });

  final String name;
  final String address;
  final String port;
  final String token;
  final String tls;
  final String unsafe;
  final String rconPort;
  final String password;
  final String rcon;

  @override
  ServerInfoPageState createState() => ServerInfoPageState();
}

class ServerInfoPageState extends State<ServerInfoPage> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // 添加生命周期观察者
    _initializeRpcService();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // 移除观察者
    _rpcService.dispose();
    LogUtil.log('${widget.name} 页面已关闭', level: 'INFO');
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    LogUtil.log('应用生命周期状态变化: $state', level: 'INFO');
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _rpcService.pauseConnection();
    } else if (state == AppLifecycleState.resumed) {
      if (!_rpcService.isConnected) {
        _rpcService.resumeConnection();
      }
    }
  }

  bool _isLoading = true;
  String _statusMessage = '正在连接到服务器...';
  bool _isConnectionError = false;
  int _selectedIndex = 0;
  late Network _rpcService;

  // 导航项数据
  static const List<NavigationItem> _navigationItems = [
    NavigationItem(
      label: '状态',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
    ),
    NavigationItem(
      label: '发送',
      icon: Icons.send_outlined,
      selectedIcon: Icons.send,
    ),
    NavigationItem(
      label: '设置',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
    ),
  ];

  // 初始化 RPC 服务
  Future<void> _initializeRpcService() async {
    bool useTls = widget.tls == 'true';
    bool unsafe = widget.unsafe == 'true';
    LogUtil.log('初始化连接: 地址=${widget.address}, 端口=${widget.port}, TLS=$useTls, 不安全证书=$unsafe', level: 'INFO');
    _rpcService = Network(
      name: widget.name,
      address: widget.address,
      port: widget.port,
      token: widget.token,
      useTls: useTls,
      unsafe: unsafe,
      onStatusChanged: _handleConnectionStatusChanged,
    );
    try {
      await _rpcService.initialize();
    } catch (e, stack) {
      LogUtil.log('初始化 RPC 服务失败: $e\n$stack', level: 'ERROR');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = '连接错误: ${e.toString()}';
          _isConnectionError = true;
        });
      }
    }
  }

  // 处理连接状态变化
  void _handleConnectionStatusChanged(ConnectionStatus status, String? message) {
    if (!mounted) return;
    setState(() {
      switch (status) {
        case ConnectionStatus.connecting:
          _isLoading = true;
          _statusMessage = '正在连接到服务器...';
          _isConnectionError = false;
          break;
        case ConnectionStatus.connected:
          _isLoading = false;
          _isConnectionError = false;
          break;
        case ConnectionStatus.disconnected:
          _isLoading = false;
          _statusMessage = '连接已断开: ${message ?? "未知原因"}';
          _isConnectionError = true;
          break;
        case ConnectionStatus.error:
          _isLoading = false;
          _statusMessage = '连接错误: ${message ?? "未知错误"}';
          _isConnectionError = true;
          break;
      }
    });
  }

  // 重新连接
  Future<void> _reconnect() async {
    setState(() {
      _isLoading = true;
      _statusMessage = '正在重新连接...';
    });
    try {
      await _rpcService.establishConnection();
    } catch (e) {
      LogUtil.log('重新连接失败: $e', level: 'ERROR');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = '重连失败: ${e.toString()}';
        });
      }
    }
  }

  // 获取子页面
  List<Widget> _getPages() {
    return [
      // 状态管理页面
      ServerManagementPage(
        name: widget.name,
        address: widget.address,
        port: widget.port,
        token: widget.token,
        network: _rpcService,
        isConnected: _rpcService.isConnected
      ),
      // 发送页面
      SendPage(
        name: widget.name,
        address: widget.address,
        port: widget.port,
        token: widget.token,
        network: _rpcService,
        isConnected: _rpcService.isConnected,
        rcon: widget.rcon == 'true',
        rconPort: widget.rconPort,
        password: widget.password,
      ),
      // 设置页面
      ServerSettingPage(
        name: widget.name,
        address: widget.address,
        port: widget.port,
        token: widget.token,
        network: _rpcService,
        isConnected: _rpcService.isConnected
      ),
    ];
  }

  // 切换导航项
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isConnectionError || _isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.name),
        ),
        body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _statusMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.red[700],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _reconnect,
                    child: const Text('重新连接'),
                  ),
                ],
              ),
            ),
      );
    }

    // 获取屏幕宽度
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool useDrawer = screenWidth >= 600;
    final List<Widget> pages = _getPages();

    if (useDrawer) {
      if (screenWidth >= 900) {
        // 大屏幕
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.name),
          ),
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
                child: pages[_selectedIndex],
              ),
            ],
          ),
        );
      } else {
        // 中等屏幕
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.name),
          ),
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
                child: pages[_selectedIndex],
              ),
            ],
          ),
        );
      }
    } else {
      // 底部导航栏
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.name),
        ),
        body: pages[_selectedIndex],
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