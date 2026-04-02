# uni 一键登录集成指南

## 概述

项目已添加 uni 一键登录的框架代码，但需要你配置实际的 SDK 才能使用。

## 集成步骤

### 1. 申请 uni 一键登录服务

访问 [uni 一键登录官网](https://www.dcloud.io/univerify.html) 申请服务，获取：
- AppID
- AppKey

### 2. 添加 SDK 依赖

在 `android/app/build.gradle` 中添加：

```gradle
dependencies {
    // ... 其他依赖

    // uni 一键登录 SDK（具体依赖需要根据官方文档）
    // implementation 'com.example:uni-login-sdk:x.x.x'
}
```

### 3. 配置 SDK

在 `android/app/src/main/kotlin/com/example/chat_app/UniLoginPlugin.kt` 中添加实际的 SDK 调用。

示例代码框架：

```kotlin
override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
        "uniLogin" -> {
            // 初始化 SDK
            UniLoginSDK.init(context, appId, appKey)

            // 调用一键登录
            UniLoginSDK.login(object : UniLoginCallback {
                override fun onSuccess(token: String) {
                    // 用 token 换取手机号
                    val phoneNumber = exchangeTokenForPhone(token)
                    result.success(mapOf(
                        "success" to true,
                        "phoneNumber" to phoneNumber
                    ))
                }

                override fun onError(errorCode: Int, errorMsg: String) {
                    result.success(mapOf(
                        "success" to false,
                        "message" to errorMsg
                    ))
                }
            })
        }
    }
}
```

### 4. 配置运营商授权

需要分别在中国移动、中国电信、中国联通开放平台申请：
- 中国移动：http://dev.10086.cn/
- 中国电信：https://id.189.cn/
- 中国联通：https://saas.wostore.cn/

### 5. 修改 AndroidManifest.xml

添加必要的权限和配置：

```xml
<uses-permission android:name="android.permission.READ_PHONE_STATE" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
```

## 注意事项

1. **测试限制**：一键登录需要使用真实 SIM 卡，且需要在真实设备上测试（模拟器不可用）
2. **运营商支持**：需要插入对应运营商的 SIM 卡
3. **网络要求**：需要蜂窝网络连接（WiFi 状态下需要支持数据网络）
4. **费用**：按调用次数收费，需要预充值

## 替代方案

如果不想使用 uni 一键登录，可以：
1. 只使用手动输入手机号
2. 使用短信验证码登录（集成短信服务商如阿里云、腾讯云）
