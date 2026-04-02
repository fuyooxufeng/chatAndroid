import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../services/device_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _accountController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isAutoLoggingIn = false;
  bool _isEmailMode = false;
  String? _deviceId;

  // Method Channel for uni login (optional)
  static const MethodChannel _uniLoginChannel =
      MethodChannel('com.example.chat_app/uni_login');

  @override
  void initState() {
    super.initState();
    _checkAutoLogin();
  }

  @override
  void dispose() {
    _accountController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// 检查自动登录
  Future<void> _checkAutoLogin() async {
    setState(() => _isAutoLoggingIn = true);

    try {
      // 获取设备ID
      _deviceId = await DeviceService.getDeviceId();
      print('设备ID: $_deviceId');

      // 检查是否有保存的账号
      if (await DeviceService.hasSavedAccount()) {
        final savedAccount = await DeviceService.getSavedAccount();
        final isEmail = await DeviceService.isEmailAccount();

        if (savedAccount != null && savedAccount.isNotEmpty) {
          // 自动登录
          if (mounted) {
            final provider = context.read<ChatProvider>();
            await provider.connect(savedAccount);

            if (provider.isConnected) {
              print('自动登录成功: $savedAccount');
              return;
            }
          }
        }
      }
    } catch (e) {
      print('自动登录失败: $e');
    } finally {
      if (mounted) {
        setState(() => _isAutoLoggingIn = false);
      }
    }
  }

  void _login() async {
    final account = _accountController.text.trim();
    final password = _passwordController.text.trim();

    if (account.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEmailMode ? '请输入邮箱' : '请输入手机号')),
      );
      return;
    }

    // 验证邮箱格式
    if (_isEmailMode && !_isValidEmail(account)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('邮箱格式不正确')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final provider = context.read<ChatProvider>();
    await provider.connect(account);

    if (provider.isConnected) {
      // 保存账号用于自动登录
      await DeviceService.saveAccount(account, _isEmailMode);
      print('登录成功，账号已保存: $account');
    }

    setState(() => _isLoading = false);
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  /// uni 一键登录（可选）
  Future<void> _uniLogin() async {
    setState(() => _isLoading = true);

    try {
      final result = await _uniLoginChannel.invokeMethod<Map>('uniLogin');

      if (result != null && result['success'] == true) {
        final phoneNumber = result['phoneNumber'] as String?;
        if (phoneNumber != null && phoneNumber.isNotEmpty) {
          final provider = context.read<ChatProvider>();
          await provider.connect(phoneNumber);

          if (provider.isConnected) {
            await DeviceService.saveAccount(phoneNumber, false);
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('获取手机号失败')),
          );
        }
      } else {
        final errorMsg = result?['message'] as String? ?? '一键登录失败';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg)),
        );
      }
    } on PlatformException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('一键登录错误: ${e.message}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('一键登录异常: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 自动登录中显示加载
    if (_isAutoLoggingIn) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('自动登录中...'),
            ],
          ),
        ),
      );
    }

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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
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
                      // 切换登录方式
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => setState(() => _isEmailMode = false),
                              style: TextButton.styleFrom(
                                backgroundColor: !_isEmailMode
                                    ? const Color(0xFF128C7E).withOpacity(0.1)
                                    : null,
                              ),
                              child: Text(
                                '手机号',
                                style: TextStyle(
                                  color: !_isEmailMode
                                      ? const Color(0xFF128C7E)
                                      : Colors.grey,
                                  fontWeight: !_isEmailMode
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: TextButton(
                              onPressed: () => setState(() => _isEmailMode = true),
                              style: TextButton.styleFrom(
                                backgroundColor: _isEmailMode
                                    ? const Color(0xFF128C7E).withOpacity(0.1)
                                    : null,
                              ),
                              child: Text(
                                '邮箱',
                                style: TextStyle(
                                  color: _isEmailMode
                                      ? const Color(0xFF128C7E)
                                      : Colors.grey,
                                  fontWeight: _isEmailMode
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // 账号输入框
                      TextField(
                        controller: _accountController,
                        keyboardType: _isEmailMode
                            ? TextInputType.emailAddress
                            : TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: _isEmailMode ? '邮箱' : '手机号',
                          prefixIcon: Icon(_isEmailMode ? Icons.email : Icons.phone),
                          border: const OutlineInputBorder(),
                          hintText: _isEmailMode ? 'example@email.com' : '请输入手机号',
                        ),
                      ),
                      const SizedBox(height: 16),
                      // 密码输入框
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: '密码',
                          prefixIcon: Icon(Icons.lock),
                          border: OutlineInputBorder(),
                          hintText: '默认密码: aaaaaa',
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '默认密码: aaaaaa',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // 登录按钮
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
                      const SizedBox(height: 12),
                      // uni 一键登录按钮（可选）
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _uniLogin,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.phone_android),
                          label: Text(
                            _isLoading ? '获取中...' : '本机号码一键登录',
                            style: const TextStyle(fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF25D366),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // 设备信息
                      if (_deviceId != null)
                        Text(
                          '设备ID: ${_deviceId!.substring(0, _deviceId!.length > 8 ? 8 : _deviceId!.length)}...',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 10,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  '首次登录后，系统将自动记住您的账号',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
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
