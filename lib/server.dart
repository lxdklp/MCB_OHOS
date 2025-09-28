import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mcb/server/add_server.dart';
import 'package:mcb/server/edit_server.dart';
import 'package:mcb/server/server_info.dart';

class ServerPage extends StatefulWidget {
  const ServerPage({super.key});

  @override
  ServerPageState createState() => ServerPageState();
}

class ServerPageState extends State<ServerPage> {
  List<Map<String, String>> _serverList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadServers();
  }

  // 加载服务器列表
  Future<void> _loadServers() async {
    setState(() {
      _isLoading = true;
    });
    final prefs = await SharedPreferences.getInstance();
    final List<String> serverNames = prefs.getStringList('servers') ?? [];
    List<Map<String, String>> servers = [];
    for (String name in serverNames) {
      final List<String>? config = prefs.getStringList('${name}_config');
      if (config != null) {
        servers.add({
          'name': config[0],
          'address': config[1],
          'rpcPort': config[2],
          'token': config[3],
          'tls': config[4],
          'unsafe': config[5],
          'rcon': config[6],
          'rconPort': config[7],
          'password': config[8],
        });
      }
    }
    if (mounted) {
      setState(() {
        _serverList = servers;
        _isLoading = false;
      });
    }
  }

  // 添加服务器并刷新列表
  void _addServer() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddServerPage()),
    );
    _loadServers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的服务器'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _serverList.isEmpty
              ? _buildEmptyView()
              : _buildServerList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _addServer,
        child: const Icon(Icons.add),
      ),
    );
  }

  // 构建空状态视图
  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.dns_outlined,
            size: 80,
          ),
          const SizedBox(height: 16),
          Text(
            '暂无服务器',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text('点击下方按钮添加服务器'),
        ],
      ),
    );
  }

  // 构建服务器列表
  Widget _buildServerList() {
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: _serverList.length,
      itemBuilder: (context, index) {
        final server = _serverList[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            title: Text('服务器名称: ${server['name'] ?? '未命名服务器'}'),
            subtitle: Text('RPC地址: ${server['address']}:${server['rpcPort']}'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ServerInfoPage(
                  name: server['name'] ?? '',
                  address: server['address'] ?? '',
                  port: server['rpcPort'] ?? '',
                  token: server['token'] ?? '',
                  tls: server['tls'] ?? 'false',
                  unsafe: server['unsafe'] ?? 'false',
                  rcon: server['rcon'] ?? 'false',
                  rconPort: server['rconPort'] ?? '',
                  password: server['password'] ?? '',
                )),
              ).then((_) {
                _loadServers();
              });
            },
            trailing: ButtonTheme(
              minWidth: 0,
              child: IconButton(
                icon: const Icon(Icons.create),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => EditServerPage(
                      name: server['name'] ?? '',
                      address: server['address'] ?? '',
                      rpcPort: server['rpcPort'] ?? '',
                      token: server['token'] ?? '',
                      tls: server['tls'] ?? 'false',
                      unsafe: server['unsafe'] ?? 'false',
                      rcon: server['rcon'] ?? 'false',
                      rconPort: server['rconPort'] ?? '',
                      password: server['password'] ?? '',
                    )),
                  ).then((_) {
                    _loadServers();
                  });
                },
              ),
            )
          ),
        );
      },
    );
  }
}