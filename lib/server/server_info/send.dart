import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mcb/function/log.dart';
import 'package:mcb/function/network.dart';

class SendPage extends StatefulWidget {
  final String name;
  final String address;
  final String port;
  final String token;
  final Network network;
  final bool isConnected;
  final bool rcon;
  final String rconPort;
  final String password;

  const SendPage({
    super.key,
    required this.name,
    required this.address,
    required this.port,
    required this.token,
    required this.network,
    required this.isConnected,
    required this.rcon,
    required this.rconPort,
    required this.password,
  });

  @override
  SendPageState createState() => SendPageState();
}

class SendPageState extends State<SendPage> {
  final TextEditingController _methodController = TextEditingController();
  final TextEditingController _paramsController = TextEditingController();
  final TextEditingController _responseController = TextEditingController(); 
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _rconCommandController = TextEditingController();
  final TextEditingController _rconResponseController = TextEditingController();
  bool _isRconConnected = false;
  bool _isRconLoading = false;
  RconClient? _rconClient;
  bool _isLoading = false;
  String _responseText = '';
  bool _isError = false;
  bool _isDisposed = false;
  List<Map<String, String>> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
    // 默认请求
    _methodController.text = 'server/status';
    // 默认命令
    _rconCommandController.text = 'help';
  }

  @override
  void dispose() {
    _isDisposed = true;
    if (_rconClient != null) {
      _rconClient!.close();
      _rconClient = null;
    }
    _methodController.dispose();
    _paramsController.dispose();
    _responseController.dispose();
    _rconCommandController.dispose();
    _rconResponseController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // 加载历史记录
  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> historyJson = prefs.getStringList('${widget.name}_rpc_history') ?? [];
      setState(() {
        _history = historyJson
            .map((json) => Map<String, String>.from(jsonDecode(json)))
            .toList();
      });
    } catch (e) {
      LogUtil.log('加载RPC历史记录失败: $e', level: 'ERROR');
    }
  }

  // 保存历史记录
  Future<void> _saveToHistory(String method, String params) async {
    try {
      _history.removeWhere((item) => item['method'] == method && item['params'] == params);
      _history.insert(0, {'method': method, 'params': params});
      if (_history.length > 10) {
        _history = _history.sublist(0, 10);
      }
      final prefs = await SharedPreferences.getInstance();
      final List<String> historyJson = _history
          .map((item) => jsonEncode(item))
          .toList();
      await prefs.setStringList('${widget.name}_rpc_history', historyJson);
      setState(() {});
    } catch (e) {
      LogUtil.log('保存RPC历史记录失败: $e', level: 'ERROR');
    }
  }

  // 发送RPC请求
  Future<void> _sendRequest() async {
    String method = _methodController.text.trim();
    String paramsText = _paramsController.text.trim();
    if (method.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入方法名')),
      );
      return;
    }
    if (!widget.isConnected) {
      setState(() {
        _responseText = '连接已断开，无法发送请求';
        _responseController.text = '连接已断开，无法发送请求';
        _isError = true;
      });
      return;
    }
    LogUtil.log('准备发送RPC请求: $method', level: 'INFO');
    setState(() {
      _isLoading = true;
      _responseText = '正在发送请求...';
      _responseController.text = '正在发送请求...';
      _isError = false;
    });
    try {
      dynamic params;
      if (paramsText.isNotEmpty) {
        try {
          params = jsonDecode(paramsText);
        } catch (e) {
          setState(() {
            _isLoading = false;
            _responseText = '参数格式错误: ${e.toString()}';
            _responseController.text = '参数格式错误: ${e.toString()}';
            _isError = true;
          });
          return;
        }
      }
      LogUtil.log('正在发送RPC请求: $method ${params != null ? "带参数" : "无参数"}', level: 'DEBUG');
      final response = await widget.network.callAPI(method, params)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw TimeoutException('请求超时(15秒)')
          );
      LogUtil.log('收到原始响应: ${response.toString()}', level: 'DEBUG');
      _saveToHistory(method, paramsText);
      final jsonString = const JsonEncoder.withIndent('  ').convert(response);
      LogUtil.log('格式化后JSON长度: ${jsonString.length}', level: 'DEBUG');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _responseText = jsonString;
          _responseController.text = jsonString;
          _isError = response.containsKey('error');
        });
      }
    } catch (e) {
      LogUtil.log('RPC请求失败: $e', level: 'ERROR');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _responseText = '请求失败: ${e.toString()}';
          _responseController.text = '请求失败: ${e.toString()}';
          _isError = true;
        });
      }
    }
  }

  // 从历史记录中加载
  Future<void> _loadFromHistory(Map<String, String> item) async {
    setState(() {
      _methodController.text = item['method'] ?? '';
      _paramsController.text = item['params'] ?? '';
    });
  }

  // 清除输入
  Future<void> _clearInputs() async {
    setState(() {
      _methodController.clear();
      _paramsController.clear();
    });
  }

  // 连接 RCON
  Future<void> _connectRcon() async {
    if (_isRconConnected) {
      _disconnectRcon();
      return;
    }
    setState(() {
      _isRconLoading = true;
      _rconResponseController.text = '正在连接到RCON服务器...';
    });
    try {
      final rconPort = int.tryParse(widget.rconPort) ?? 25575;
      final password = widget.password;
      if (password.isEmpty) {
        throw Exception('RCON密码不能为空');
      }
      // 创建并连接RCON客户端
      LogUtil.log('正在连接RCON: ${widget.address}:$rconPort', level: 'INFO');
      final rconClient = RconClient(widget.address, rconPort, password);
      // 尝试连接和认证
      final success = await rconClient.connect();
      if (!success) {
        throw Exception('RCON连接失败');
      }
      _rconClient = rconClient;
      if (mounted) {
        setState(() {
          _isRconConnected = true;
          _isRconLoading = false;
          _rconResponseController.text = 'RCON连接成功，可以发送命令';
        });
      }
      LogUtil.log('RCON连接成功: ${widget.address}:$rconPort', level: 'INFO');
    } catch (e) {
      LogUtil.log('RCON连接失败: $e', level: 'ERROR');
      if (_rconClient != null) {
        _rconClient!.close();
        _rconClient = null;
      }
      if (mounted) {
        setState(() {
          _isRconLoading = false;
          _isRconConnected = false;
          _rconResponseController.text = '连接失败: ${e.toString()}';
        });
      }
    }
  }

  // 断开 RCON 连接
  Future<void> _disconnectRcon() async {
    if (_rconClient != null) {
      _rconClient!.close();
      _rconClient = null;
      if (mounted && !_isDisposed) {
        setState(() {
          _isRconConnected = false;
          _rconResponseController.text = 'RCON连接已断开';
        });
      }
      LogUtil.log('RCON连接已断开', level: 'INFO');
    }
  }

  // 发送 RCON 命令
  Future<void> _sendRconCommand() async {
    final command = _rconCommandController.text.trim();
    if (command.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入命令')),
      );
      return;
    }
    if (!_isRconConnected || _rconClient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('RCON未连接')),
      );
      return;
    }
    setState(() {
      _isRconLoading = true;
      _rconResponseController.text = '正在发送命令...';
    });
    try {
      final response = await _rconClient!.sendCommand(command);
      if (mounted) {
        setState(() {
          _isRconLoading = false;
          _rconResponseController.text = response;
        });
      }
      LogUtil.log('RCON命令发送成功: $command', level: 'INFO');
    } catch (e) {
      LogUtil.log('RCON命令发送失败: $e', level: 'ERROR');
      if (e.toString().contains('socket') ||
          e.toString().contains('connection') ||
          e.toString().contains('network')) {
        _disconnectRcon();
      }
      if (mounted) {
        setState(() {
          _isRconLoading = false;
          _rconResponseController.text = '命令执行失败: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          // RPC请求卡片
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题和输入区域
                  const Text(
                    '发送 RPC 请求',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 方法输入
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _methodController,
                          decoration: const InputDecoration(
                            labelText: '方法名',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearInputs,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // 参数输入
                  TextField(
                    controller: _paramsController,
                    decoration: const InputDecoration(
                      labelText: '参数 (JSON格式,可选)',
                      border: OutlineInputBorder(),
                    ),
                    minLines: 2,
                    maxLines: 5,
                  ),
                  const SizedBox(height: 16),
                  // 连接状态和发送按钮
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.isConnected
                            ? '连接状态：已连接'
                            : '连接状态：已断开',
                        style: TextStyle(
                          color: widget.isConnected ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: widget.isConnected ? _sendRequest : null,
                        icon: const Icon(Icons.send),
                        label: const Text('发送请求'),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  // 历史记录区域
                  if (_history.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '历史记录',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.remove('${widget.name}_rpc_history');
                            setState(() {
                              _history = [];
                            });
                          },
                          child: const Text('清除历史'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 50,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _history.length,
                        itemBuilder: (context, index) {
                          final item = _history[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ActionChip(
                              label: Text(item['method'] ?? ''),
                              onPressed: () => _loadFromHistory(item),
                              avatar: const Icon(Icons.history, size: 16),
                            ),
                          );
                        },
                      ),
                    ),
                    const Divider(height: 32),
                  ],
                  // 响应区域
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '响应',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_responseText.isNotEmpty && !_isLoading)
                        IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: () {
                            final data = ClipboardData(text: _responseText);
                            Clipboard.setData(data);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('已复制到剪贴板')),
                            );
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // RPC响应框
                  SizedBox(
                    height: 200,
                    child: _isLoading
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 16),
                                Text('请求处理中...', style: TextStyle(fontSize: 16)),
                              ],
                            ),
                          )
                        : TextField(
                            controller: _responseController,
                            readOnly: true,
                            maxLines: null,
                            expands: true,
                            textAlignVertical: TextAlignVertical.top,
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.all(16.0),
                              filled: true,
                              fillColor: _isError ? Colors.red[50] : Colors.grey[50],
                              isCollapsed: false,
                              alignLabelWithHint: true,
                            ),
                            keyboardType: TextInputType.multiline,
                          ),
                  ),
                ],
              ),
            ),
          ),
          // RCON 卡片
          if (widget.rcon) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '发送 RCON 命令',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 服务器信息
                    Text(
                      '服务器: ${widget.address}:${widget.rconPort}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 命令输入
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _rconCommandController,
                            decoration: const InputDecoration(
                              labelText: '命令',
                              border: OutlineInputBorder(),
                              hintText: 'Minecraft命令,无需 /',
                            ),
                            enabled: _isRconConnected,
                            onSubmitted: _isRconConnected
                                ? (_) => _sendRconCommand()
                                : null,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _rconCommandController.clear();
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // 连接状态和发送按钮
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _isRconConnected
                              ? 'RCON 状态:已连接'
                              : 'RCON 状态:未连接',
                          style: TextStyle(
                            color: _isRconConnected ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: _isRconLoading ? null : _connectRcon,
                              icon: _isRconLoading 
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Icon(_isRconConnected ? Icons.close : Icons.connect_without_contact),
                              label: Text(_isRconConnected ? '断开连接' : '连接 RCON'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isRconConnected ? Colors.red : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: _isRconConnected && !_isRconLoading ? _sendRconCommand : null,
                              icon: const Icon(Icons.send),
                              label: const Text('发送命令'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // 响应区域
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'RCON 响应',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_rconResponseController.text.isNotEmpty && !_isRconLoading)
                          IconButton(
                            icon: const Icon(Icons.copy),
                            onPressed: () {
                              final data = ClipboardData(text: _rconResponseController.text);
                              Clipboard.setData(data);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('已复制到剪贴板')),
                              );
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // RCON响应输入框
                    SizedBox(
                      height: 200,
                      child: _isRconLoading
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(height: 16),
                                  Text('处理中...', style: TextStyle(fontSize: 16)),
                                  SizedBox(height: 8),
                                  Text('请耐心等待，这可能需要几秒钟', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                            )
                          : TextField(
                              controller: _rconResponseController,
                              readOnly: true,
                              maxLines: null,
                              expands: true,
                              textAlignVertical: TextAlignVertical.top,
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                contentPadding: const EdgeInsets.all(16.0),
                                filled: true,
                                fillColor: Colors.grey[50],
                                isCollapsed: false,
                                alignLabelWithHint: true,
                              ),
                              keyboardType: TextInputType.multiline,
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}