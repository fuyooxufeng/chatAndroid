package com.example.chat_app

import android.content.Context
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/**
 * uni 一键登录插件
 * 注意：需要集成实际的 uni 一键登录 SDK
 * 当前为占位实现，需要添加实际的 SDK 调用
 */
class UniLoginPlugin(private val context: Context) : MethodCallHandler {

    companion object {
        const val CHANNEL_NAME = "com.example.chat_app/uni_login"

        fun registerWith(flutterEngine: FlutterEngine, context: Context) {
            val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
            channel.setMethodCallHandler(UniLoginPlugin(context))
        }
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "uniLogin" -> {
                // TODO: 集成实际的 uni 一键登录 SDK
                // 这里需要调用 uni 一键登录 SDK 的接口
                // 以下是模拟实现

                // 模拟返回失败，提示需要配置 SDK
                result.success(mapOf(
                    "success" to false,
                    "message" to "uni 一键登录 SDK 未配置。请在 UniLoginPlugin.kt 中添加实际的 SDK 调用。"
                ))

                // 实际集成步骤：
                // 1. 在 build.gradle 中添加 uni 一键登录 SDK 依赖
                // 2. 在 MainActivity 中初始化 SDK
                // 3. 在此处调用 SDK 的登录方法
                // 4. 返回获取到的手机号
            }
            else -> {
                result.notImplemented()
            }
        }
    }
}
