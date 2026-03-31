import asyncio
import websockets
import json
from datetime import datetime

# 存储连接的用户 {phone: websocket}
connected_clients = {}

# 存储用户消息历史 {phone: [{from, content, time}]}
message_history = {}

async def broadcast(message, exclude=None):
    """广播消息给所有用户"""
    disconnected = []
    for phone, ws in connected_clients.items():
        if phone != exclude:
            try:
                await ws.send(json.dumps(message))
            except:
                disconnected.append(phone)

    # 清理断开的连接
    for phone in disconnected:
        if phone in connected_clients:
            del connected_clients[phone]

async def send_to_user(phone, message):
    """发送消息给指定用户"""
    if phone in connected_clients:
        try:
            await connected_clients[phone].send(json.dumps(message))
            return True
        except:
            del connected_clients[phone]
    return False

async def handler(websocket):
    """处理客户端连接"""
    phone = None

    try:
        async for message in websocket:
            try:
                data = json.loads(message)
                msg_type = data.get('type')

                # 登录
                if msg_type == 'login':
                    phone = data.get('phone')
                    password = data.get('password')

                    if not phone:
                        await websocket.send(json.dumps({
                            'type': 'error',
                            'message': '手机号不能为空'
                        }))
                        continue

                    # 简单的密码验证
                    if password != 'aaaaaa':
                        await websocket.send(json.dumps({
                            'type': 'error',
                            'message': '密码错误'
                        }))
                        continue

                    # 注册客户端
                    connected_clients[phone] = websocket

                    # 发送登录成功消息
                    await websocket.send(json.dumps({
                        'type': 'login_success',
                        'phone': phone,
                        'online_users': list(connected_clients.keys())
                    }))

                    # 广播用户上线通知
                    await broadcast({
                        'type': 'user_online',
                        'phone': phone,
                        'online_users': list(connected_clients.keys())
                    }, exclude=phone)

                    print(f"用户 {phone} 已登录")

                # 发送消息
                elif msg_type == 'message':
                    if not phone:
                        await websocket.send(json.dumps({
                            'type': 'error',
                            'message': '请先登录'
                        }))
                        continue

                    content = data.get('content', '').strip()
                    target = data.get('target')  # None 表示群发

                    if not content:
                        continue

                    msg_data = {
                        'type': 'message',
                        'from': phone,
                        'content': content,
                        'time': datetime.now().strftime('%H:%M'),
                        'is_group': target is None
                    }

                    if target is None:
                        # 群发
                        msg_data['target'] = 'all'
                        await broadcast(msg_data, exclude=phone)
                        # 给自己发送确认
                        await websocket.send(json.dumps(msg_data))
                        print(f"[{phone}] 群发: {content}")
                    else:
                        # 私聊
                        msg_data['target'] = target
                        success = await send_to_user(target, msg_data)
                        # 给自己发送确认
                        await websocket.send(json.dumps(msg_data))

                        if not success:
                            await websocket.send(json.dumps({
                                'type': 'error',
                                'message': f'用户 {target} 不在线'
                            }))
                        else:
                            print(f"[{phone}] -> [{target}]: {content}")

                # 获取在线用户列表
                elif msg_type == 'get_users':
                    await websocket.send(json.dumps({
                        'type': 'user_list',
                        'users': list(connected_clients.keys())
                    }))

            except json.JSONDecodeError:
                await websocket.send(json.dumps({
                    'type': 'error',
                    'message': '无效的消息格式'
                }))

    except websockets.exceptions.ConnectionClosed:
        pass
    finally:
        # 用户断开连接
        if phone and phone in connected_clients:
            del connected_clients[phone]
            await broadcast({
                'type': 'user_offline',
                'phone': phone,
                'online_users': list(connected_clients.keys())
            })
            print(f"用户 {phone} 已断开")

async def main():
    """启动服务器"""
    print("聊天服务器启动中...")
    print("监听地址: 0.0.0.0:8765")
    print("本地访问: ws://localhost:8765")
    print("局域网访问: ws://YOUR_IP:8765")
    print("按 Ctrl+C 停止服务器\n")

    async with websockets.serve(handler, '0.0.0.0', 8765):
        await asyncio.Future()  # 永久运行

if __name__ == '__main__':
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\n服务器已关闭")
