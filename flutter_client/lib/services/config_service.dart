import 'dart:convert';
import 'package:flutter/services.dart';

class AppConfig {
  static Map<String, dynamic>? _config;

  static Future<void> load() async {
    try {
      final jsonString = await rootBundle.loadString('assets/config.json');
      _config = jsonDecode(jsonString);
    } catch (e) {
      // 使用默认配置
      _config = {
        "server": {
          "host": "localhost",
          "port": 8765,
          "ws_protocol": "ws"
        },
        "user": {
          "phone": "",
          "password": "aaaaaa"
        }
      };
    }
  }

  // 服务器配置
  static String get serverHost {
    return _config?['server']?['host'] ?? 'localhost';
  }

  static int get serverPort {
    return _config?['server']?['port'] ?? 8765;
  }

  static String get wsProtocol {
    return _config?['server']?['ws_protocol'] ?? 'ws';
  }

  static String get wsUrl {
    return '$wsProtocol://$serverHost:$serverPort';
  }

  // 用户配置
  static String get userPhone {
    return _config?['user']?['phone'] ?? '';
  }

  static String get userPassword {
    return _config?['user']?['password'] ?? 'aaaaaa';
  }

  static bool get hasAutoLogin {
    final phone = userPhone;
    return phone.isNotEmpty;
  }
}
