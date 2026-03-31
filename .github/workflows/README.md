# GitHub Actions 自动打包

此配置用于自动构建 Android APK 安装包。

## 使用方法

### 1. 推送代码到 GitHub

确保项目已上传到 GitHub 仓库。

```bash
# 在项目根目录初始化 git
git init
git add .
git commit -m "Initial commit"

# 创建 GitHub 仓库并推送
git remote add origin https://github.com/yourusername/chat_platform.git
git push -u origin main
```

### 2. 触发自动构建

构建会在以下情况自动触发：
- 推送到 `main` 或 `master` 分支
- 提交 Pull Request 到 `main` 或 `master` 分支
- 手动触发（见下方）

### 3. 手动触发构建

1. 打开 GitHub 仓库页面
2. 点击 "Actions" 标签
3. 选择 "Build Android APK" 工作流
4. 点击 "Run workflow" 按钮

### 4. 下载 APK

构建完成后，可以在以下位置下载 APK：

#### 方式一：从 Artifacts 下载
1. 进入 Actions 页面
2. 点击最新的工作流运行记录
3. 在 "Artifacts" 部分下载 `app-release-apk`

#### 方式二：从 Releases 下载（自动发布）
当代码推送到 main 分支时，会自动创建 Release 并上传 APK。
1. 进入仓库的 "Releases" 页面
2. 下载最新版本的 APK

## 构建输出

| 文件 | 说明 |
|------|------|
| `app-debug.apk` | 调试版本，包含调试信息 |
| `app-release.apk` | 发布版本，体积更小 |

## 自定义配置

如需修改服务器地址，编辑 `flutter_client/assets/config.json` 后重新推送。

## 注意事项

1. GitHub Actions 免费额度：每月 2000 分钟（公开仓库无限）
2. Artifacts 默认保留 90 天
3. 每次推送都会触发新的构建
