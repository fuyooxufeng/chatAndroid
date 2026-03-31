# 聊天平台

简单的跨平台聊天应用，类似 WhatsApp 界面。支持桌面端和移动端。

## 项目结构

```
chat_platform/
├── server.py           # WebSocket 服务器
├── client.py           # Python 桌面客户端
├── config.json         # 客户端配置文件
├── flutter_client/     # Flutter 移动客户端
├── requirements.txt    # Python 依赖
├── README.md           # 本文件
├── CONFIG.md           # 配置说明文档
└── PROJECT.md          # 项目总览
```

## 功能特点

- 手机号登录（密码统一为 `aaaaaa`）
- 群聊功能
- 私聊功能
- 实时在线用户列表
- WhatsApp 风格界面
- 支持自定义服务器地址（通过配置文件）

## 配置服务器地址

所有客户端都支持通过配置文件设置服务器地址，详见 [CONFIG.md](CONFIG.md)。

**快速配置示例**：

编辑 `config.json`：
```json
{
  "server": {
    "host": "your-server.com",
    "port": 8765,
    "ws_protocol": "ws"
  }
}
```

## 安装依赖

```bash
cd /Users/xufengrichard/Desktop/chat_platform
pip install -r requirements.txt
```

## 启动服务

### 1. 启动服务器

```bash
python server.py
```

服务器默认监听 `0.0.0.0:8765`，支持局域网访问。

### 2. 启动桌面客户端

```bash
python client.py
```

### 3. 运行移动客户端

```bash
cd flutter_client
flutter pub get
flutter run
```

## 使用方法

1. 启动服务器
2. 启动客户端
3. 在登录页面输入手机号（如：13800138000）
4. 密码统一为：`aaaaaa`
5. 点击用户列表进行私聊，或点击"群聊"进行群发

## 界面说明

- **左侧**：用户列表，显示在线用户
- **右侧**：聊天区域
  - 顶部：当前聊天对象名称
  - 中间：消息显示区域（绿色气泡=自己，白色气泡=他人）
  - 底部：消息输入框和发送按钮

## 平台支持

| 平台 | 客户端 | 状态 |
|------|--------|------|
| Windows | Python tkinter | ✅ 支持 |
| macOS | Python tkinter | ✅ 支持 |
| Linux | Python tkinter | ✅ 支持 |
| Android | Flutter | ✅ 支持 |
| iOS | Flutter | ✅ 支持 |

## 文件说明

- `server.py` - WebSocket 服务器
- `client.py` - Python GUI 桌面客户端
- `config.json` - 客户端配置文件（服务器地址和端口）
- `requirements.txt` - Python 依赖列表
