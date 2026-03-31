import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../services/contacts_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  bool _isGettingPhoneNumber = false;
  String? _autoPhoneNumber;

  @override
  void initState() {
    super.initState();
    _tryGetPhoneNumber();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  /// 尝试获取本机手机号
  Future<void> _tryGetPhoneNumber() async {
    setState(() => _isGettingPhoneNumber = true);

    // 尝试获取手机号
    String? phoneNumber = await ContactsHelper.getPhoneNumber();

    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      setState(() {
        _autoPhoneNumber = phoneNumber;
        _phoneController.text = phoneNumber;
      });
    }

    // 同时加载通讯录
    await ContactsHelper.loadContacts();

    setState(() => _isGettingPhoneNumber = false);
  }

  void _login() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入手机号')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final provider = context.read<ChatProvider>();
    await provider.connect(phone);

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF128C7E), Color(0xFF075E54)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.chat_bubble,
                  size: 100,
                  color: Colors.white,
                ),
                const SizedBox(height: 32),
                const Text(
                  'Chat App',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 48),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: '手机号',
                          prefixIcon: const Icon(Icons.phone),
                          border: const OutlineInputBorder(),
                          suffixIcon: _isGettingPhoneNumber
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : _autoPhoneNumber != null
                                  ? const Icon(Icons.check_circle,
                                      color: Colors.green)
                                  : null,
                          helperText: _autoPhoneNumber != null
                              ? '已自动获取本机号码'
                              : '无法自动获取，请手动输入',
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '密码: aaaaaa',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF128C7E),
                            foregroundColor: Colors.white,
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text(
                                  '登录',
                                  style: TextStyle(fontSize: 18),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
