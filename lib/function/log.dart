import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class LogUtil {
  // 添加日志
  static Future<void> log(String message, {String level = 'INFO'}) async {
    debugPrint('[$level] $message');
    final prefs = await SharedPreferences.getInstance();
    List<String> logs = prefs.getStringList('logs') ?? [];
    // 创建日志条目
    final timestamp = DateTime.now().toIso8601String();
    final logEntry = jsonEncode({
      'timestamp': timestamp,
      'level': level,
      'message': message,
    });
    logs.add(logEntry);
    await prefs.setStringList('logs', logs);
  }
  // 获取所有日志
  static Future<List<Map<String, dynamic>>> getLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final logs = prefs.getStringList('logs') ?? [];
    return logs.map((log) => jsonDecode(log) as Map<String, dynamic>).toList();
  }
  // 清除所有日志
  static Future<void> clearLogs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('logs');
  }
}