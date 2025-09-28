import 'package:flutter/material.dart';
import 'package:mcb/function/log.dart';
import 'package:mcb/function/network.dart';

class ServerSettingPage extends StatefulWidget {
  final String name;
  final String address;
  final String port;
  final String token;
  final Network network;
  final bool isConnected;

  const ServerSettingPage({
    super.key,
    required this.name,
    required this.address,
    required this.port,
    required this.token,
    required this.network,
    required this.isConnected,
  });

  @override
  ServerSettingPageState createState() => ServerSettingPageState();
}

class ServerSettingPageState extends State<ServerSettingPage> {
  bool _isLoading = true;
  String _errorMessage = '';
  bool? _autoSave;
  bool? _enforceAllowlist;
  bool? _useAllowlist;
  bool? _allowFlight;
  bool? _forceGameMode;
  bool? _acceptTransfers;
  bool? _hideOnlinePlayers;
  bool? _statusReplies;
  String? _difficulty;
  String? _gameMode;
  String? _motd;
  List<Map<String, dynamic>> _gameRules = [];
  bool _isLoadingGameRules = false;
  String _gameRulesErrorMessage = '';
  final List<String> _difficultyOptions = ['peaceful', 'easy', 'normal', 'hard'];
  final List<String> _gameModeOptions = ['survival', 'creative', 'adventure', 'spectator'];
  final TextEditingController _motdController = TextEditingController();
  final TextEditingController _maxPlayersController = TextEditingController();
  final TextEditingController _pauseWhenEmptyController = TextEditingController();
  final TextEditingController _playerIdleTimeoutController = TextEditingController();
  final TextEditingController _spawnProtectionController = TextEditingController();
  final TextEditingController _viewDistanceController = TextEditingController();
  final TextEditingController _simulationDistanceController = TextEditingController();
  final TextEditingController _heartbeatIntervalController = TextEditingController();
  final TextEditingController _operatorPermissionController = TextEditingController();
  final TextEditingController _entityBroadcastController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAllSettings();
    _loadGameRules();
  }

  @override
  void dispose() {
    _motdController.dispose();
    _maxPlayersController.dispose();
    _pauseWhenEmptyController.dispose();
    _playerIdleTimeoutController.dispose();
    _spawnProtectionController.dispose();
    _viewDistanceController.dispose();
    _simulationDistanceController.dispose();
    _heartbeatIntervalController.dispose();
    _operatorPermissionController.dispose();
    _entityBroadcastController.dispose();
    super.dispose();
  }

  // 加载所有设置
  Future<void> _loadAllSettings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      await Future.wait([
        _loadBooleanSetting('serversettings/autosave', (value) => _autoSave = value),
        _loadBooleanSetting('serversettings/enforce_allowlist', (value) => _enforceAllowlist = value),
        _loadBooleanSetting('serversettings/use_allowlist', (value) => _useAllowlist = value),
        _loadBooleanSetting('serversettings/allow_flight', (value) => _allowFlight = value),
        _loadBooleanSetting('serversettings/force_game_mode', (value) => _forceGameMode = value),
        _loadBooleanSetting('serversettings/accept_transfers', (value) => _acceptTransfers = value),
        _loadBooleanSetting('serversettings/hide_online_players', (value) => _hideOnlinePlayers = value),
        _loadBooleanSetting('serversettings/status_replies', (value) => _statusReplies = value),
        _loadStringSetting('serversettings/difficulty', (value) => _difficulty = value),
        _loadStringSetting('serversettings/game_mode', (value) => _gameMode = value),
        _loadStringSetting('serversettings/motd', (value) {
          _motd = value;
          _motdController.text = value;
        }),
        _loadIntegerSetting('serversettings/max_players', (value) {
          _maxPlayersController.text = value.toString();
        }),
        _loadIntegerSetting('serversettings/pause_when_empty_seconds', (value) {
          _pauseWhenEmptyController.text = value.toString();
        }),
        _loadIntegerSetting('serversettings/player_idle_timeout', (value) {
          _playerIdleTimeoutController.text = value.toString();
        }),
        _loadIntegerSetting('serversettings/spawn_protection_radius', (value) {
          _spawnProtectionController.text = value.toString();
        }),
        _loadIntegerSetting('serversettings/view_distance', (value) {
          _viewDistanceController.text = value.toString();
        }),
        _loadIntegerSetting('serversettings/simulation_distance', (value) {
          _simulationDistanceController.text = value.toString();
        }),
        _loadIntegerSetting('serversettings/status_heartbeat_interval', (value) {
          _heartbeatIntervalController.text = value.toString();
        }),
        _loadIntegerSetting('serversettings/operator_user_permission_level', (value) {
          _operatorPermissionController.text = value.toString();
        }),
        _loadIntegerSetting('serversettings/entity_broadcast_range', (value) {
          _entityBroadcastController.text = value.toString();
        }),
      ]);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = '加载设置失败: ${_formatErrorMessage(e)}';
        });
      }
    }
  }

  // 加载游戏规则
  Future<void> _loadGameRules() async {
    setState(() {
      _isLoadingGameRules = true;
      _gameRulesErrorMessage = '';
    });
    try {
      final response = await widget.network.callAPI('gamerules');
      if (response.containsKey('result')) {
        final result = response['result'];
        if (result is List) {
          if (mounted) {
            setState(() {
              _gameRules = List<Map<String, dynamic>>.from(
                result.map((rule) => Map<String, dynamic>.from(rule))
              );
              _isLoadingGameRules = false;
            });
          }
          LogUtil.log('获取游戏规则成功: ${_gameRules.length} 条规则', level: 'INFO');
        } else {
          throw Exception('返回的游戏规则数据格式无效');
        }
      } else if (response.containsKey('error')) {
        throw Exception('服务器错误: ${response['error']}');
      } else {
        throw Exception('无效的响应格式');
      }
    } catch (e) {
      LogUtil.log('获取游戏规则失败: $e', level: 'ERROR');
      if (mounted) {
        setState(() {
          _isLoadingGameRules = false;
          _gameRulesErrorMessage = '获取游戏规则失败: ${_formatErrorMessage(e)}';
        });
      }
    }
  }

  // 更新游戏规则
  Future<void> _updateGameRule(String ruleKey, dynamic ruleValue) async {
    try {
      final response = await widget.network.callAPI('gamerules/update', [{
        "key": ruleKey,
        "value": ruleValue.toString()
      }]);
      if (response.containsKey('result')) {
        final updatedRule = response['result'];
        final index = _gameRules.indexWhere((rule) => rule['key'] == ruleKey);
        if (index != -1) {
          setState(() {
            _gameRules[index] = Map<String, dynamic>.from(updatedRule);
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('游戏规则 "$ruleKey" 已更新')),
        );
      } else {
        throw Exception('服务器没有返回有效的结果');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('更新游戏规则失败: ${_formatErrorMessage(e)}')),
      );
    }
  }

  // 加载布尔型设置
  Future<void> _loadBooleanSetting(String endpoint, Function(bool) setter) async {
    try {
      final response = await widget.network.callAPI(endpoint);
      if (response.containsKey('result')) {
        setter(response['result'] as bool);
      }
    } catch (e) {
      LogUtil.log('获取设置失败 $endpoint: $e', level: 'ERROR');
      rethrow;
    }
  }

  // 加载字符串设置
  Future<void> _loadStringSetting(String endpoint, Function(String) setter) async {
    try {
      final response = await widget.network.callAPI(endpoint);
      if (response.containsKey('result')) {
        setter(response['result'] as String);
      }
    } catch (e) {
      LogUtil.log('获取设置失败 $endpoint: $e', level: 'ERROR');
      rethrow;
    }
  }

  // 加载整型设置
  Future<void> _loadIntegerSetting(String endpoint, Function(int) setter) async {
    try {
      final response = await widget.network.callAPI(endpoint);
      if (response.containsKey('result')) {
        setter(response['result'] as int);
      }
    } catch (e) {
      LogUtil.log('获取设置失败 $endpoint: $e', level: 'ERROR');
      rethrow;
    }
  }

  // 更新布尔型设置
  Future<void> _updateBooleanSetting(String endpoint, bool value) async {
    try {
      await widget.network.callAPI('$endpoint/set', [value]);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('设置已更新')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('更新设置失败: ${_formatErrorMessage(e)}')),
      );
      _loadAllSettings();
    }
  }

  // 更新字符串设置
  Future<void> _updateStringSetting(String endpoint, String value) async {
    try {
      await widget.network.callAPI('$endpoint/set', [value]);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('设置已更新')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('更新设置失败: ${_formatErrorMessage(e)}')),
      );
      _loadAllSettings();
    }
  }

  // 更新整型设置
  Future<void> _updateIntegerSetting(String endpoint, int value) async {
    try {
      await widget.network.callAPI('$endpoint/set', [value]);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('设置已更新')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('更新设置失败: ${_formatErrorMessage(e)}')),
      );
      _loadAllSettings();
    }
  }

  // 格式化错误信息
  String _formatErrorMessage(Object error) {
    if (error.toString().contains('WebSocket')) {
      return 'WebSocket连接错误';
    } else if (error.toString().contains('timeout')) {
      return '请求超时';
    } else {
      return error.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAllSettings,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 基本设置
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('基本设置', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  _buildMotdSetting(),
                  _buildMaxPlayersSetting(),
                  _buildIdleTimeoutSetting(),
                ],
              ),
            ),
          ),
          // 游戏规则设置
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('游戏设置', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  _buildDifficultySetting(),
                  _buildGameModeSetting(),
                  _buildBooleanSetting('自动保存世界', _autoSave, (value) {
                    setState(() => _autoSave = value);
                    _updateBooleanSetting('serversettings/autosave', value!);
                  }),
                  _buildBooleanSetting('强制游戏模式', _forceGameMode, (value) {
                    setState(() => _forceGameMode = value);
                    _updateBooleanSetting('serversettings/force_game_mode', value!);
                  }),
                  _buildBooleanSetting('允许生存模式飞行', _allowFlight, (value) {
                    setState(() => _allowFlight = value);
                    _updateBooleanSetting('serversettings/allow_flight', value!);
                  }),
                ],
              ),
            ),
          ),
          // 游戏规则管理
          _buildGameRulesCard(),
          // 白名单设置
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('白名单设置', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  _buildBooleanSetting('启用白名单', _useAllowlist, (value) {
                    setState(() => _useAllowlist = value);
                    _updateBooleanSetting('serversettings/use_allowlist', value!);
                  }),
                  _buildBooleanSetting('强制执行白名单', _enforceAllowlist, (value) {
                    setState(() => _enforceAllowlist = value);
                    _updateBooleanSetting('serversettings/enforce_allowlist', value!);
                  }),
                ],
              ),
            ),
          ),
          // 服务器设置
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('服务器设置', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  _buildViewDistanceSetting(),
                  _buildSimulationDistanceSetting(),
                  _buildPauseWhenEmptySetting(),
                  _buildSpawnProtectionSetting(),
                  _buildEntityBroadcastSetting(),
                  _buildHeartbeatIntervalSetting(),
                  _buildOperatorPermissionSetting(),
                  _buildBooleanSetting('接受玩家转移', _acceptTransfers, (value) {
                    setState(() => _acceptTransfers = value);
                    _updateBooleanSetting('serversettings/accept_transfers', value!);
                  }),
                  _buildBooleanSetting('隐藏在线玩家列表', _hideOnlinePlayers, (value) {
                    setState(() => _hideOnlinePlayers = value);
                    _updateBooleanSetting('serversettings/hide_online_players', value!);
                  }),
                  _buildBooleanSetting('允许服务器列表查询', _statusReplies, (value) {
                    setState(() => _statusReplies = value);
                    _updateBooleanSetting('serversettings/status_replies', value!);
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          // 刷新按钮
          Center(
            child: ElevatedButton.icon(
              onPressed: () {
                _loadAllSettings();
                _loadGameRules();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('刷新所有设置'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // 构建布尔型设置项
  Widget _buildBooleanSetting(String label, bool? value, Function(bool?) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 16))),
          Switch(
            value: value ?? false,
            onChanged: value != null ? onChanged : null,
          ),
        ],
      ),
    );
  }

  // 构建游戏规则卡片
  Widget _buildGameRulesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('游戏规则', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _isLoadingGameRules ? null : _loadGameRules,
                  tooltip: '刷新游戏规则',
                ),
              ],
            ),
            const Text('中文描述来自于Minecraft Wiki', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            if (_isLoadingGameRules)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_gameRulesErrorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _gameRulesErrorMessage,
                  style: TextStyle(color: Colors.red[700]),
                ),
              )
            else if (_gameRules.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('没有可用的游戏规则'),
              )
            else
              _buildGameRulesList(),
          ],
        ),
      ),
    );
  }

  // 构建游戏规则列表
  Widget _buildGameRulesList() {
    final booleanRules = _gameRules.where((rule) => rule['type'] == 'boolean').toList();
    final integerRules = _gameRules.where((rule) => rule['type'] == 'integer').toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 布尔型规则
        if (booleanRules.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
            child: Text('开关类规则', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ...booleanRules.map((rule) => _buildBooleanGameRule(rule)),
        ],
        // 整数型规则
        if (integerRules.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(top: 16.0, bottom: 8.0),
            child: Text('数值类规则', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ...integerRules.map((rule) => _buildIntegerGameRule(rule)),
        ],
      ],
    );
  }

  // 构建布尔型游戏规则
  Widget _buildBooleanGameRule(Map<String, dynamic> rule) {
    final key = rule['key'] as String;
    bool value = false;
    if (rule['value'] is bool) {
      value = rule['value'];
    } else if (rule['value'] is String) {
      value = rule['value'].toString().toLowerCase() == 'true';
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatRuleName(key),
                  style: const TextStyle(fontSize: 15),
                ),
                Text(
                  _getRuleDescription(key),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: (newValue) {
              _updateGameRule(key, newValue);
            },
          ),
        ],
      ),
    );
  }

  // 构建整数型游戏规则
  Widget _buildIntegerGameRule(Map<String, dynamic> rule) {
    final key = rule['key'] as String;
    final TextEditingController controller = TextEditingController();
    int? value;
    if (rule['value'] is int) {
      value = rule['value'];
    } else if (rule['value'] is String) {
      value = int.tryParse(rule['value']);
    }
    if (value != null) {
      controller.text = value.toString();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _formatRuleName(key),
            style: const TextStyle(fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            _getRuleDescription(key),
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  final newValue = int.tryParse(controller.text);
                  if (newValue != null) {
                    _updateGameRule(key, newValue);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('请输入有效的整数')),
                    );
                  }
                },
                child: const Text('保存'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 格式化规则名称
  String _formatRuleName(String ruleName) {
    final name = ruleName.replaceAll('minecraft:', '');
    final words = name.replaceAllMapped(
      RegExp(r'([a-z0-9])([A-Z])'),
      (match) => '${match.group(1)} ${match.group(2)}'
    ).replaceAll('_', ' ');
    return words.split(' ').map((word) =>
      word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : ''
    ).join(' ');
  }
  String _getRuleDescription(String ruleName) {
    // 中文描述
    final descriptions = {
      'allowEnteringNetherUsingPortals': '允许进入下界',
      'allowFireTicksAwayFromPlayer': '允许火在远离玩家处蔓延',
      'announceAdvancements': '进度通知',
      'blockExplosionDropDecay': '在方块交互爆炸中，一些方块不会掉落战利品',
      'commandBlockOutput': '广播命令方块输出',
      'commandBlocksEnabled': '启用命令方块',
      'commandModificationBlockLimit': '命令修改方块数量限制',
      'disableElytraMovementCheck': '禁用鞘翅移动检测',
      'disablePlayerMovementCheck': '禁用玩家移动检测',
      'disableRaids': '禁用袭击',
      'dayLightCycle': '游戏内时间流逝',
      'doEntityDrops': '非生物实体掉落',
      'doFireTick': '火焰蔓延',
      'doImmediateRespawn': '立即重生',
      'doInsomnia': '生成幻翼',
      'doLimitedCrafting': '合成需要配方',
      'doMobLoot': '生成生物',
      'doPatrolSpawning': '	生成灾厄巡逻队',
      'doTileDrops': '方块掉落',
      'doTraderSpawning': '生成流浪商人',
      'doVinesSpread': '藤蔓蔓延',
      'doWardenSpawning': '生成监守者',
      'doWeatherCycle': '天气更替',
      'drowningDamage': '溺水伤害',
      'enderPearlsVanishOnDeath': '掷出的末影珍珠在死亡时消失',
      'fallDamage': '摔落伤害',
      'fireDamage': '火焰伤害',
      'forgiveDeadPlayers': '宽恕死亡玩家',
      'freezeDamage': '冰冻伤害',
      'globalSoundEvents': '全局声音事件',
      'keepInventory': '死亡后保留物品栏',
      'lavaSourceConversion': '允许流动熔岩转化为熔岩源',
      'locatorBar': '启用玩家定位栏',
      'logAdminCommands': '通告管理员命令',
      'maxCommandChainLength': '命令连锁执行数量限制',
      'maxCommandForkCount': '命令上下文数量限制',
      'maxEntityCramming': '实体挤压上限',
      'minecartMaxSpeed': '矿车最大速度',
      'mobExplosionDropDecay': '在生物爆炸中，一些方块不会掉落战利品',
      'mobGriefing': '允许破坏性生物行为',
      'naturalRegeneration': '生命值自然恢复',
      'playersNetherPortalCreativeDelay': '创造模式下玩家在下界传送门中等待的时间',
      'playersNetherPortalDefaultDelay': '非创造模式下玩家在下界传送门中等待的时间',
      'playersSleepingPercentage': '入睡占比',
      'projectilesCanBreakBlocks': '弹射物能否破坏方块',
      'pvp': '启用PvP',
      'randomTickSpeed': '随机刻速率',
      'reducedDebugInfo': '简化调试信息',
      'sendCommandFeedback': '发送命令反馈',
      'showDeathMessages': '显示死亡消息',
      'snowAccumulationHeight': '积雪厚度',
      'spawnMonsters': '生成怪物',
      'spawnRadius': '重生点半径',
      'spawnerBlocksEnabled': '允许刷怪笼与试炼刷怪笼运作',
      'spectatorsGenerateChunks': '允许旁观者生成地形',
      'tntExplodes': '允许TNT被点燃并爆炸',
      'tntExplosionDropDecay': '在TNT爆炸中,一些方块不会掉落战利品',
      'universalAnger': '无差别愤怒',
      'waterSourceConversion': '允许流动水转化为水源'
    };
    final cleanName = ruleName.replaceAll('minecraft:', '');
    return descriptions[cleanName] ?? '修改游戏规则';
  }

  // 构建难度设置项
  Widget _buildDifficultySetting() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('游戏难度', style: TextStyle(fontSize: 16)),
          DropdownButton<String>(
            value: _difficulty,
            hint: const Text('选择难度'),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _difficulty = newValue;
                });
                _updateStringSetting('serversettings/difficulty', newValue);
              }
            },
            items: _difficultyOptions.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(_getDifficultyName(value)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // 获取难度的显示名称
  String _getDifficultyName(String difficulty) {
    switch (difficulty) {
      case 'peaceful': return '和平';
      case 'easy': return '简单';
      case 'normal': return '普通';
      case 'hard': return '困难';
      default: return difficulty;
    }
  }

  // 构建游戏模式设置项
  Widget _buildGameModeSetting() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('默认游戏模式', style: TextStyle(fontSize: 16)),
          DropdownButton<String>(
            value: _gameMode,
            hint: const Text('选择游戏模式'),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _gameMode = newValue;
                });
                _updateStringSetting('serversettings/game_mode', newValue);
              }
            },
            items: _gameModeOptions.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(_getGameModeName(value)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // 获取游戏模式的显示名称
  String _getGameModeName(String gameMode) {
    switch (gameMode) {
      case 'survival': return '生存模式';
      case 'creative': return '创造模式';
      case 'adventure': return '冒险模式';
      case 'spectator': return '旁观模式';
      default: return gameMode;
    }
  }

  // MOTD设置项
  Widget _buildMotdSetting() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('MOTD', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          TextField(
            controller: _motdController,
            decoration: const InputDecoration(
              hintText: '输入MOTD',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
            onChanged: (value) {
              _motd = value;
            },
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                if (_motd != null) {
                  _updateStringSetting('serversettings/motd', _motd!);
                }
              },
              child: const Text('保存'),
            ),
          ),
        ],
      ),
    );
  }

  // 最大玩家数设置项
  Widget _buildMaxPlayersSetting() {
    return _buildIntegerSetting(
      label: '最大玩家数',
      controller: _maxPlayersController,
      onSaved: (value) {
        if (value != null) {
          _updateIntegerSetting('serversettings/max_players', value);
        }
      },
      min: 1,
      max: 100,
    );
  }

  // 玩家闲置超时设置项
  Widget _buildIdleTimeoutSetting() {
    return _buildIntegerSetting(
      label: '玩家闲置超时时间 (秒)',
      controller: _playerIdleTimeoutController,
      onSaved: (value) {
        if (value != null) {
          _updateIntegerSetting('serversettings/player_idle_timeout', value);
        }
      },
      min: 0,
      max: 3600,
      helperText: '0表示禁用',
    );
  }

  // 无玩家暂停设置项
  Widget _buildPauseWhenEmptySetting() {
    return _buildIntegerSetting(
      label: '无玩家时暂停服务器 (秒)',
      controller: _pauseWhenEmptyController,
      onSaved: (value) {
        if (value != null) {
          _updateIntegerSetting('serversettings/pause_when_empty_seconds', value);
        }
      },
      min: 0,
      max: 3600,
      helperText: '0表示禁用',
    );
  }

  // 出生点保护半径设置项
  Widget _buildSpawnProtectionSetting() {
    return _buildIntegerSetting(
      label: '出生点保护半径',
      controller: _spawnProtectionController,
      onSaved: (value) {
        if (value != null) {
          _updateIntegerSetting('serversettings/spawn_protection_radius', value);
        }
      },
      min: 0,
      max: 100,
      helperText: '0表示禁用',
    );
  }

  // 渲染距离设置项
  Widget _buildViewDistanceSetting() {
    return _buildIntegerSetting(
      label: '渲染距离 (区块)',
      controller: _viewDistanceController,
      onSaved: (value) {
        if (value != null) {
          _updateIntegerSetting('serversettings/view_distance', value);
        }
      },
      min: 3,
      max: 32,
    );
  }

  // 模拟距离设置项
  Widget _buildSimulationDistanceSetting() {
    return _buildIntegerSetting(
      label: '模拟距离 (区块)',
      controller: _simulationDistanceController,
      onSaved: (value) {
        if (value != null) {
          _updateIntegerSetting('serversettings/simulation_distance', value);
        }
      },
      min: 3,
      max: 32,
    );
  }

  // 心跳间隔设置项
  Widget _buildHeartbeatIntervalSetting() {
    return _buildIntegerSetting(
      label: '心跳间隔 (毫秒)',
      controller: _heartbeatIntervalController,
      onSaved: (value) {
        if (value != null) {
          _updateIntegerSetting('serversettings/status_heartbeat_interval', value);
        }
      },
      min: 1000,
      max: 60000,
    );
  }

