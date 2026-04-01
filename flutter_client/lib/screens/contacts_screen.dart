import 'package:flutter/material.dart';
import '../services/contacts_service.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  bool _isLoading = false;
  bool _hasPermission = false;
  List<MapEntry<String, String>> _contacts = [];

  Future<void> _loadContacts() async {
    setState(() => _isLoading = true);

    await ContactsHelper.loadContacts();

    setState(() {
      _contacts = ContactsHelper.contactsCache.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));
      _hasPermission = true;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('通讯录'),
        backgroundColor: const Color(0xFF075E54),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 读取通讯录按钮区域
          if (!_hasPermission)
            Container(
              padding: const EdgeInsets.all(24),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.contacts,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '需要访问通讯录权限',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '点击按钮读取通讯录数据',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _loadContacts,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.refresh),
                      label: Text(
                        _isLoading ? '读取中...' : '读取通讯录',
                        style: const TextStyle(fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF128C7E),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            // 刷新按钮
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    '共 ${_contacts.length} 位联系人',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _loadContacts,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.refresh, size: 18),
                    label: const Text('刷新'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF128C7E),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

          // 通讯录列表
          Expanded(
            child: _contacts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.contact_phone,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _hasPermission ? '通讯录为空' : '点击按钮读取通讯录',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _contacts.length,
                    itemBuilder: (context, index) {
                      final contact = _contacts[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF128C7E),
                          child: Text(
                            contact.value.isNotEmpty
                                ? contact.value[0].toUpperCase()
                                : '?',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(contact.value),
                        subtitle: Text(contact.key),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
