import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mcb/function/log.dart';
import 'package:mcb/function/crypto_util.dart';

class EditServerPage extends StatefulWidget {
  const EditServerPage({
    super.key,
    required this.name,
    required this.address,
    required this.rpcPort,
    required this.token,
    required this.tls,
    required this.unsafe,
    required this.rcon,
    required this.rconPort,
    required this.password,
  });

  final String name;
  final String address;
  final String rpcPort;
  final String token;
  final String tls;
  final String unsafe;
  final String rcon;
  final String rconPort;
  final String password;

  @override
  EditServerPageState createState() => EditServerPageState();
}

class EditServerPageState extends State<EditServerPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _rpcPortController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _rconPortController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String tls = 'false';
  String unsafe = 'false';
  String rcon = 'false';

  bool _obscureToken = true;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.name;
    _addressController.text = widget.address;
    _rpcPortController.text = widget.rpcPort;
    _tokenController.text = widget.token;
    tls = widget.tls;
    unsafe = widget.unsafe;
    rcon = widget.rcon;
    _rconPortController.text = widget.rconPort;
    _passwordController.text = widget.password;
  }

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

  // 切换令牌可见性
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
        const SnackBar(content: Text('请填写 RPC 端口')),
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
    if (rcon == 'true') {
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
    if (rcon == 'false') {
      rconPort = '';
      password = '';
    }
    final prefs = await SharedPreferences.getInstance();
    if (name != widget.name) {
      List<String> servers = prefs.getStringList('servers') ?? [];
      servers.remove(widget.name);
      servers.add(name);
      await prefs.setStringList('servers', servers);
      await prefs.remove('${widget.name}_config');
    }
    String encryptedToken = await CryptoUtil.encrypt(token);
    String encryptedPassword = await CryptoUtil.encrypt(password);
    List<String> serverConfig = [name, address, rpcPort, encryptedToken, tls, unsafe, rcon, rconPort, encryptedPassword];
    await prefs.setStringList('${name}_config', serverConfig);
    LogUtil.log(
      '已保存服务器: $name',
      level: 'INFO'
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('服务器添加成功')),
    );
    Navigator.pop(context);
  }

  // 删除服务器
  Future<void> _deleteServer() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> servers = prefs.getStringList('servers') ?? [];
    servers.remove(widget.name);
    await prefs.setStringList('servers', servers);
    await prefs.remove('${widget.name}_config');
    LogUtil.log('删除服务器: ${widget.name}', level: 'INFO');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('服务器删除成功')),
    );
    Navigator.pop(context);
  }

  // 确认删除对话框
  Future<void> _showDeleteDialog() async {
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除服务器'),
        content: Text('确定要删除服务器"${widget.name}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _deleteServer();
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('编辑服务器'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                      hintText: '请输入地址',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _rpcPortController,
                    decoration: const InputDecoration(
                      labelText: '端口',
                      hintText: '请输入端口',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _tokenController,
                    decoration: InputDecoration(
                      labelText: '令牌',
                      hintText: '请输入令牌',
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
                            'TLS 加密',
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
                        value: tls == 'true',
                        onChanged: (value) {
                          setState(() {
                            tls = value ? 'true' : 'false';
                          });
                        },
                      ),
                    ],
                  ),
                  if (tls == 'true') ...[
                    const SizedBox(height: 20),
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
                              '自签证书请启用',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: unsafe == 'true',
                          onChanged: (value) {
                            setState(() {
                              unsafe = value ? 'true' : 'false';
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
                        value: rcon == 'true',
                        onChanged: (value) {
                          setState(() {
                            rcon = value ? 'true' : 'false';
                          });
                        },
                      ),
                    ],
                  ),
                  if (rcon == 'true') ...[
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
                        border: OutlineInputBorder(),
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
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'save',
            onPressed: _saveServer,
            child: const Icon(Icons.save),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'delete',
            onPressed: _showDeleteDialog,
            child: const Icon(Icons.delete),
          ),
        ],
      ),
    );
  }
}