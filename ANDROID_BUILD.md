# Android APK 打包指南

服务器地址已配置为: `122.51.76.222:8765`

## 方法一：GitHub Actions 自动打包（推荐）

### 步骤 1: 创建 GitHub 仓库

1. 访问 https://github.com/new
2. 创建一个新的公开仓库（如 `chat_platform`）
3. 不要初始化 README

### 步骤 2: 上传代码

在项目根目录执行：

```bash
# 初始化 git
git init

# 添加所有文件
git add .

# 提交
git commit -m "Initial commit with GitHub Actions"

# 添加远程仓库（替换 yourusername 为你的 GitHub 用户名）
git remote add origin https://github.com/yourusername/chat_platform.git

# 推送代码
git push -u origin main
```

### 步骤 3: 等待自动构建

1. 打开 GitHub 仓库页面
2. 点击 "Actions" 标签
3. 等待构建完成（约 3-5 分钟）

### 步骤 4: 下载 APK

构建完成后：

1. 在 Actions 页面点击最新的运行记录
2. 滚动到 "Artifacts" 部分
3. 下载 `app-release-apk`
4. 解压后得到 `app-release.apk`

### 步骤 5: 安装到手机

1. 将 APK 传输到手机（微信、QQ、数据线等）
2. 在手机上点击安装
3. 允许"安装未知来源应用"

---

## 方法二：本地打包

### 前提条件

- 安装 Flutter SDK
- 安装 Android Studio
- 配置 Android SDK

### 打包命令

```bash
cd /Users/xufengrichard/Desktop/chat_platform/flutter_client

# 获取依赖
flutter pub get

# 打包发布版 APK
flutter build apk --release

# APK 位置：build/app/outputs/flutter-apk/app-release.apk
```

---

## 测试前检查清单

- [ ] 云服务器 122.51.76.222:8765 已启动
- [ ] 手机网络可以访问外网
- [ ] 已安装 APK 到手机

## 常见问题

### 连接失败

如果 APP 显示连接失败：

1. 检查服务器是否运行
2. 检查云服务器防火墙是否开放 8765 端口
3. 检查手机网络是否正常

### 安装失败

如果安装时提示解析错误：
- 确保 APK 文件完整下载
- 重新下载或重新构建

---

## 配置文件说明

如需修改服务器地址，编辑 `flutter_client/assets/config.json`：

```json
{
  "server": {
    "host": "122.51.76.222",
    "port": 8765,
    "ws_protocol": "ws"
  },
  "user": {
    "phone": "",
    "password": "aaaaaa"
  }
}
```

修改后需要重新打包。
