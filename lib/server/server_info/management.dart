import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:mcb/function/log.dart';
import 'package:mcb/function/network.dart';

class ServerManagementPage extends StatefulWidget {
  final String name;
  final String address;
  final String port;
  final String token;
  final Network network;
  final bool isConnected;

  const ServerManagementPage({
    super.key,
    required this.name,
    required this.address,
    required this.port,
    required this.token,
    required this.network,
    required this.isConnected,
  });

  @override
  ServerManagementPageState createState() => ServerManagementPageState();
}

class ServerManagementPageState extends State<ServerManagementPage> {
  bool _isLoading = true;
  String _statusMessage = '';
  dynamic _serverStatus;
  Timer? _refreshTimer;
  List<Map<String, dynamic>> _onlinePlayers = [];
  bool _isLoadingPlayers = false;
  String _playersErrorMessage = '';
  List<Map<String, dynamic>> _bannedPlayers = [];
  bool _isLoadingBans = false;
  String _bansErrorMessage = '';
  List<Map<String, dynamic>> _operatorList = [];
  bool _isLoadingOperators = false;
  String _operatorsErrorMessage = '';
  List<Map<String, dynamic>> _allowlist = [];
  bool _isLoadingAllowlist = false;
  String _allowlistErrorMessage = '';
  List<Map<String, dynamic>> _ipBannedList = [];
  bool _isLoadingIpBans = false;
  String _ipBansErrorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchServerStatus();
    _fetchOnlinePlayers();
    _fetchBanList();
    _fetchIpBanList();
    _fetchOperatorList();
    _fetchAllowlist();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        _fetchServerStatus();
        _fetchOnlinePlayers();
        _fetchBanList();
        _fetchIpBanList();
        _fetchOperatorList();
        _fetchAllowlist();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  // 获取服务器状态
  Future<void> _fetchServerStatus() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final jsonResponse = await widget.network.callAPI('server/status');
      if (jsonResponse.containsKey('result')) {
        final result = jsonResponse['result'];
        if (mounted) {
          setState(() {
            _isLoading = false;
            _serverStatus = result;
            _statusMessage = '';
          });
        }
        LogUtil.log('获取服务器状态成功: ${widget.name}', level: 'INFO');
      } else if (jsonResponse.containsKey('error')) {
        throw Exception('服务器错误: ${jsonResponse['error']}');
      } else {
        throw Exception('无效的响应格式');
      }
    } catch (e) {
      LogUtil.log('获取服务器状态失败: $e', level: 'ERROR');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = '获取状态失败: ${_formatErrorMessage(e)}';
        });
      }
    }
  }

