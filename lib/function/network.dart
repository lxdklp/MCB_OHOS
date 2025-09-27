import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'dart:typed_data';
import 'package:mcb/function/log.dart';

/// JSON-RPC 连接状态
enum ConnectionStatus {
  connecting,
  connected,
  disconnected,
  error,
}

// JSON-RPC WebSocket 服务类
class Network {
  final String name;
  final String address;
  final String port;
  final String token;
  final bool useTls;
  final bool unsafe;
  // WebSocket 连接
  WebSocketChannel? _channel;
  bool _isConnected = false;
  bool _isPaused = false;
  bool _disposed = false;
  Timer? _reconnectTimer;
  Timer? _keepAliveTimer;
  final Duration _keepAliveInterval = const Duration(seconds: 30);
  final Duration _reconnectInterval = const Duration(seconds: 3);
  int _requestId = 1;
  final Map<int, Completer<Map<String, dynamic>>> _pendingRequests = {};
  final Duration _requestTimeout = const Duration(seconds: 30);
  void Function(ConnectionStatus, String?)? onStatusChanged;

  // 构造函数
  Network({
    required this.name,
    required this.address,
    required this.port,
    required this.token,
    this.useTls = false,
    this.unsafe = false,
    this.onStatusChanged,
  });
  bool get isConnected => _isConnected;

  // 初始化连接
  Future<void> initialize() async {
    await establishConnection();
    _startKeepAliveTimer();
  }

  // 开始保活定时器
  Future<void> _startKeepAliveTimer() async{
    _keepAliveTimer?.cancel();
    if (_isConnected && !_isPaused && !_disposed) {
      _keepAliveTimer = Timer.periodic(_keepAliveInterval, (_) {
        if (_isConnected && !_isPaused && !_disposed) {
          try {
            callAPI('server/status').catchError((e) {
              LogUtil.log('保持连接活跃失败: $e', level: 'WARNING');
              return <String, dynamic>{};
            });
          } catch (e) {
            LogUtil.log('发送保活请求时出错: $e', level: 'WARNING');
          }
        } else {
          _keepAliveTimer?.cancel();
        }
      });
      LogUtil.log('已启动保活定时器', level: 'DEBUG');
    }
  }

  // 释放资源
  void dispose() async {
    _disposed = true;
    onStatusChanged = null;
    _keepAliveTimer?.cancel();
    _reconnectTimer?.cancel();
    await closeConnection(permanent: true);
    LogUtil.log('$name 的 Network 已释放资源', level: 'INFO');
  }

  // 暂停连接
  Future<void> pauseConnection() async {
    if (_isConnected && !_disposed) {
      _isPaused = true;
      LogUtil.log('暂停WebSocket连接: $address:$port', level: 'INFO');
      _keepAliveTimer?.cancel(); // 暂停时取消保活定时器
      await closeConnection(permanent: false);
    }
  }

  // 恢复连接
  Future<void> resumeConnection() async {
    if (_isPaused && !_isConnected && !_disposed) {
      _isPaused = false;
      LogUtil.log('恢复WebSocket连接: $address:$port', level: 'INFO');
      await establishConnection();
      _startKeepAliveTimer();
    }
  }

  // 建立 WebSocket 连接
  Future<bool> establishConnection() async {
    if (_disposed) {
      LogUtil.log('忽略连接请求,因为Network已销毁', level: 'DEBUG');
      return false;
    }
    if (_isConnected || _channel != null) {
      return true;
    }
    try {
      _notifyStatusChange(ConnectionStatus.connecting, null);
      final protocol = useTls ? 'wss' : 'ws';
      final wsUrl = '$protocol://$address:$port';
      LogUtil.log('建立 ${useTls ? "安全" : "普通"} WebSocket 连接: $wsUrl', level: 'INFO');
      final headers = {
        'authorization': 'Bearer $token',
      };
      if (useTls && unsafe) {
        final httpClient = HttpClient()
          ..badCertificateCallback = (_, __, ___) {
            LogUtil.log('接受不安全证书连接', level: 'WARNING');
            return true;
          };
        _channel = IOWebSocketChannel.connect(
          Uri.parse(wsUrl),
          headers: headers,
          pingInterval: const Duration(seconds: 10),
          customClient: httpClient,
        );
      } else {
        _channel = IOWebSocketChannel.connect(
          Uri.parse(wsUrl),
          headers: headers,
          pingInterval: const Duration(seconds: 10),
        );
      }
      // 监听 WebSocket 消息
      _channel!.stream.listen(
        _handleWebSocketMessage,
        onError: _handleWebSocketError,
        onDone: _handleWebSocketClosed,
      );
      _isConnected = true;
      _notifyStatusChange(ConnectionStatus.connected, null);
      return true;
    } catch (e) {
      LogUtil.log('建立 WebSocket 连接失败: $e', level: 'ERROR');
      await _handleConnectionError(e);
      return false;
    }
  }

