// 简化版通讯录服务（移除有问题的依赖）
// 如需完整功能，请使用稳定版本的依赖

class ContactsHelper {
  static Map<String, String> _contactsCache = {};

  /// 获取本机手机号（简化版，返回 null 需要手动输入）
  static Future<String?> getPhoneNumber() async {
    // 由于依赖包存在兼容性问题，暂时返回 null
    // 用户需要手动输入手机号
    return null;
  }

  /// 清理手机号格式
  static String _cleanPhoneNumber(String phone) {
    return phone.replaceAll(RegExp(r'[^\d]'), '');
  }

  /// 加载通讯录（简化版，不实际加载）
  static Future<void> loadContacts() async {
    // 由于依赖包存在兼容性问题，暂时不加载
    // 直接显示手机号
    _contactsCache.clear();
  }

  /// 根据手机号获取联系人名称
  static String getContactName(String phoneNumber) {
    // 简化版直接返回手机号
    return phoneNumber;
  }

  /// 检查手机号是否在通讯录中
  static bool isInContacts(String phoneNumber) {
    return false;
  }

  /// 获取通讯录缓存
  static Map<String, String> get contactsCache => _contactsCache;

  /// 刷新通讯录
  static Future<void> refreshContacts() async {
    await loadContacts();
  }
}
