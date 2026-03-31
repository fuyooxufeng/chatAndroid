# Flutter 聊天客户端

跨平台移动聊天应用，支持 Android 和 iOS。

## 功能特点

- 手机号登录
- 实时 WebSocket 通信
- 群聊功能
- 私聊功能
- 在线用户列表
- WhatsApp 风格界面

## 项目结构

```
flutter_client/
├── lib/
│   ├── main.dart                    # 应用入口
│   ├── models/message.dart          # 消息模型
│   ├── providers/
│   │   └── chat_provider.dart       # 状态管理
│   ├── screens/
│   │   ├── login_screen.dart        # 登录页面
│   │   ├── home_screen.dart         # 主页/用户列表
│   │   └── chat_screen.dart         # 聊天页面
│   └── services/
│       └── config_service.dart      # 配置服务
├── assets/
│   └── config.json                  # 服务器配置文件
├── pubspec.yaml                     # 依赖配置
└── analysis_options.yaml            # 代码分析配置
```

## 配置服务器地址

编辑 `assets/config.json`：

```json
{
  "server": {
    "host": "your-server.com",
    "port": 8765,
    "ws_protocol": "ws"
  }
}
```

### 常见配置

| 环境 | host | port | ws_protocol |
|------|------|------|-------------|
| iOS 模拟器 | `localhost` | 8765 | ws |
| Android 模拟器 | `10.0.2.2` | 8765 | ws |
| 真机测试 | `192.168.x.x` | 8765 | ws |
| 云服务器 | `your-domain.com` | 8765 | ws |
| HTTPS | `your-domain.com` | 443 | wss |

**注意**：修改配置后需要重新编译应用。

## 安装运行

### 1. 安装 Flutter

确保已安装 Flutter SDK：
```bash
flutter doctor
```

### 2. 获取依赖

```bash
cd flutter_client
flutter pub get
```

### 3. 配置服务器

编辑 `assets/config.json` 设置服务器地址。

### 4. 启动服务器

先启动 Python WebSocket 服务器：
```bash
cd ..
python server.py
```

### 5. 运行应用

**iOS 模拟器：**
```bash
flutter run -d ios
```

**Android 模拟器：**
```bash
flutter run -d android
```

**查看可用设备：**
```bash
flutter devices
```

## 打包发布

### Android APK

```bash
flutter build apk --release
```

输出：`build/app/outputs/flutter-apk/app-release.apk`

### Android App Bundle

```bash
flutter build appbundle --release
```

### iOS

```bash
flutter build ios --release
```

> 注意：iOS 发布需要 Apple Developer 账号和 Xcode 配置

## 依赖包

- `web_socket_channel`: WebSocket 连接
- `provider`: 状态管理
- `shared_preferences`: 本地存储
- `intl`: 国际化/格式化

## 界面预览

- **登录页**: 绿色渐变背景，手机号输入
- **主页**: 群聊入口 + 在线用户列表
- **聊天页**: 气泡消息，绿色(自己)/白色(他人)
