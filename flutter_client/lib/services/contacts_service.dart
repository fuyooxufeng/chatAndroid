import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';

class ContactsHelper {
  static Map<String, String> _contactsCache = {};

  /// 获取本机手机号（简化版，返回 null 需要手动输入）
  static Future<String?> getPhoneNumber() async {
    // Android 10+ 已限制获取本机号码，需要特殊权限
    // 目前返回 null，用户需手动输入
    return null;
  }

  /// 清理手机号格式
  static String _cleanPhoneNumber(String phone) {
    // 移除所有非数字字符
    String cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');

    // 处理中国区号
    if (cleaned.startsWith('86') && cleaned.length > 10) {
      cleaned = cleaned.substring(2);
    }
    if (cleaned.startsWith('+86')) {
      cleaned = cleaned.substring(3);
    }

    return cleaned;
  }

  /// 加载通讯录
  static Future<void> loadContacts() async {
    try {
      // 请求通讯录权限
      final status = await Permission.contacts.request();
      if (!status.isGranted) {
        print('通讯录权限被拒绝');
        return;
      }

      // 检查是否支持通讯录功能
      if (!await FlutterContacts.requestPermission()) {
        print('无法获取通讯录权限');
        return;
      }

      // 获取所有联系人
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );

      _contactsCache.clear();

      for (final contact in contacts) {
        for (final phone in contact.phones) {
          final cleanedNumber = _cleanPhoneNumber(phone.number);
          if (cleanedNumber.isNotEmpty) {
            _contactsCache[cleanedNumber] = contact.displayName;
          }
        }
      }

      print('通讯录加载完成: ${_contactsCache.length} 条记录');
    } catch (e) {
      print('加载通讯录失败: $e');
    }
  }

  /// 根据手机号获取联系人名称
  static String getContactName(String phoneNumber) {
    final cleaned = _cleanPhoneNumber(phoneNumber);
    return _contactsCache[cleaned] ?? phoneNumber;
  }

  /// 检查手机号是否在通讯录中
  static bool isInContacts(String phoneNumber) {
    final cleaned = _cleanPhoneNumber(phoneNumber);
    return _contactsCache.containsKey(cleaned);
  }

  /// 获取通讯录缓存
  static Map<String, String> get contactsCache => _contactsCache;

  /// 刷新通讯录
  static Future<void> refreshContacts() async {
    await loadContacts();
  }
}
