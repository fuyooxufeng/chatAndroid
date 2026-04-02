import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/message.dart';
import '../services/config_service.dart';
import '../services/auth_service.dart';
import '../services/device_service.dart';

class ChatProvider extends ChangeNotifier {
  WebSocketChannel? _channel;
  String? _userId;  // 用户ID（可以是手机号或邮箱）
  String? _password;
  bool _isLoggedIn = false;
  bool _isConnected = false;
  bool _isReconnecting = false;
  List<String> _onlineUsers = [];
  Map<String, List<Message>> _messages = {};
  String? _selectedChat;
  String _errorMessage = '';
  Timer? _reconnectTimer;

  // Getters
  bool get isLoggedIn => _isLoggedIn;
  bool get isConnected => _isConnected;
  bool get isReconnecting => _isReconnecting;
  String? get phone => _userId;  // 保持向后兼容
  String? get userId => _userId;
  String? get selectedChat => _selectedChat;
  List<String> get onlineUsers => _onlineUsers;
  String get errorMessage => _errorMessage;
  Map<String, List<Message>> get messages => _messages;

  List<Message> get currentMessages {
    if (_selectedChat == null) {
      return _messages['group'] ?? [];
    }
    return _messages[_selectedChat] ?? [];
  }

  bool get isGroupChat => _selectedChat == null;

  // 初始化（检查是否有保存的登录信息）
  Future<bool> checkSavedLogin() async {
    final isLoggedIn = await AuthService.isLoggedIn();
    if (isLoggedIn) {
      final userId = await AuthService.getSavedPhone();
      final password = await AuthService.getSavedPassword();
      if (userId != null && userId.isNotEmpty) {
        _userId = userId;
        _password = password ?? 'aaaaaa';
        return true;
      }
    }
    return false;
  }

  // WebSocket 连接（支持手机号或邮箱）
  Future<void> connect(String userId, {String? password}) async {
    _userId = userId;
    _password = password ?? AppConfig.userPassword;

    // 保存登录信息
    await AuthService.saveLoginInfo(_userId!, _password!);

    await _doConnect();
  }

  // 实际连接方法
  Future<void> _doConnect() async {
    if (_userId == null) return;

    try {
      final wsUrl = AppConfig.wsUrl;
      _channel = WebSocketChannel.connect(
        Uri.parse(wsUrl),
      );

      _isConnected = true;
      _isReconnecting = false;
      notifyListeners();

      // 取消重连定时器
      _reconnectTimer?.cancel();

      // 监听消息
      _channel!.stream.listen(
        (message) => _handleMessage(jsonDecode(message)),
        onError: (error) {
          _errorMessage = '连接错误: $error';
          _handleDisconnection();
        },
        onDone: () {
          _handleDisconnection();
        },
      );

      // 发送登录信息（保持与服务器兼容，使用 phone 字段）
      _sendMessage({
        'type': 'login',
        'phone': _userId!,
        'password': _password!,
      });
    } catch (e) {
      _errorMessage = '无法连接到服务器';
      _handleDisconnection();
    }
  }

  // 处理断开连接
  void _handleDisconnection() {
    _isConnected = false;
    _isLoggedIn = false;
    notifyListeners();

    // 启动自动重连
    _startReconnectTimer();
  }

  // 启动重连定时器
  void _startReconnectTimer() {
    _reconnectTimer?.cancel();
    _isReconnecting = true;
    notifyListeners();

    // 每 3 秒尝试重连一次
    _reconnectTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (_isConnected) {
        timer.cancel();
        return;
      }
      if (_userId != null) {
        await _doConnect();
      }
    });
  }

  // 使用保存的信息重新连接
  Future<void> reconnectWithSavedInfo() async {
    final userId = await AuthService.getSavedPhone();
    final password = await AuthService.getSavedPassword();
    if (userId != null && userId.isNotEmpty) {
      _userId = userId;
      _password = password ?? 'aaaaaa';
      await _doConnect();
    }
  }

  void _handleMessage(Map<String, dynamic> data) {
    final type = data['type'];

    switch (type) {
      case 'login_success':
        _isLoggedIn = true;
        _isReconnecting = false;
        _onlineUsers = List<String>.from(data['online_users'] ?? []);
        notifyListeners();
        break;

      case 'user_online':
      case 'user_offline':
        _onlineUsers = List<String>.from(data['online_users'] ?? []);
        notifyListeners();
        break;

      case 'message':
        _receiveMessage(data);
        break;

      case 'error':
        _errorMessage = data['message'] ?? '未知错误';
        notifyListeners();
        break;
    }
  }

  void _receiveMessage(Map<String, dynamic> data) {
    final message = Message.fromJson(data);
    final from = message.from;
    final isGroup = message.isGroup;
    final target = message.target;

    String key;
    if (isGroup) {
      key = 'group';
    } else {
      key = from == _userId ? target! : from;
    }

    if (!_messages.containsKey(key)) {
      _messages[key] = [];
    }
    _messages[key]!.add(message);
    notifyListeners();
  }

  void sendMessage(String content) {
    if (content.trim().isEmpty) return;

    _sendMessage({
      'type': 'message',
      'content': content.trim(),
      'target': _selectedChat,
    });
  }

  void _sendMessage(Map<String, dynamic> data) {
    if (_channel != null && _isConnected) {
      _channel!.sink.add(jsonEncode(data));
    }
  }

  void selectChat(String? chat) {
    _selectedChat = chat;
    notifyListeners();
  }

  Future<void> logout() async {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _userId = null;
    _password = null;
    _isLoggedIn = false;
    _isConnected = false;
    _isReconnecting = false;
    _onlineUsers = [];
    _messages = {};
    _selectedChat = null;
    await AuthService.clearLoginInfo();
    await DeviceService.clearSavedAccount();  // 同时清除设备保存的账号
    notifyListeners();
  }

  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    super.dispose();
  }
}
