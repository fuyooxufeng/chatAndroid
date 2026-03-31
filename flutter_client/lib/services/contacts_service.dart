import 'dart:async';
import 'package:contacts_service/contacts_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sim_info/sim_info.dart';

class ContactsHelper {
  // 缓存通讯录数据
  static Map<String, String> _contactsCache = {};

  /// 获取本机手机号
  static Future<String?> getPhoneNumber() async {
    try {
      // 请求电话权限
      var status = await Permission.phone.request();
      if (status.isGranted) {
        String? phoneNumber = await SimInfo.getPhoneNumber;
        // 清理手机号（去掉空格、横线等）
        if (phoneNumber != null && phoneNumber.isNotEmpty) {
          phoneNumber = _cleanPhoneNumber(phoneNumber);
          return phoneNumber;
        }
      }
    } catch (e) {
      print('获取手机号失败: $e');
    }
    return null;
  }

  /// 清理手机号格式
  static String _cleanPhoneNumber(String phone) {
    // 去掉所有非数字字符
    return phone.replaceAll(RegExp(r'[^\d]'), '');
  }

  /// 请求通讯录权限
  static Future<bool> requestContactsPermission() async {
    var status = await Permission.contacts.request();
    return status.isGranted;
  }

  /// 加载通讯录
  static Future<void> loadContacts() async {
    try {
      // 检查权限
      bool hasPermission = await requestContactsPermission();
      if (!hasPermission) {
        print('没有通讯录权限');
        return;
      }

      // 获取所有联系人
      Iterable<Contact> contacts = await ContactsService.getContacts();

      // 清空缓存
      _contactsCache.clear();

      // 解析联系人
      for (Contact contact in contacts) {
        if (contact.phones != null && contact.phones!.isNotEmpty) {
          String name = contact.displayName ?? contact.givenName ?? '未知';

          for (Item phone in contact.phones!) {
            if (phone.value != null) {
              String cleanNumber = _cleanPhoneNumber(phone.value!);
              if (cleanNumber.isNotEmpty) {
                _contactsCache[cleanNumber] = name;
              }
            }
          }
        }
      }

      print('通讯录加载完成，共 ${_contactsCache.length} 条记录');
    } catch (e) {
      print('加载通讯录失败: $e');
    }
  }

  /// 根据手机号获取联系人名称
  static String getContactName(String phoneNumber) {
    String cleanNumber = _cleanPhoneNumber(phoneNumber);
    return _contactsCache[cleanNumber] ?? phoneNumber;
  }

  /// 检查手机号是否在通讯录中
  static bool isInContacts(String phoneNumber) {
    String cleanNumber = _cleanPhoneNumber(phoneNumber);
    return _contactsCache.containsKey(cleanNumber);
  }

  /// 获取通讯录缓存
  static Map<String, String> get contactsCache => _contactsCache;

  /// 刷新通讯录
  static Future<void> refreshContacts() async {
    await loadContacts();
  }
}