// 管理员权限等级设置项
Widget _buildOperatorPermissionSetting() {
  int currentLevel = int.tryParse(_operatorPermissionController.text) ?? 4;
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('管理员默认权限等级', style: TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          value: currentLevel >= 1 && currentLevel <= 4 ? currentLevel : 2, // 改为 initialValue
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          items: const [
            DropdownMenuItem(
              value: 1,
              child: Text('1 - Moderator'),
            ),
            DropdownMenuItem(
              value: 2,
              child: Text('2 - Gamemaster'),
            ),
            DropdownMenuItem(
              value: 3,
              child: Text('3 - Admin'),
            ),
            DropdownMenuItem(
              value: 4,
              child: Text('4 - Owner'),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              _operatorPermissionController.text = value.toString();
              _updateIntegerSetting('serversettings/operator_user_permission_level', value);
            }
          },
        )
      ],
    ),
  );
}

  // 构建实体广播范围设置项
  Widget _buildEntityBroadcastSetting() {
    return _buildIntegerSetting(
      label: '实体广播范围百分比',
      controller: _entityBroadcastController,
      onSaved: (value) {
        if (value != null) {
          _updateIntegerSetting('serversettings/entity_broadcast_range', value);
        }
      },
      min: 10,
      max: 500,
      helperText: '百分比值',
    );
  }

  // 通用整数设置构建器
  Widget _buildIntegerSetting({
    required String label,
    required TextEditingController controller,
    required Function(int?) onSaved,
    required int min,
    required int max,
    String? helperText,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    helperText: helperText,
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                  },
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  final text = controller.text.trim();
                  if (text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('请输入有效的数值')),
                    );
                    return;
                  }
                  final value = int.tryParse(text);
                  if (value == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('请输入有效的整数')),
                    );
                    return;
                  }
                  if (value < min || value > max) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('数值必须在 $min 到 $max 之间')),
                    );
                    return;
                  }
                  onSaved(value);
                },
                child: const Text('保存'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}