  // 关闭 WebSocket 连接
  Future<void> closeConnection({bool permanent = true}) async {
    try {
      // 取消重连计划
      if (permanent) {
        _reconnectTimer?.cancel();
      }
      // 清理所有待处理的请求
      _pendingRequests.forEach((id, completer) {
        if (!completer.isCompleted) {
          completer.completeError('连接已关闭');
        }
      });
      _pendingRequests.clear();
      if (_channel != null) {
        LogUtil.log('正在关闭WebSocket连接: $address:$port', level: 'INFO');
        try {
          await _channel!.sink.close(WebSocketStatus.normalClosure, '正常关闭');
        } catch (e) {
          LogUtil.log('关闭WebSocket连接时出错: $e', level: 'WARNING');
        }
        _channel = null;
      }
      _isConnected = false;
      if (permanent && !_disposed) {
        _notifyStatusChange(ConnectionStatus.disconnected, '连接已关闭');
      }
    } catch (e) {
      LogUtil.log('关闭连接时出错: $e', level: 'WARNING');
    }
  }

  // 处理 WebSocket 消息
  Future<void> _handleWebSocketMessage(dynamic message) async {
    // 如果已销毁，忽略消息处理
    if (_disposed) return;
    try {
      final response = jsonDecode(message.toString());
      LogUtil.log('收到 WebSocket 消息: $response', level: 'INFO');
      if (response is Map<String, dynamic> && response.containsKey('id')) {
        final id = response['id'];
        final completer = _pendingRequests[id];
        if (completer != null && !completer.isCompleted) {
          completer.complete(response);
          _pendingRequests.remove(id);
        }
      }
    } catch (e) {
      LogUtil.log('解析 WebSocket 消息失败: $e', level: 'ERROR');
    }
  }

  // 处理 WebSocket 错误
  Future<void> _handleWebSocketError(Object error) async {
    // 如果已销毁，忽略错误处理
    if (_disposed) return;
    LogUtil.log('WebSocket 错误: $error', level: 'ERROR');
    await _handleConnectionError(error);
  }

  // 处理 WebSocket 连接关闭 - 修改以考虑暂停状态和销毁状态
  Future<void> _handleWebSocketClosed() async {
    // 如果已销毁，忽略关闭处理
    if (_disposed) {
      LogUtil.log('忽略WebSocket连接关闭处理，因为Network已销毁', level: 'DEBUG');
      return;
    }
    LogUtil.log('WebSocket 连接关闭', level: 'INFO');
    _isConnected = false;
    _pendingRequests.forEach((id, completer) {
      if (!completer.isCompleted) {
        completer.completeError('连接已关闭');
      }
    });
    _pendingRequests.clear();
    if (!_isPaused && !_disposed) {
      _notifyStatusChange(ConnectionStatus.disconnected, '连接已关闭');
      await _scheduleReconnection();
    }
  }

  // 安排重新连接
  Future<void> _scheduleReconnection() async {
    _reconnectTimer?.cancel();
    if (!_isPaused && !_disposed) {
      _reconnectTimer = Timer(_reconnectInterval, () async {
        if (!_isConnected && !_isPaused && !_disposed) {
          await establishConnection();
        }
      });
    }
  }

  // 处理连接错误
  Future<void> _handleConnectionError(Object error) async {
    // 如果已销毁，忽略错误处理
    if (_disposed) return;
    _isConnected = false;
    _notifyStatusChange(ConnectionStatus.error, _formatErrorMessage(error));
    if (!_isPaused && !_disposed) {
      await _scheduleReconnection();
    }
  }

