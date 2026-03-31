# Flutter 客户端打包指南

## 准备工作

### 1. 配置服务器地址

编辑 `assets/config.json`，将 `host` 改为你的服务器地址：

**情况 A: 电脑本地测试（手机连接同一WiFi）**
```json
{
  "server": {
    "host": "192.168.x.x",  // 电脑的局域网IP
    "port": 8765,
    "ws_protocol": "ws"
  }
}
```

**查看电脑IP的方法：**
- macOS: 终端运行 `ifconfig | grep inet`
- Windows: 终端运行 `ipconfig`
- Linux: 终端运行 `ip addr`

**情况 B: 云服务器**
```json
{
  "server": {
    "host": "your-server-domain.com",
    "port": 8765,
    "ws_protocol": "ws"
  }
}
```

### 2. 配置自动登录（可选）

```json
{
  "user": {
    "phone": "13800138000",
    "password": "aaaaaa"
  }
}
```

---

## Android 打包

### 步骤 1: 配置签名（可选，用于发布）

调试版本可以跳过此步骤。如需发布到应用商店，需配置签名：

创建 `android/key.properties`:
```
storePassword=your-store-password
keyPassword=your-key-password
keyAlias=your-key-alias
storeFile=../your-keystore.jks
```

### 步骤 2: 修改版本号（可选）

编辑 `pubspec.yaml`:
```yaml
version: 1.0.0+1  # 格式: 版本号+构建号
```

### 步骤 3: 打包 APK

```bash
cd /Users/xufengrichard/Desktop/chat_platform/flutter_client

# 获取依赖
flutter pub get

# 打包 APK（调试版）
flutter build apk --debug

# 或打包 APK（发布版）
flutter build apk --release
```

### 步骤 4: 找到 APK 文件

**调试版:**
`build/app/outputs/flutter-apk/app-debug.apk`

**发布版:**
`build/app/outputs/flutter-apk/app-release.apk`

### 步骤 5: 安装到手机

**方法 1 - 数据线安装:**
```bash
# 连接手机，开启USB调试
flutter install
```

**方法 2 - 手动安装:**
1. 将 APK 文件传输到手机
2. 在手机上点击安装
3. 如提示"未知来源"，请在设置中允许

**方法 3 - 通过 ADB:**
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

---

## iOS 打包

### 前提条件

- macOS 系统
- Xcode 已安装
- Apple Developer 账号（真机测试需要）

### 步骤 1: 配置签名

1. 用 Xcode 打开 `ios/Runner.xcworkspace`
2. 选择 Runner → Signing & Capabilities
3. 登录 Apple Developer 账号
4. 选择 Team

### 步骤 2: 打包 IPA

```bash
cd /Users/xufengrichichard/Desktop/chat_platform/flutter_client

# 获取依赖
flutter pub get

# 构建 iOS 版本
flutter build ios --release
```

### 步骤 3: 导出 IPA

1. 在 Xcode 中选择 Product → Archive
2. 等待归档完成
3. 点击 Distribute App
4. 选择 Ad Hoc（内部分发）或 Development（开发测试）
5. 导出 IPA 文件

### 步骤 4: 安装到 iPhone

**方法 1 - Xcode 直接运行:**
连接 iPhone，选择设备，点击运行

**方法 2 - 使用 Apple Configurator 2:**
1. 安装 Apple Configurator 2 (Mac App Store)
2. 连接 iPhone
3. 双击设备 → 添加 → App
4. 选择导出的 IPA 文件

**方法 3 - 使用 TestFlight（推荐用于分发）:**
1. 上传 IPA 到 App Store Connect
2. 通过 TestFlight 安装测试

---

## 常见问题

### Android 安装问题

**问题 1: "安装包解析错误"**
- 确保 APK 文件完整传输
- 尝试重新打包

**问题 2: "被系统禁止安装"**
- 设置 → 安全 → 允许未知来源应用

**问题 3: 连接不上服务器**
- 检查手机和电脑是否在同一WiFi
- 检查服务器IP是否正确
- 检查防火墙设置

### iOS 安装问题

**问题 1: "无法验证 App"**
- 设置 → 通用 → VPN与设备管理 → 信任开发者

**问题 2: 打包失败**
- 确保已选择正确的 Development Team
- 检查 Bundle Identifier 是否唯一

---

## 测试清单

安装后请验证：

- [ ] 应用能正常打开
- [ ] 能连接到服务器（看是否有"连接中..."提示）
- [ ] 能成功登录
- [ ] 能看到在线用户列表
- [ ] 能发送和接收消息
- [ ] 群聊功能正常
- [ ] 私聊功能正常

---

## 网络要求

### 本地测试（电脑+手机同一WiFi）

1. 手机和电脑必须在同一局域网
2. 电脑防火墙需要开放 8765 端口
3. 使用电脑的局域网 IP（不是 127.0.0.1 或 localhost）

### 云服务器测试

1. 云服务器安全组需要开放 8765 端口
2. 使用公网 IP 或域名
