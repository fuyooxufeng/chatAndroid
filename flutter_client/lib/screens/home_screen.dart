import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../services/contacts_service.dart';
import 'chat_screen.dart';
import 'contacts_screen.dart';

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
          Consumer<ChatProvider>(
            builder: (context, provider, child) {
              if (!provider.isConnected) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          IconButton(
            icon: const Icon(Icons.contacts),
            onPressed: () {
              // 打开通讯录页面
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ContactsScreen(),
                ),
              );
            },
          ),
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
                          // 获取通讯录中的名字
                          final displayName =
                              ContactsHelper.getContactName(user);
                          final isInContacts =
                              ContactsHelper.isInContacts(user);

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isInContacts
                                  ? const Color(0xFF128C7E)
                                  : Colors.grey[300],
                              child: Text(
                                displayName.isNotEmpty
                                    ? displayName[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  color: isInContacts
                                      ? Colors.white
                                      : Colors.black54,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              displayName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('在线'),
                                if (isInContacts)
                                  Text(
                                    user,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                              ],
                            ),
                            trailing: isInContacts
                                ? const Icon(Icons.check_circle,
                                    color: Color(0xFF128C7E), size: 20)
                                : const Icon(Icons.chevron_right),
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