  // 通知状态改变
  Future<void> _notifyStatusChange(ConnectionStatus status, String? message) async {
    // 如果已销毁，不要触发回调
    if (_disposed) {
      LogUtil.log('忽略状态更新,因为Network已销毁', level: 'DEBUG');
      return;
    }
    onStatusChanged?.call(status, message);
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

  // 调用 JSON-RPC API
  Future<Map<String, dynamic>> callAPI(String method, [dynamic params]) async {
    // 如果连接已暂停或已销毁，则快速失败
    if (_isPaused) {
      throw Exception('连接已暂停');
    }
    if (_disposed) {
      throw Exception('Network已被销毁');
    }
    if (!_isConnected || _channel == null) {
      await establishConnection();
      if (!_isConnected || _channel == null) {
        throw Exception('无法建立连接');
      }
    }
    final completer = Completer<Map<String, dynamic>>();
    final id = _requestId++;
    // 创建 JSON-RPC 请求
    final request = {
      'jsonrpc': '2.0',
      'method': method,
      'id': id,
    };
    if (params != null) {
      request['params'] = params;
    }
    _pendingRequests[id] = completer;
    try {
      _channel!.sink.add(jsonEncode(request));
      LogUtil.log('发送 RPC 请求: $method', level: 'INFO');
      Timer(_requestTimeout, () {
        if (!completer.isCompleted) {
          _pendingRequests.remove(id);
          completer.completeError(TimeoutException('请求超时: $method'));
        }
      });
      return completer.future;
    } catch (e) {
      _pendingRequests.remove(id);
      LogUtil.log('发送 RPC 请求失败: $e', level: 'ERROR');
      throw Exception('发送请求失败: ${_formatErrorMessage(e)}');
    }
  }
}

// RCON 协议常量
class RconPacketType {
  static const int responseValue = 0;
  static const int execCommand = 2;
  static const int auth = 3;
  static const int authResponse = 2;
}

/// RCON 响应结果类
class RconResponse {
  final int id;
  final String body;
  final bool isSuccess;
  const RconResponse({
    required this.id,
    required this.body,
    required this.isSuccess,
  });
  @override
  String toString() => body;
}

/// RCON 客户端类
class RconClient {
  final String host;
  final int port;
  final String password;
  Socket? _socket;
  bool _authenticated = false;
  int _requestId = 0;
  Completer<RconResponse>? _currentRequest;
  List<int> _buffer = [];
  RconClient(this.host, this.port, this.password);
  bool get isConnected => _socket != null;
  bool get isauthenticated => _authenticated;

  // 连接到RCON服务器
  Future<bool> connect() async {
    if (_socket != null) {
      return _authenticated;
    }
    try {
      LogUtil.log('正在连接RCON: $host:$port', level: 'INFO');
      _socket = await Socket.connect(host, port, timeout: const Duration(seconds: 5));
      // 设置接收数据处理
      _socket!.listen(
        _handleData,
        onError: (error) {
          LogUtil.log('RCON连接错误: $error', level: 'ERROR');
          _failCurrentRequest(error.toString());
          _close();
        },
        onDone: () {
          LogUtil.log('RCON连接已关闭', level: 'INFO');
          _failCurrentRequest('连接已关闭');
          _close();
        },
      );
      // 发送认证请求
      LogUtil.log('发送RCON认证请求...', level: 'INFO');
      final response = await _sendPacket(RconPacketType.auth, password);
      if (response.id == -1) {
        throw Exception('RCON认证失败: 密码可能不正确');
      }
      _authenticated = true;
      LogUtil.log('RCON认证成功', level: 'INFO');
      return true;
    } catch (e) {
      LogUtil.log('RCON连接失败: $e', level: 'ERROR');
      _close();
      return false;
    }
  }

  // 发送RCON命令
  Future<String> sendCommand(String command) async {
    if (!isConnected || !isauthenticated) {
      if (!await connect()) {
        throw Exception('无法连接到RCON服务器');
      }
    }
    try {
      LogUtil.log('发送RCON命令: $command', level: 'INFO');
      final response = await _sendPacket(RconPacketType.execCommand, command);
      return response.body;
    } catch (e) {
      LogUtil.log('发送RCON命令失败: $e', level: 'ERROR');
      throw Exception('发送RCON命令失败: $e');
    }
  }

