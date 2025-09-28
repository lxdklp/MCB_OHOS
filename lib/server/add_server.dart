import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mcb/function/log.dart';

class AddServerPage extends StatefulWidget {
  const AddServerPage({super.key});

  @override
  AddServerPageState createState() => AddServerPageState();
}

class AddServerPageState extends State<AddServerPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _rpcPortController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _rconPortController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String _tls = 'false';
  String _unsafe = 'false';
  String _rcon = 'false';

  bool _obscureToken = true;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _rpcPortController.dispose();
    _tokenController.dispose();
    _rconPortController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 切换 RPC 令牌可见性
  Future<void> _toggleTokenVisibility() async {
    setState(() {
      _obscureToken = !_obscureToken;
    });
  }

  // 切换 RCON 密码可见性
  Future<void> _togglePasswordVisibility() async {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  // 保存服务器信息
  Future<void> _saveServer() async {
    String name = _nameController.text;
    String address = _addressController.text;
    String rpcPort = _rpcPortController.text;
    String token = _tokenController.text;
    String rconPort = _rconPortController.text;
    String password = _passwordController.text;

    if (name.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写名称')),
      );
      return;
    }
    if (address.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写地址')),
      );
      return;
    }
    if (rpcPort.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写端口')),
      );
      return;
    }
    if (token.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写令牌')),
      );
      return;
    }
    if (_rcon == 'true') {
      if (rconPort.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请填写 RCON 端口')),
        );
        return;
      }
      if (password.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请填写 RCON 密码')),
        );
        return;
      }
      if (int.tryParse(rpcPort) == null || int.parse(rpcPort) <= 0 || int.parse(rpcPort) > 65535) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('端口格式不正确')),
        );
        return;
      }
    }
    if (_rcon == 'false') {
      rconPort = '';
      password = '';
    }
    final prefs = await SharedPreferences.getInstance();
    List<String> servers = prefs.getStringList('servers') ?? [];
    if (servers.contains(name)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已存在相同名称的服务器')),
      );
      return;
    }
    servers.add(name);
    await prefs.setStringList('servers', servers);
    List<String> serverConfig = [name, address, rpcPort, token, _tls, _unsafe, _rcon, rconPort, password];
    await prefs.setStringList('${name}_config', serverConfig);
    LogUtil.log(
      '保存服务器: $name, 地址: $address, 端口: $rpcPort, 令牌: $token, TLS: $_tls, 允许不安全: $_unsafe, RCON: $_rcon, RCON 端口: $rconPort, RCON 密码: $password',
      level: 'INFO'
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('服务器添加成功')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('添加服务器'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '服务器信息',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: '名称',
                        hintText: '请输入名称',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: '地址',
                        hintText: '请输入服务器地址',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _rpcPortController,
                      decoration: const InputDecoration(
                        labelText: '端口',
                        hintText: '请输入 RPC 端口',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _tokenController,
                      decoration: InputDecoration(
                        labelText: '令牌',
                        hintText: '请输入 RPC 令牌',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureToken ? Icons.visibility : Icons.visibility_off),
                          onPressed: _toggleTokenVisibility,
                        )
                      ),
                      obscureText: _obscureToken,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '连接设置',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '实验性,可能存在bug',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'SSL/TLS 加密',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '使用安全连接',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: _tls == 'true',
                          onChanged: (value) {
                            setState(() {
                              _tls = value ? 'true' : 'false';
                            });
                          },
                        ),
                      ],
                    ),
                    if (_tls == 'true') ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '允许不安全证书',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '接受自签名或过期证书',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          Switch(
                            value: _unsafe == 'true',
                            onChanged: (value) {
                              setState(() {
                                _unsafe = value ? 'true' : 'false';
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'RCON',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '启用 RCON',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '通过 RCON 远程管理服务器',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: _rcon == 'true',
                          onChanged: (value) {
                            setState(() {
                              _rcon = value ? 'true' : 'false';
                            });
                          },
                        ),
                      ],
                    ),
                    if (_rcon == 'true') ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _rconPortController,
                        decoration: const InputDecoration(
                          labelText: '端口',
                          hintText: '请输入 RCON 端口',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: '密码',
                          hintText: '请输入 RCON 密码',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                            onPressed: _togglePasswordVisibility,
                          ),
                        ),
                        obscureText: _obscurePassword,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 150),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveServer,
        child: const Icon(Icons.save),
      ),
    );
  }
}