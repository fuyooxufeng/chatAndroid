import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/chat_provider.dart';
import 'services/config_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.load();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late ChatProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = ChatProvider();
    // 检查是否有保存的登录信息
    _checkSavedLogin();
  }

  Future<void> _checkSavedLogin() async {
    final hasSavedLogin = await _provider.checkSavedLogin();
    if (hasSavedLogin) {
      // 自动连接
      await _provider.reconnectWithSavedInfo();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: MaterialApp(
        title: 'Chat App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF128C7E),
            primary: const Color(0xFF128C7E),
          ),
          useMaterial3: true,
        ),
        home: Consumer<ChatProvider>(
          builder: (context, provider, child) {
            if (provider.isReconnecting) {
              return const ReconnectingScreen();
            }
            return provider.isLoggedIn ? const HomeScreen() : const LoginScreen();
          },
        ),
      ),
    );
  }
}

// 重连中界面
class ReconnectingScreen extends StatelessWidget {
  const ReconnectingScreen({super.key});

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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.chat_bubble,
                size: 80,
                color: Colors.white,
              ),
              const SizedBox(height: 24),
              const Text(
                'Chat App',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 48),
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 16),
              const Text(
                '正在重新连接...',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
