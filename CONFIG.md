# 客户端配置说明

所有客户端都支持通过配置文件自定义服务器地址、端口以及自动登录信息。

## 配置文件位置

| 客户端 | 配置文件路径 |
|--------|-------------|
| Python 桌面端 | `config.json` (与 client.py 同目录) |
| Python CTI 端 | `config.json` (与 cti_client.py 同目录) |
| Flutter 移动端 | `assets/config.json` |

## 配置格式

```json
{
  "server": {
    "host": "your-server.com",
    "port": 8765,
    "ws_protocol": "ws"
  },
  "user": {
    "phone": "13800138000",
    "password": "aaaaaa"
  }
}
```

### 配置项说明

| 配置项 | 说明 | 默认值 |
|--------|------|--------|
| `server.host` | 服务器地址 | `localhost` |
| `server.port` | 服务器端口 | `8765` |
| `server.ws_protocol` | 协议：`ws`(http) 或 `wss`(https) | `ws` |
| `user.phone` | 手机号（为空则手动输入） | `""` |
| `user.password` | 登录密码 | `aaaaaa` |

## 自动登录

在配置文件中填写 `user.phone` 后，客户端启动时会自动使用配置的手机号和密码登录，无需手动输入。

```json
{
  "user": {
    "phone": "13800138000",
    "password": "aaaaaa"
  }
}
```

- **Python 桌面端**: 配置 phone 后自动登录
- **CTI 客户端**: 配置 phone 后自动登录，命令行参数 `-p` 可覆盖配置
- **Flutter 移动端**: 配置 phone 后自动登录，显示加载界面

## 常见配置示例

### 本地开发
```json
{
  "server": {
    "host": "localhost",
    "port": 8765,
    "ws_protocol": "ws"
  },
  "user": {
    "phone": "",
    "password": "aaaaaa"
  }
}
```

### 云服务器部署 + 自动登录
```json
{
  "server": {
    "host": "your-server-ip-or-domain.com",
    "port": 8765,
    "ws_protocol": "ws"
  },
  "user": {
    "phone": "13800138000",
    "password": "aaaaaa"
  }
}
```

### HTTPS/WSS 部署
```json
{
  "server": {
    "host": "your-domain.com",
    "port": 443,
    "ws_protocol": "wss"
  },
  "user": {
    "phone": "13800138000",
    "password": "aaaaaa"
  }
}
```

## 移动端特殊配置

### Android 模拟器
```json
{
  "server": {
    "host": "10.0.2.2",
    "port": 8765,
    "ws_protocol": "ws"
  }
}
```

### iOS 模拟器
```json
{
  "server": {
    "host": "localhost",
    "port": 8765,
    "ws_protocol": "ws"
  }
}
```

### 真机测试
将 `host` 设置为电脑的局域网 IP：
```json
{
  "server": {
    "host": "192.168.1.100",
    "port": 8765,
    "ws_protocol": "ws"
  }
}
```

## Flutter 配置更新步骤

1. 修改 `flutter_client/assets/config.json`
2. 重新编译应用：
   ```bash
   cd flutter_client
   flutter build apk  # Android
   flutter build ios  # iOS
   ```

## 注意事项

1. **Python 客户端**：配置文件不存在时会自动创建默认配置
2. **Flutter 客户端**：修改配置后需要重新编译
3. **CTI 客户端**：命令行参数 `-p` 优先级高于配置文件
4. **云服务器部署**：确保服务器防火墙开放对应端口
5. **HTTPS/WSS**：需要配置 SSL 证书