  // 关闭连接
  Future<void> close() async {
    _close();
  }

  Future<void> _close() async {
    _failCurrentRequest('连接已关闭');
    _socket?.destroy();
    _socket = null;
    _authenticated = false;
    _buffer.clear();
  }

  // 处理当前请求失败
  Future<void> _failCurrentRequest(String message) async {
    if (_currentRequest != null && !_currentRequest!.isCompleted) {
      _currentRequest!.completeError(message);
      _currentRequest = null;
    }
  }

  // 处理接收到的数据
  Future<void> _handleData(List<int> data) async {
    _buffer.addAll(data);
    while (_buffer.length >= 12) {
      final length = _byteListToInt(_buffer.sublist(0, 4));
      if (_buffer.length < length + 4) {
        return;
      }
      // 解析包
      final id = _byteListToInt(_buffer.sublist(4, 8));
      final type = _byteListToInt(_buffer.sublist(8, 12));
      final payload = _buffer.sublist(12, length + 2);
      final body = utf8.decode(payload).replaceAll('\x00', '');
      _buffer = _buffer.sublist(length + 4);
      // 处理响应
      if (_currentRequest != null && !_currentRequest!.isCompleted) {
        if (type == RconPacketType.responseValue || type == RconPacketType.authResponse) {
          _currentRequest!.complete(
            RconResponse(id: id, body: body, isSuccess: id != -1)
          );
          _currentRequest = null;
        }
      }
      if (body.length == 4096 && _currentRequest == null) {
        LogUtil.log('接收到4096字符的响应', level: 'WARNING');
      }
    }
  }

  // 发送RCON数据包
  Future<RconResponse> _sendPacket(int type, String payload) async {
    if (_socket == null) {
      throw Exception('未连接到RCON服务器');
    }
    if (_currentRequest != null) {
      throw Exception('上一个请求尚未完成,RCON协议要求等待响应后再发送新请求');
    }
    _requestId++;
    if (_requestId > 0x7FFFFFFF) {
      _requestId = 1;
    }
    final packet = _createPacket(_requestId, type, payload);
    // 检查数据包大小
    if (packet.length > 1460) {
      throw Exception('RCON数据包过大,不能超过1460字节');
    }
    _currentRequest = Completer<RconResponse>();
    final timeout = Timer(const Duration(seconds: 10), () {
      if (_currentRequest != null && !_currentRequest!.isCompleted) {
        _currentRequest!.completeError('RCON请求超时');
        _currentRequest = null;
      }
    });
    try {
      _socket!.add(packet);
      await _socket!.flush();
      final response = await _currentRequest!.future;
      timeout.cancel();
      return response;
    } catch (e) {
      timeout.cancel();
      rethrow;
    }
  }

  // 创建RCON数据包
  Uint8List _createPacket(int id, int type, String payload) {
    // 计算包长度(负载长度 + 10 = 负载 + 两个null终止符 + 8字节包头)
    final payloadBytes = utf8.encode(payload);
    final length = payloadBytes.length + 10;
    // 创建缓冲区
    final buffer = ByteData(length + 4);
    // 写入长度
    buffer.setInt32(0, length, Endian.little);
    // 写入ID
    buffer.setInt32(4, id, Endian.little);
    // 写入类型
    buffer.setInt32(8, type, Endian.little);
    // 写入数据
    final result = Uint8List(length + 4);
    result.setRange(0, 12, buffer.buffer.asUint8List());
    result.setRange(12, 12 + payloadBytes.length, payloadBytes);
    // 添加两个null字节
    result[12 + payloadBytes.length] = 0;
    result[12 + payloadBytes.length + 1] = 0;
    return result;
  }

  // 将字节列表转换为整数(小端序)
  int _byteListToInt(List<int> bytes) {
    final buffer = ByteData(4);
    for (int i = 0; i < 4; i++) {
      buffer.setUint8(i, bytes[i]);
    }
    return buffer.getInt32(0, Endian.little);
  }
}