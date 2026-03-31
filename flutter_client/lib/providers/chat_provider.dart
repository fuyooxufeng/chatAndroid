import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/message.dart';
import '../services/config_service.dart';

class ChatProvider extends ChangeNotifier {
  WebSocketChannel? _channel;
  String? _phone;
  bool _isLoggedIn = false;
  bool _isConnected = false;
  List<String> _onlineUsers = [];
  Map<String, List<Message>> _messages = {};
  String? _selectedChat;
  String _errorMessage = '';

  // Getters
  bool get isLoggedIn => _isLoggedIn;
  bool get isConnected => _isConnected;
  String? get phone => _phone;
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

  // WebSocket 连接
  Future<void> connect(String phone) async {
    _phone = phone;

    try {
      final wsUrl = AppConfig.wsUrl;
      _channel = WebSocketChannel.connect(
        Uri.parse(wsUrl),
      );

      _isConnected = true;
      notifyListeners();

      // 监听消息
      _channel!.stream.listen(
        (message) => _handleMessage(jsonDecode(message)),
        onError: (error) {
          _errorMessage = '连接错误: $error';
          notifyListeners();
        },
        onDone: () {
          _isConnected = false;
          notifyListeners();
        },
      );

      // 发送登录信息
      login(phone);
    } catch (e) {
      _errorMessage = '无法连接到服务器';
      notifyListeners();
    }
  }

  void login(String phone, {String? password}) {
    _phone = phone;
    _sendMessage({
      'type': 'login',
      'phone': phone,
      'password': password ?? AppConfig.userPassword,
    });
  }

  void _handleMessage(Map<String, dynamic> data) {
    final type = data['type'];

    switch (type) {
      case 'login_success':
        _isLoggedIn = true;
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

    // 确定存储键
    String key;
    if (isGroup) {
      key = 'group';
    } else {
      key = from == _phone ? target! : from;
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
    if (_channel != null) {
      _channel!.sink.add(jsonEncode(data));
    }
  }

  void selectChat(String? chat) {
    _selectedChat = chat;
    notifyListeners();
  }

  void logout() {
    _channel?.sink.close();
    _channel = null;
    _phone = null;
    _isLoggedIn = false;
    _isConnected = false;
    _onlineUsers = [];
    _messages = {};
    _selectedChat = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }
}
