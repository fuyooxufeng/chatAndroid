# 聊天平台项目总览

完整的跨平台聊天解决方案，包含服务器、桌面客户端和移动客户端。

## 项目结构

```
chat_platform/
├── server.py                 # Python WebSocket 服务器
├── client.py                 # Python tkinter 桌面客户端
├── flutter_client/           # Flutter 移动客户端
│   ├── lib/
│   │   ├── main.dart
│   │   ├── models/
│   │   ├── providers/
│   │   └── screens/
│   ├── pubspec.yaml
│   └── README.md
├── requirements.txt          # Python 依赖
└── README.md
```

## 快速开始

### 1. 启动服务器

```bash
python server.py
```

### 2. 运行桌面客户端

```bash
python client.py
```

### 3. 运行移动客户端

```bash
cd flutter_client
flutter pub get
flutter run
```

## 平台支持

| 平台 | 客户端 | 状态 |
|------|--------|------|
| Windows | Python tkinter | ✅ 支持 |
| macOS | Python tkinter | ✅ 支持 |
| Linux | Python tkinter | ✅ 支持 |
| Android | Flutter | ✅ 支持 |
| iOS | Flutter | ✅ 支持 |

## 功能对比

| 功能 | 桌面端 | 移动端 |
|------|--------|--------|
| 手机号登录 | ✅ | ✅ |
| 群聊 | ✅ | ✅ |
| 私聊 | ✅ | ✅ |
| 在线用户列表 | ✅ | ✅ |
| WhatsApp 风格 | ✅ | ✅ |
| 消息时间戳 | ✅ | ✅ |

## 默认设置

- 密码: `aaaaaa`
- 服务器端口: `8765`

## 网络配置

- 本地测试: `ws://localhost:8765`
- Android 模拟器: `ws://10.0.2.2:8765`
- 局域网: `ws://<服务器IP>:8765`