// 获取在线玩家列表
  Future<void> _fetchOnlinePlayers() async {
    if (!mounted) return;
    setState(() {
      _isLoadingPlayers = true;
      _playersErrorMessage = '';
    });
    try {
      final jsonResponse = await widget.network.callAPI('players');
      if (jsonResponse.containsKey('result')) {
        final result = jsonResponse['result'];
        if (result is List) {
          if (mounted) {
            setState(() {
              _onlinePlayers = List<Map<String, dynamic>>.from(
                result.map((player) => {
                  'id': player['id'],
                  'name': player['name'],
                })
              );
              _isLoadingPlayers = false;
            });
          }
          LogUtil.log('获取在线玩家成功: ${_onlinePlayers.length} 名玩家', level: 'INFO');
        } else {
          throw Exception('返回的玩家数据格式无效');
        }
      } else if (jsonResponse.containsKey('error')) {
        throw Exception('服务器错误: ${jsonResponse['error']}');
      } else {
        throw Exception('无效的响应格式');
      }
    } catch (e) {
      LogUtil.log('获取在线玩家失败: $e', level: 'ERROR');
      if (mounted) {
        setState(() {
          _isLoadingPlayers = false;
          _playersErrorMessage = '获取玩家列表失败: ${_formatErrorMessage(e)}';
        });
      }
    }
  }

  // 获取封禁列表
  Future<void> _fetchBanList() async {
    if (!mounted) return;
    setState(() {
      _isLoadingBans = true;
      _bansErrorMessage = '';
    });
    try {
      final jsonResponse = await widget.network.callAPI('bans');
      if (jsonResponse.containsKey('result')) {
        final result = jsonResponse['result'];
        if (result is List) {
          if (mounted) {
            setState(() {
              _bannedPlayers = List<Map<String, dynamic>>.from(
                result.map((ban) => Map<String, dynamic>.from(ban))
              );
              _isLoadingBans = false;
            });
          }
          LogUtil.log('获取封禁列表成功: ${_bannedPlayers.length} 名封禁玩家', level: 'INFO');
        } else {
          throw Exception('返回的封禁数据格式无效');
        }
      } else if (jsonResponse.containsKey('error')) {
        throw Exception('服务器错误: ${jsonResponse['error']}');
      } else {
        throw Exception('无效的响应格式');
      }
    } catch (e) {
      LogUtil.log('获取封禁列表失败: $e', level: 'ERROR');
      if (mounted) {
        setState(() {
          _isLoadingBans = false;
          _bansErrorMessage = '获取封禁列表失败: ${_formatErrorMessage(e)}';
        });
      }
    }
  }

  // 获取 IP 封禁列表
  Future<void> _fetchIpBanList() async {
    if (!mounted) return;
    setState(() {
      _isLoadingIpBans = true;
      _ipBansErrorMessage = '';
    });
    try {
      final jsonResponse = await widget.network.callAPI('ip_bans');
      if (jsonResponse.containsKey('result')) {
        final result = jsonResponse['result'];
        if (result is List) {
          if (mounted) {
            setState(() {
              _ipBannedList = List<Map<String, dynamic>>.from(
                result.map((ban) => Map<String, dynamic>.from(ban))
              );
              _isLoadingIpBans = false;
            });
          }
          LogUtil.log('获取 IP 封禁列表成功: ${_ipBannedList.length} 个 IP 封禁', level: 'INFO');
        } else {
          throw Exception('返回的 IP 封禁数据格式无效');
        }
      } else if (jsonResponse.containsKey('error')) {
        throw Exception('服务器错误: ${jsonResponse['error']}');
      } else {
        throw Exception('无效的响应格式');
      }
    } catch (e) {
      LogUtil.log('获取 IP 封禁列表失败: $e', level: 'ERROR');
      if (mounted) {
        setState(() {
          _isLoadingIpBans = false;
          _ipBansErrorMessage = '获取 IP 封禁列表失败: ${_formatErrorMessage(e)}';
        });
      }
    }
  }

  // 获取管理员列表
  Future<void> _fetchOperatorList() async {
    if (!mounted) return;
    setState(() {
      _isLoadingOperators = true;
      _operatorsErrorMessage = '';
    });
    try {
      final jsonResponse = await widget.network.callAPI('operators');
      if (jsonResponse.containsKey('result')) {
        final result = jsonResponse['result'];
        if (result is List) {
          if (mounted) {
            setState(() {
              _operatorList = List<Map<String, dynamic>>.from(
                result.map((op) => Map<String, dynamic>.from(op))
              );
              _isLoadingOperators = false;
            });
          }
          LogUtil.log('获取管理员列表成功: ${_operatorList.length} 名管理员', level: 'INFO');
        } else {
          throw Exception('返回的管理员数据格式无效');
        }
      } else if (jsonResponse.containsKey('error')) {
        throw Exception('服务器错误: ${jsonResponse['error']}');
      } else {
        throw Exception('无效的响应格式');
      }
    } catch (e) {
      LogUtil.log('获取管理员列表失败: $e', level: 'ERROR');
      if (mounted) {
        setState(() {
          _isLoadingOperators = false;
          _operatorsErrorMessage = '获取管理员列表失败: ${_formatErrorMessage(e)}';
        });
      }
    }
  }

  // 获取白名单列表
  Future<void> _fetchAllowlist() async {
    if (!mounted) return;
    setState(() {
      _isLoadingAllowlist = true;
      _allowlistErrorMessage = '';
    });
    try {
      final jsonResponse = await widget.network.callAPI('allowlist');
      if (jsonResponse.containsKey('result')) {
        final result = jsonResponse['result'];
        if (result is List) {
          if (mounted) {
            setState(() {
              _allowlist = List<Map<String, dynamic>>.from(
                result.map((player) => Map<String, dynamic>.from(player))
              );
              _isLoadingAllowlist = false;
            });
          }
          LogUtil.log('获取白名单列表成功: ${_allowlist.length} 名玩家', level: 'INFO');
        } else {
          throw Exception('返回的白名单数据格式无效');
        }
      } else if (jsonResponse.containsKey('error')) {
        throw Exception('服务器错误: ${jsonResponse['error']}');
      } else {
        throw Exception('无效的响应格式');
      }
    } catch (e) {
      LogUtil.log('获取白名单列表失败: $e', level: 'ERROR');
      if (mounted) {
        setState(() {
          _isLoadingAllowlist = false;
          _allowlistErrorMessage = '获取白名单列表失败: ${_formatErrorMessage(e)}';
        });
      }
    }
  }

  // 格式化错误信息
  String _formatErrorMessage(Object error) {
    if (error is SocketException) {
      return '网络连接错误，请检查网络设置或服务器地址';
    } else if (error is TimeoutException) {
      return '连接超时，服务器可能未响应';
    } else if (error is FormatException) {
      return '数据格式错误，服务器返回了无效数据';
    } else if (error.toString().contains('WebSocket')) {
      return 'WebSocket连接失败，请确认服务器支持WebSocket';
    } else if (error.toString().contains('certificate') ||
              error.toString().contains('SSL') ||
              error.toString().contains('TLS')) {
      return '证书验证失败，您可以尝试启用"允许不安全证书"选项';
    } else {
      return '发生未知错误: ${error.toString()}';
    }
  }

  // 显示私聊对话框
  Future<void> _showPrivateMessageDialog(Map<String, dynamic> player) async {
    final playerName = player['name'] ?? '未知玩家';
    final playerUUID = player['id'] ?? '未知UUID';
    final messageController = TextEditingController();
    final translateParamsController = TextEditingController();
    final currentContext = context;
    bool isTranslatable = false;
    bool isOverlay = false;
      showDialog(
      context: currentContext,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('发送私信给 $playerName',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text('消息类型:', style: TextStyle(fontWeight: FontWeight.bold)),
                      ChoiceChip(
                        label: const Text('普通文本'),
                        selected: !isTranslatable,
                        onSelected: (selected) {
                          setState(() {
                            isTranslatable = !selected;
                          });
                        },
                      ),
                      ChoiceChip(
                        label: const Text('本地化文本'),
                        selected: isTranslatable,
                        onSelected: (selected) {
                          setState(() {
                            isTranslatable = selected;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: messageController,
                    decoration: InputDecoration(
                      labelText: isTranslatable ? '本地化键名' : '私信内容',
                      hintText: isTranslatable ? 'zh_cn' : '输入要发送的消息',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  if (isTranslatable)
                    Column(
                      children: [
                        const SizedBox(height: 16),
                        TextField(
                          controller: translateParamsController,
                          decoration: const InputDecoration(
                            labelText: '参数列表',
                            hintText: '使用逗号分隔多个参数，例如: 参数1,参数2',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: isOverlay,
                        onChanged: (value) {
                          setState(() {
                            isOverlay = value ?? false;
                          });
                        },
                      ),
                      const Flexible(child: Text('在动作栏显示')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('取消'),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () async {
                          // 原有逻辑保持不变...
                          final message = messageController.text.trim();
                          if (message.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('请输入消息内容')),
                            );
                            return;
                          }
                          Navigator.pop(context);
                          try {
                            final Map<String, dynamic> messageData = {};
                            if (isTranslatable) {
                              messageData['translatable'] = message;
                              final paramsText = translateParamsController.text.trim();
                              if (paramsText.isNotEmpty) {
                                List<String> params = paramsText.split(',')
                                    .map((e) => e.trim())
                                    .where((e) => e.isNotEmpty)
                                    .toList();
                                if (params.isNotEmpty) {
                                  messageData['translatableParams'] = params;
                                }
                              }
                            } else {
                              messageData['literal'] = message;
                            }
                            await widget.network.callAPI('server/system_message', [
                              {
                                'message': messageData,
                                'overlay': isOverlay,
                                'receivingPlayers': [
                                  {
                                    "name": playerName,
                                    "id": playerUUID
                                  }
                                ]
                              }
                            ]);
                            if (mounted) {
                              ScaffoldMessenger.of(currentContext).showSnackBar(
                                SnackBar(content: Text('私信已发送给 $playerName')),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(currentContext).showSnackBar(
                                SnackBar(content: Text('发送私信失败: ${_formatErrorMessage(e)}')),
                              );
                            }
                          }
                        },
                        child: const Text('发送'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 踢出玩家确认对话框
  Future<void> _showKickConfirmDialog(Map<String, dynamic> player) async {
    final playerName = player['name'] ?? '未知玩家';
    final playerUUID = player['id'] ?? '未知UUID';
    final currentContext = context;
    final reasonController = TextEditingController();
    showDialog(
      context: currentContext,
      builder: (context) => AlertDialog(
        title: const Text('踢出玩家'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('确定要踢出玩家 "$playerName" 吗？'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: '踢出理由',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final reason = reasonController.text.trim();
              try {
                await widget.network.callAPI('players/kick', [
                  {
                    "message": {"literal": reason.isEmpty ? "来自MCB的踢出" : reason},
                    "players": [{
                      "name": playerName,
                      "id": playerUUID
                  }]
                  }
                ]);
                if (mounted) {
                  ScaffoldMessenger.of(currentContext).showSnackBar(
                    SnackBar(content: Text(reason.isEmpty
                        ? '已踢出玩家: $playerName'
                        : '已踢出玩家: $playerName (理由: $reason)')),
                  );
                  Future.delayed(const Duration(seconds: 1), _fetchOnlinePlayers);
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(currentContext).showSnackBar(
                    SnackBar(content: Text('踢出失败: ${_formatErrorMessage(e)}')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('踢出'),
          ),
        ],
      ),
    );
  }

    // 封禁玩家确认对话框
  Future<void> _showBanConfirmDialog(Map<String, dynamic> player) async {
    final playerName = player['name'] ?? '未知玩家';
    final playerUUID = player['id'] ?? '未知UUID';
    final currentContext = context;
    final reasonController = TextEditingController();
    final sourceController = TextEditingController();
    showDialog(
      context: currentContext,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('封禁玩家'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('确定要封禁玩家 "$playerName" 吗？\n这将阻止该玩家重新加入服务器。'),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: '封禁理由',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: sourceController,
                  decoration: const InputDecoration(
                    labelText: '封禁执行者',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final reason = reasonController.text.trim();
                try {
                  await widget.network.callAPI('bans/add', [[
                    {
                      "reason": reason.isEmpty ? "来自MCB的封禁" : reason,
                      "source": sourceController.text.trim().isEmpty ? "MCB客户端" : sourceController.text.trim(),
                      "expires": null,
                      "player": {
                        "name": playerName,
                        "id": playerUUID
                      }
                    }
                  ]]);
                  if (mounted) {
                    String message = reason.isEmpty
                        ? '已封禁玩家: $playerName'
                        : '已封禁玩家: $playerName (理由: $reason)';
                    ScaffoldMessenger.of(currentContext).showSnackBar(
                      SnackBar(content: Text(message)),
                    );
                    Future.delayed(const Duration(seconds: 1), _fetchOnlinePlayers);
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(currentContext).showSnackBar(
                      SnackBar(content: Text('封禁失败: ${_formatErrorMessage(e)}')),
                    );
                  }
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('封禁'),
            ),
          ],
        ),
      ),
    );
  }

  // 解除 IP 封禁确认对话框
  Future<void> _showUnbanIpConfirmDialog(String ip) async {
    final currentContext = context;
    showDialog(
      context: currentContext,
      builder: (context) => AlertDialog(
        title: const Text('解除 IP 封禁'),
        content: Text('确定要解除对 IP "$ip" 的封禁吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await widget.network.callAPI('ip_bans/remove', [ip]);
                if (mounted) {
                  ScaffoldMessenger.of(currentContext).showSnackBar(
                    SnackBar(content: Text('已解除对 IP $ip 的封禁')),
                  );
                  _fetchIpBanList();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(currentContext).showSnackBar(
                    SnackBar(content: Text('解除 IP 封禁失败: ${_formatErrorMessage(e)}')),
                  );
                }
              }
            },
            child: const Text('解除封禁'),
          ),
        ],
      ),
    );
  }

  // 清空 IP 封禁列表确认对话框
  Future<void> _showClearIpBansConfirmDialog() async {
    final currentContext = context;
    final ipBanCount = _ipBannedList.length;
    showDialog(
      context: currentContext,
      builder: (context) => AlertDialog(
        title: const Text('清空 IP 封禁列表'),
        content: Text('确定要清空所有 IP 封禁记录吗？\n这将解除对 $ipBanCount 个 IP 的封禁，此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await widget.network.callAPI('ip_bans/clear');
                if (mounted) {
                  ScaffoldMessenger.of(currentContext).showSnackBar(
                    const SnackBar(content: Text('已清空所有 IP 封禁记录')),
                  );
                  _fetchIpBanList();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(currentContext).showSnackBar(
                    SnackBar(content: Text('清空 IP 封禁列表失败: ${_formatErrorMessage(e)}')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('清空'),
          ),
        ],
      ),
    );
  }

  // 添加解除封禁确认对话框方法
  Future<void> _showUnbanConfirmDialog(Map<String, dynamic> player) async {
    final playerName = player['name'] ?? '未知玩家';
    final playerUUID = player['id'] ?? '未知UUID';
    final currentContext = context;
    showDialog(
      context: currentContext,
      builder: (context) => AlertDialog(
        title: const Text('解除封禁'),
        content: Text('确定要解除对玩家 "$playerName" 的封禁吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await widget.network.callAPI('bans/remove', [[
                  {
                    "player": [{
                      "name": playerName,
                      "id": playerUUID
                    }]
                  }
                ]]);
                if (mounted) {
                  ScaffoldMessenger.of(currentContext).showSnackBar(
                    SnackBar(content: Text('已解除对玩家 $playerName 的封禁')),
                  );
                  _fetchBanList();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(currentContext).showSnackBar(
                    SnackBar(content: Text('解除封禁失败: ${_formatErrorMessage(e)}')),
                  );
                }
              }
            },
            child: const Text('解除封禁'),
          ),
        ],
      ),
    );
  }

  // 清空封禁列表确认对话框
  Future<void> _showClearBansConfirmDialog() async {
    final currentContext = context;
    final bannedCount = _bannedPlayers.length;
    showDialog(
      context: currentContext,
      builder: (context) => AlertDialog(
        title: const Text('清空封禁列表'),
        content: Text('确定要清空所有封禁记录吗？\n这将解除对 $bannedCount 名玩家的封禁，此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await widget.network.callAPI('bans/clear');
                if (mounted) {
                  ScaffoldMessenger.of(currentContext).showSnackBar(
                    const SnackBar(content: Text('已清空所有封禁记录')),
                  );
                  _fetchBanList();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(currentContext).showSnackBar(
                    SnackBar(content: Text('清空封禁列表失败: ${_formatErrorMessage(e)}')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('清空'),
          ),
        ],
      ),
    );
  }

  // 移除管理员确认对话框
  Future<void> _showRemoveOperatorConfirmDialog(Map<String, dynamic> player) async {
    final playerName = player['name'] ?? '未知玩家';
    final playerUUID = player['id'] ?? '未知UUID';
    final currentContext = context;
    showDialog(
      context: currentContext,
      builder: (context) => AlertDialog(
        title: const Text('移除管理员'),
        content: Text('确定要移除 "$playerName" 的管理员权限吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await widget.network.callAPI('operators/remove', [
                  {
                    "player": {
                      "name": playerName,
                      "id": playerUUID
                    }
                  }
                ]);
                if (mounted) {
                  ScaffoldMessenger.of(currentContext).showSnackBar(
                    SnackBar(content: Text('已移除 $playerName 的管理员权限')),
                  );
                  _fetchOperatorList();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(currentContext).showSnackBar(
                    SnackBar(content: Text('移除管理员失败: ${_formatErrorMessage(e)}')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('移除'),
          ),
        ],
      ),
    );
  }

  // 添加管理员对话框
  Future<void> _showAddOperatorDialog(Map<String, dynamic> player) async {
    final playerName = player['name'] ?? '未知玩家';
    final playerUUID = player['id'] ?? '未知UUID';
    final currentContext = context;
    int permissionLevel = 4;
    bool bypassPlayerLimit = false;
    showDialog(
      context: currentContext,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('设置管理员'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('设置 "$playerName" 为服务器管理员'),
              const SizedBox(height: 16),
              const Text('权限级别:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment<int>(
                    value: 4,
                    label: Text('4级'),
                  ),
                  ButtonSegment<int>(
                    value: 3,
                    label: Text('3级'),
                  ),
                  ButtonSegment<int>(
                    value: 2,
                    label: Text('2级'),
                  ),
                  ButtonSegment<int>(
                    value: 1,
                    label: Text('1级'),
                  ),
                ],
                selected: {permissionLevel},
                onSelectionChanged: (Set<int> newSelection) {
                  setState(() {
                    permissionLevel = newSelection.first;
                  });
                },
              ),
              const Divider(),
              CheckboxListTile(
                title: const Text('允许绕过服务器玩家上限'),
                subtitle: const Text('即使服务器已满，也可以加入'),
                value: bypassPlayerLimit,
                onChanged: (value) {
                  setState(() {
                    bypassPlayerLimit = value!;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await widget.network.callAPI('operators/add', [[
                    {
                      "player": {
                        "name": playerName,
                        "id": playerUUID
                      },
                      "permissionLevel": permissionLevel,
                      "bypassesPlayerLimit": bypassPlayerLimit
                    }
                  ]]);
                  if (mounted) {
                    ScaffoldMessenger.of(currentContext).showSnackBar(
                      SnackBar(content: Text('已将 $playerName 设置为管理员 (权限级别: $permissionLevel)')),
                    );
                    _fetchOperatorList();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(currentContext).showSnackBar(
                      SnackBar(content: Text('设置管理员失败: ${_formatErrorMessage(e)}')),
                    );
                  }
                }
              },
              child: const Text('确定'),
            ),
          ],
        ),
      ),
    );
  }

  // 清空管理员列表确认对话框
  Future<void> _showClearOperatorsConfirmDialog() async {
    final currentContext = context;
    final operatorCount = _operatorList.length;
    showDialog(
      context: currentContext,
      builder: (context) => AlertDialog(
        title: const Text('清空管理员列表'),
        content: Text('确定要清空所有管理员记录吗？\n这将解除对 $operatorCount 名玩家的管理员身份，此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await widget.network.callAPI('operators/clear');
                if (mounted) {
                  ScaffoldMessenger.of(currentContext).showSnackBar(
                    const SnackBar(content: Text('已清空所有管理员')),
                  );
                  _fetchOperatorList();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(currentContext).showSnackBar(
                    SnackBar(content: Text('清空管理员列表失败: ${_formatErrorMessage(e)}')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('清空'),
          ),
        ],
      ),
    );
  }

  // 添加玩家到白名单对话框
  Future<void> _showAddToAllowlistDialog(Map<String, dynamic> player) async {
    final playerName = player['name'] ?? '未知玩家';
    final playerUUID = player['id'] ?? '未知UUID';
    final currentContext = context;
    showDialog(
      context: currentContext,
      builder: (context) => AlertDialog(
        title: const Text('添加到白名单'),
        content: Text('确定将玩家 "$playerName" 添加到白名单吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await widget.network.callAPI('allowlist/add', [[
                  {
                    "name": playerName,
                    "id": playerUUID
                  }
                ]]);
                if (mounted) {
                  ScaffoldMessenger.of(currentContext).showSnackBar(
                    SnackBar(content: Text('已将 $playerName 添加到白名单')),
                  );
                  _fetchAllowlist();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(currentContext).showSnackBar(
                    SnackBar(content: Text('添加到白名单失败: ${_formatErrorMessage(e)}')),
                  );
                }
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  // 添加玩家到白名单对话框
  Future<void> _showAddCustomizedAllowlistDialog() async {
    final nameController = TextEditingController();
    final uuidController = TextEditingController();
    final currentContext = context;
    final formKey = GlobalKey<FormState>();
    // 生成UUID
    String generateOfflinePlayerUUID(String playerName) {
      var digest = md5.convert(utf8.encode('OfflinePlayer:$playerName'));
      String hash = digest.toString();
      String uuid = '${hash.substring(0, 8)}-${hash.substring(8, 12)}-${hash.substring(12, 16)}-${hash.substring(16, 20)}-${hash.substring(20, 32)}';
      return uuid;
    }
    showDialog(
      context: currentContext,
      builder: (context) => AlertDialog(
        title: const Text('添加玩家到白名单'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '玩家名称',
                  hintText: '输入玩家的游戏名称',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '玩家名称不能为空';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: uuidController,
                      decoration: const InputDecoration(
                        labelText: '玩家UUID',
                        hintText: '格式:8-4-4-4-12位字符',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'UUID不能为空';
                        }
                        // 验证UUID格式
                        final uuidRegex = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$');
                        if (!uuidRegex.hasMatch(value.trim())) {
                          return 'UUID格式不正确';
                        }
                        return null;
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.password),
                    tooltip: '生成UUID',
                    onPressed: () {
                      final name = nameController.text.trim();
                      if (name.isNotEmpty) {
                        uuidController.text = generateOfflinePlayerUUID(name);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('请先输入玩家名称')),
                        );
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text('注意: UUID应为32位带分割线数字与小写字母混合的字符串,点击右侧按钮生成离线模式下玩家的UUID'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              if (formKey.currentState?.validate() != true) {
                return;
              }
              Navigator.pop(context);
              final playerName = nameController.text.trim();
              final playerUUID = uuidController.text.trim();
              try {
                await widget.network.callAPI('allowlist/add', [[
                  {
                    "name": playerName,
                    "id": playerUUID
                  }
                ]]);
                if (mounted) {
                  ScaffoldMessenger.of(currentContext).showSnackBar(
                    SnackBar(content: Text('已将 $playerName 添加到白名单')),
                  );
                  _fetchAllowlist();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(currentContext).showSnackBar(
                    SnackBar(content: Text('添加到白名单失败: ${_formatErrorMessage(e)}')),
                  );
                }
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  // 从白名单移除玩家对话框
  Future<void> _showRemoveFromAllowlistDialog(Map<String, dynamic> player) async {
    final playerName = player['name'] ?? '未知玩家';
    final playerUUID = player['id'] ?? '未知UUID';
    final currentContext = context;
    showDialog(
      context: currentContext,
      builder: (context) => AlertDialog(
        title: const Text('从白名单移除'),
        content: Text('确定将玩家 "$playerName" 从白名单中移除吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                // 从白名单移除API调用
                await widget.network.callAPI('allowlist/remove', [[
                  {
                    "name": playerName,
                    "id": playerUUID
                  }
                ]]);
                if (mounted) {
                  ScaffoldMessenger.of(currentContext).showSnackBar(
                    SnackBar(content: Text('已将 $playerName 从白名单中移除')),
                  );
                  _fetchAllowlist();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(currentContext).showSnackBar(
                    SnackBar(content: Text('从白名单移除失败: ${_formatErrorMessage(e)}')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('移除'),
          ),
        ],
      ),
    );
  }

  // 清空白名单确认对话框
  Future<void> _showClearAllowlistConfirmDialog() async {
    final currentContext = context;
    final allowlistCount = _allowlist.length;
    showDialog(
      context: currentContext,
      builder: (context) => AlertDialog(
        title: const Text('清空白名单'),
        content: Text('确定要清空整个白名单吗？\n这将移除 $allowlistCount 名玩家的白名单权限，此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await widget.network.callAPI('allowlist/clear');
                if (mounted) {
                  ScaffoldMessenger.of(currentContext).showSnackBar(
                    const SnackBar(content: Text('已清空白名单')),
                  );
                  _fetchAllowlist();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(currentContext).showSnackBar(
                    SnackBar(content: Text('清空白名单失败: ${_formatErrorMessage(e)}')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('清空'),
          ),
        ],
      ),
    );
  }

  // 保存服务器
  Future<void> _saveServer() async {
    try {
      await widget.network.callAPI('server/save');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('服务器保存命令已发送')),
        );
        Future.delayed(const Duration(seconds: 2), _fetchServerStatus);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: ${_formatErrorMessage(e)}')),
        );
      }
    }
  }

  // 停止服务器
  Future<void> _stopServer() async {
    try {
      await widget.network.callAPI('server/stop');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('服务器停止命令已发送')),
        );
        Future.delayed(const Duration(seconds: 2), _fetchServerStatus);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('停止失败: ${_formatErrorMessage(e)}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _fetchServerStatus,
      child: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _statusMessage.isNotEmpty
          ? _buildErrorView()
          : _buildServerStatusView(),
    );
  }

  // 错误视图组件
  Widget _buildErrorView() {
    return Center(
      child: ListView(
        shrinkWrap: true,
        children: [
          const SizedBox(height: 16),
          Text(
            _statusMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.red[700],
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
              onPressed: _fetchServerStatus,
            ),
          ),
        ],
      ),
    );
  }

  // 显示服务器状态信息
  Widget _buildServerStatusView() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('服务器信息', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                _buildInfoRow('服务器名称', widget.name),
                _buildInfoRow('RPC地址', '${widget.address}:${widget.port}'),
                _buildInfoRow('连接状态', widget.isConnected ? '已连接' : '未连接'),
              ],
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('服务器状态', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ..._buildStatusDetails(),
              ],
            ),
          ),
        ),
        if (widget.isConnected)
        _buildPlayersCard(),
        _buildSendMessageCard(),
        _buildBanListCard(),
        _buildOperatorListCard(),
        _buildAllowlistCard(),
        _buildIpBanListCard(),
        _buildControlCard(),
      ],
    );
  }

  // 发送消息卡片
  Widget _buildSendMessageCard() {
    final TextEditingController messageController = TextEditingController();
    final TextEditingController translateParamsController = TextEditingController();
    bool isTranslatable = false;
    bool isOverlay = false;
    return StatefulBuilder(
      builder: (context, setState) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('发送全服消息', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Wrap(
                  children: [
                    const Text('消息类型:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 16),
                    ChoiceChip(
                      label: const Text('普通文本'),
                      selected: !isTranslatable,
                      onSelected: (selected) {
                        setState(() {
                          isTranslatable = !selected;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('本地化文本'),
                      selected: isTranslatable,
                      onSelected: (selected) {
                        setState(() {
                          isTranslatable = selected;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: messageController,
                  decoration: InputDecoration(
                    labelText: isTranslatable ? '本地化键名' : '文本消息',
                    hintText: isTranslatable ? 'zh_cn' : '输入要发送的消息',
                    border: const OutlineInputBorder(),
                  ),
                ),
                if (isTranslatable)
                  Column(
                    children: [
                      const SizedBox(height: 16),
                      TextField(
                        controller: translateParamsController,
                        decoration: const InputDecoration(
                          labelText: '参数列表',
                          hintText: '使用逗号分隔多个参数，例如: 参数1,参数2',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: isOverlay,
                      onChanged: (value) {
                        setState(() {
                          isOverlay = value ?? false;
                        });
                      },
                    ),
                    const Text('在动作栏显示'),
                  ],
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.send),
                    label: const Text('发送'),
                    onPressed: () async {
                      final currentContext = context;
                      final message = messageController.text.trim();
                      if (message.isEmpty) return;
                      try {
                        final Map<String, dynamic> messageData = {};
                        if (isTranslatable) {
                          messageData['translatable'] = message;
                          final paramsText = translateParamsController.text.trim();
                          if (paramsText.isNotEmpty) {
                            List<String> params = paramsText.split(',')
                                .map((e) => e.trim())
                                .where((e) => e.isNotEmpty)
                                .toList();
                            if (params.isNotEmpty) {
                              messageData['translatableParams'] = params;
                            }
                          }
                        } else {
                          messageData['literal'] = message;
                        }
                        await widget.network.callAPI('server/system_message', [
                          {
                            'message': messageData,
                            'overlay': isOverlay
                          }
                        ]);
                        if (mounted) {
                          ScaffoldMessenger.of(currentContext).showSnackBar(
                            const SnackBar(content: Text('消息已发送')),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(currentContext).showSnackBar(
                            SnackBar(content: Text('发送失败: ${_formatErrorMessage(e)}')),
                          );
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  // 构建玩家列表卡片
  Widget _buildPlayersCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('在线玩家', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _isLoadingPlayers ? null : _fetchOnlinePlayers,
                  tooltip: '刷新玩家列表',
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_isLoadingPlayers)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_playersErrorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _playersErrorMessage,
                  style: TextStyle(color: Colors.red[700]),
                ),
              )
            else if (_onlinePlayers.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('当前没有玩家在线'),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _onlinePlayers.length,
                itemBuilder: (context, index) {
                  final player = _onlinePlayers[index];
                  return ListTile(
                    title: Text(player['name'] ?? '未知玩家'),
                    subtitle: Text('UUID: ${player['id'] ?? '未知UUID'}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () => _showPlayerActions(player),
                      tooltip: '玩家操作',
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  // 显示玩家操作菜单
  Future<void> _showPlayerActions(Map<String, dynamic> player) async {
    final currentContext = context;
    showModalBottomSheet(
      context: currentContext,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.message),
                title: Text('私信 ${player['name']}'),
                onTap: () {
                  Navigator.pop(context);
                  _showPrivateMessageDialog(player);
                },
              ),
              ListTile(
                leading: const Icon(Icons.group),
                title: Text('将 ${player['name']} 加入白名单'),
                onTap: () {
                  Navigator.pop(context);
                  _showAddToAllowlistDialog(player);
                },
              ),
              ListTile(
                leading: const Icon(Icons.how_to_reg),
                title: Text('将 ${player['name']} 设为管理员'),
                onTap: () {
                  Navigator.pop(context);
                  _showAddOperatorDialog(player);
                },
              ),
              ListTile(
                leading: const Icon(Icons.person_remove),
                title: Text('将 ${player['name']} 踢出'),
                onTap: () async {
                  Navigator.pop(context);
                  await _showKickConfirmDialog(player);
                },
              ),
              ListTile(
                leading: const Icon(Icons.block),
                title: Text('将 ${player['name']} 封禁'),
                onTap: () async {
                  Navigator.pop(context);
                  await _showBanConfirmDialog(player);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // 封禁列表卡片
  Widget _buildBanListCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('封禁列表', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete_sweep),
                      onPressed: _bannedPlayers.isEmpty || _isLoadingBans ? null : _showClearBansConfirmDialog,
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _isLoadingBans ? null : _fetchBanList,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_isLoadingBans)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_bansErrorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _bansErrorMessage,
                  style: TextStyle(color: Colors.red[700]),
                ),
              )
            else if (_bannedPlayers.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('当前没有封禁的玩家'),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _bannedPlayers.length,
                itemBuilder: (context, index) {
                  final ban = _bannedPlayers[index];
                  final player = ban['player'] as Map<String, dynamic>;
                  final playerName = player['name'] ?? '未知玩家';
                  String reasonText = '未指定原因';
                  if (ban.containsKey('reason')) {
                    if (ban['reason'] is Map) {
                      reasonText = (ban['reason'] as Map).containsKey('literal')
                          ? ban['reason']['literal'].toString()
                          : ban['reason'].toString();
                    } else {
                      reasonText = ban['reason'].toString();
                    }
                  }
                  final source = ban['source'] ?? '未知来源';
                  String expiryText = '永久封禁';
                  if (ban.containsKey('expires') && ban['expires'] != null) {
                    expiryText = '到期时间: ${ban['expires']}';
                  }
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  playerName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _showUnbanConfirmDialog(player),
                                tooltip: '解除封禁',
                              ),
                            ],
                          ),
                          const Divider(),
                          _buildInfoRow('ID', player['id'] ?? '未知ID'),
                          _buildInfoRow('原因', reasonText),
                          _buildInfoRow('执行人', source),
                          _buildInfoRow('状态', expiryText),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  // IP 封禁列表卡片
  Widget _buildIpBanListCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('IP 封禁列表', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete_sweep),
                      onPressed: _ipBannedList.isEmpty || _isLoadingIpBans ? null : _showClearIpBansConfirmDialog,
                      tooltip: '清空 IP 封禁列表',
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _isLoadingIpBans ? null : _fetchIpBanList,
                      tooltip: '刷新 IP 封禁列表',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_isLoadingIpBans)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_ipBansErrorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _ipBansErrorMessage,
                  style: TextStyle(color: Colors.red[700]),
                ),
              )
            else if (_ipBannedList.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('当前没有 IP 被封禁'),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _ipBannedList.length,
                itemBuilder: (context, index) {
                  final ban = _ipBannedList[index];
                  final ip = ban['ip'] ?? '未知 IP';
                  String reasonText = '未指定原因';
                  if (ban.containsKey('reason')) {
                    reasonText = ban['reason'].toString();
                  }
                  final source = ban['source'] ?? '未知来源';
                  String expiryText = '永久封禁';
                  if (ban.containsKey('expires') && ban['expires'] != null) {
                    expiryText = '到期时间: ${ban['expires']}';
                  }
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  ip,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _showUnbanIpConfirmDialog(ip),
                                tooltip: '解除 IP 封禁',
                              ),
                            ],
                          ),
                          const Divider(),
                          _buildInfoRow('原因', reasonText),
                          _buildInfoRow('执行人', source),
                          _buildInfoRow('状态', expiryText),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  // 管理员列表卡片构建
  Widget _buildOperatorListCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('管理员列表', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                  IconButton(
                      icon: const Icon(Icons.delete_sweep),
                      onPressed: _operatorList.isEmpty || _isLoadingOperators ? null : _showClearOperatorsConfirmDialog,
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _isLoadingOperators ? null : _fetchOperatorList,
                  ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_isLoadingOperators)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_operatorsErrorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _operatorsErrorMessage,
                  style: TextStyle(color: Colors.red[700]),
                ),
              )
            else if (_operatorList.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('当前没有管理员'),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _operatorList.length,
                itemBuilder: (context, index) {
                  final op = _operatorList[index];
                  final player = op['player'] as Map<String, dynamic>;
                  final playerName = player['name'] ?? '未知玩家';
                  final permLevel = op['permissionLevel'] ?? 0;
                  final bypassLimit = op['bypassesPlayerLimit'] ?? false;
                  String permLevelText = permLevel.toString();
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  playerName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _showRemoveOperatorConfirmDialog(player),
                                tooltip: '移除管理员',
                              ),
                            ],
                          ),
                          const Divider(),
                          _buildInfoRow('UUID', player['id'] ?? '未知ID'),
                          _buildInfoRow('权限等级', permLevelText),
                          _buildInfoRow('玩家上限', bypassLimit ? '可绕过' : '不可绕过'),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  // 控制卡片
  Widget _buildControlCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('服务器控制', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('保存服务器'),
                    onPressed: _saveServer,
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.stop),
                    label: const Text('停止服务器'),
                    onPressed: _stopServer,
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

  // 服务器信息
  List<Widget> _buildStatusDetails() {
    final List<Widget> widgets = [];
    try {
      if (_serverStatus is Map) {
        if (_serverStatus.containsKey('started')) {
          final bool started = _serverStatus['started'] as bool;
          widgets.add(
            _buildInfoRow(
              '运行状态',
              started ? '正在运行' : '未运行',
            ),
          );
        }
        if (_serverStatus.containsKey('version') && _serverStatus['version'] is Map) {
          final Map versionInfo = _serverStatus['version'] as Map;
          if (versionInfo.containsKey('name')) {
            widgets.add(
              _buildInfoRow('游戏版本', versionInfo['name'].toString()),
            );
          }
          if (versionInfo.containsKey('protocol')) {
            widgets.add(
              _buildInfoRow('协议版本', versionInfo['protocol'].toString()),
            );
          }
        }
      }
      if (widgets.isEmpty) {
        widgets.add(const Text('没有可用的状态信息'));
      }
    } catch (e) {
      LogUtil.log('解析服务器状态时出错: $e', level: 'ERROR');
      widgets.add(Text('解析服务器状态时出错: $e', style: const TextStyle(color: Colors.red)));
    }
    return widgets;
  }

  // 白名单列表卡片
  Widget _buildAllowlistCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('白名单', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: _showAddCustomizedAllowlistDialog,
                      tooltip: '添加白名单',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_sweep),
                      onPressed: _allowlist.isEmpty || _isLoadingAllowlist ? null : _showClearAllowlistConfirmDialog,
                      tooltip: '清空白名单',
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _isLoadingAllowlist ? null : _fetchAllowlist,
                      tooltip: '刷新白名单',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_isLoadingAllowlist)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_allowlistErrorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _allowlistErrorMessage,
                  style: TextStyle(color: Colors.red[700]),
                ),
              )
            else if (_allowlist.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('当前白名单为空'),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _allowlist.length,
                itemBuilder: (context, index) {
                  final player = _allowlist[index];
                  final playerName = player['name'] ?? '未知玩家';
                  final playerId = player['id'] ?? '未知ID';
                  final isOnline = _onlinePlayers.any((p) =>
                    p['id'] == playerId || p['name'] == playerName);
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isOnline ? Colors.green : Colors.grey,
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(playerName),
                    subtitle: Text('ID: $playerId'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _showRemoveFromAllowlistDialog(player),
                      tooltip: '从白名单移除',
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  // 信息行组件
  Widget _buildInfoRow(String label, String value, {Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: textColor),
            ),
          ),
        ],
      ),
    );
  }
}