import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import 'chat_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat App'),
        backgroundColor: const Color(0xFF075E54),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<ChatProvider>().logout();
            },
          ),
        ],
      ),
      body: Consumer<ChatProvider>(
        builder: (context, provider, child) {
          final users = provider.onlineUsers
              .where((u) => u != provider.phone)
              .toList();

          return Column(
            children: [
              // 群聊入口
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF128C7E),
                  child: const Icon(Icons.group, color: Colors.white),
                ),
                title: const Text(
                  '群聊',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('点击进入群聊'),
                onTap: () {
                  provider.selectChat(null);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ChatScreen(),
                    ),
                  );
                },
              ),
              const Divider(),
              // 在线用户列表
              Expanded(
                child: users.isEmpty
                    ? const Center(
                        child: Text(
                          '暂无其他在线用户',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          final user = users[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.grey[300],
                              child: Text(
                                user[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              user,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: const Text('在线'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              provider.selectChat(user);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ChatScreen(),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
