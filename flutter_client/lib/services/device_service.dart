import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// 设备服务 - 管理设备ID和自动登录
class DeviceService {
  static const String _deviceIdKey = 'device_id';
  static const String _savedAccountKey = 'saved_account';
  static const String _isEmailKey = 'is_email_account';

  /// 获取或创建设备唯一ID
  static Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString(_deviceIdKey);

    if (deviceId == null || deviceId.isEmpty) {
      // 尝试获取设备信息
      deviceId = await _getRealDeviceId();

      // 如果获取失败，生成一个UUID
      if (deviceId == null || deviceId.isEmpty) {
        deviceId = const Uuid().v4();
      }

      await prefs.setString(_deviceIdKey, deviceId);
    }

    return deviceId;
  }

  /// 获取真实的设备ID
  static Future<String?> _getRealDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        // 使用 Android ID（每台设备唯一）
        return androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return iosInfo.identifierForVendor;
      }
    } catch (e) {
      print('获取设备信息失败: $e');
    }

    return null;
  }

  /// 保存登录账号（用于自动登录）
  static Future<void> saveAccount(String account, bool isEmail) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_savedAccountKey, account);
    await prefs.setBool(_isEmailKey, isEmail);
  }

  /// 获取保存的账号
  static Future<String?> getSavedAccount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_savedAccountKey);
  }

  /// 是否是邮箱账号
  static Future<bool> isEmailAccount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isEmailKey) ?? false;
  }

  /// 清除保存的账号
  static Future<void> clearSavedAccount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_savedAccountKey);
    await prefs.remove(_isEmailKey);
  }

  /// 检查是否有保存的账号（用于自动登录）
  static Future<bool> hasSavedAccount() async {
    final prefs = await SharedPreferences.getInstance();
    final account = prefs.getString(_savedAccountKey);
    return account != null && account.isNotEmpty;
  }
}
