#!/usr/bin/env python3
"""
CTI (Command Line Interface) Chat Client
纯文字命令行聊天客户端
"""

import asyncio
import websockets
import json
import sys
import os
import argparse
from datetime import datetime
from typing import Optional, Dict, List
import signal

# ANSI 颜色代码
class Colors:
    RESET = '\033[0m'
    BOLD = '\033[1m'
    GREEN = '\033[32m'
    CYAN = '\033[36m'
    YELLOW = '\033[33m'
    RED = '\033[31m'
    MAGENTA = '\033[35m'
    GRAY = '\033[90m'
    WHITE = '\033[37m'
    BG_GREEN = '\033[42m'
    BG_BLUE = '\033[44m'

def load_config():
    """加载配置文件"""
    config_path = os.path.join(os.path.dirname(__file__), 'config.json')
    default_config = {
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

    try:
        with open(config_path, 'r', encoding='utf-8') as f:
            config = json.load(f)
            # 确保有 user 字段
            if 'user' not in config:
                config['user'] = default_config['user']
            return config
    except:
        return default_config

def get_server_url(config):
    """生成 WebSocket URL"""
    server = config.get('server', {})
    protocol = server.get('ws_protocol', 'ws')
    host = server.get('host', 'localhost')
    port = server.get('port', 8765)
    return f"{protocol}://{host}:{port}"

class CTIChatClient:
    def __init__(self):
        self.ws = None
        self.phone: Optional[str] = None
        self.password: str = "aaaaaa"
        self.connected = False
        self.logged_in = False
        self.online_users: List[str] = []
        self.selected_target: Optional[str] = None  # None = 群聊
        self.messages: Dict[str, List[dict]] = {}  # target: messages
        self.input_queue = asyncio.Queue()
        self.running = True
        self.current_screen = "login"  # login, chat, users

    def clear_screen(self):
        """清屏"""
        os.system('cls' if os.name == 'nt' else 'clear')

    def print_header(self, title: str):
        """打印标题栏"""
        width = 60
        print(f"\n{Colors.BG_BLUE}{Colors.WHITE}{Colors.BOLD}")
        print(f" {title:^{width-2}} ")
        print(f"{Colors.RESET}")

    def print_banner(self):
        """打印应用横幅"""
        banner = f"""
{Colors.CYAN}{Colors.BOLD}
   ____ _           _      ____ _           _
  / ___| |__   __ _| |_   / ___| |_   _ ___| |_
 | |   | '_ \\ / _` | __| | |   | | | | / __| __|
 | |___| | | | (_| | |_  | |___| | |_| \\__ \\ |_
  \\____|_| |_|\\__,_|\\__|  \\____|_|\\__,_|___/\\__|
{Colors.RESET}
        """
        print(banner)

    def print_status(self):
        """打印状态栏"""
        if self.logged_in:
            target = "群聊" if self.selected_target is None else f"私聊: {self.selected_target}"
            users_count = len(self.online_users)
            print(f"{Colors.GRAY}[{self.phone}] | {target} | 在线: {users_count}人 | 输入 /help 查看命令{Colors.RESET}")
        print("-" * 60)

    def print_message(self, msg: dict, show_sender: bool = True):
        """打印单条消息"""
        from_user = msg.get('from', '')
        content = msg.get('content', '')
        time_str = msg.get('time', datetime.now().strftime("%H:%M"))
        is_me = from_user == self.phone

        if is_me:
            print(f"{Colors.GRAY}{time_str}{Colors.RESET} {Colors.GREEN}➤ 你: {content}{Colors.RESET}")
        else:
            if show_sender:
                print(f"{Colors.GRAY}{time_str}{Colors.RESET} {Colors.CYAN}◀ {from_user}:{Colors.RESET} {content}")
            else:
                print(f"{Colors.GRAY}{time_str}{Colors.RESET} {content}")

    def print_chat_history(self):
        """打印当前聊天的历史消息"""
        self.clear_screen()
        self.print_header("💬 Chat Room")

        key = "group" if self.selected_target is None else self.selected_target
        messages = self.messages.get(key, [])

        if not messages:
            print(f"\n{Colors.GRAY}  (暂无消息，开始聊天吧...)\n{Colors.RESET}")
        else:
            print()
            for msg in messages:
                self.print_message(msg)
            print()

        self.print_status()

    def print_user_list(self):
        """打印在线用户列表"""
        self.clear_screen()
        self.print_header("👥 Online Users")
        print()

        # 群聊选项
        indicator = "▶" if self.selected_target is None else " "
        print(f"  {Colors.GREEN if self.selected_target is None else Colors.WHITE}{indicator} [群聊]{Colors.RESET}")
        print()

        # 用户列表
        for user in sorted(self.online_users):
            if user == self.phone:
                continue
            indicator = "▶" if self.selected_target == user else " "
            status = f"{Colors.GREEN}●{Colors.RESET}" if user in self.online_users else f"{Colors.GRAY}○{Colors.RESET}"
            print(f"  {status} {Colors.CYAN if self.selected_target == user else Colors.WHITE}{indicator} {user}{Colors.RESET}")

        print(f"\n{Colors.GRAY}  共 {len(self.online_users)} 人在线{Colors.RESET}")
        print("\n" + "-" * 60)
        print(f"{Colors.GRAY}输入数字选择用户，或按 Enter 返回聊天{Colors.RESET}")

    def print_help(self):
        """打印帮助信息"""
        help_text = f"""
{Colors.BOLD}可用命令:{Colors.RESET}

  {Colors.CYAN}/users{Colors.RESET}     - 查看在线用户列表
  {Colors.CYAN}/group{Colors.RESET}     - 切换到群聊
  {Colors.CYAN}/to <手机号>{Colors.RESET} - 切换到私聊
  {Colors.CYAN}/clear{Colors.RESET}     - 清屏
  {Colors.CYAN}/quit{Colors.RESET}      - 退出程序
  {Colors.CYAN}/help{Colors.RESET}      - 显示帮助

{Colors.BOLD}直接输入消息发送，默认发送到当前选中的聊天对象。{Colors.RESET}
"""
        print(help_text)

    async def handle_input(self):
        """处理用户输入"""
        loop = asyncio.get_event_loop()

        while self.running:
            try:
                # 在单独的线程中读取输入
                user_input = await loop.run_in_executor(
                    None, lambda: input(f"{Colors.YELLOW}> {Colors.RESET}")
                )
                await self.input_queue.put(user_input.strip())
            except EOFError:
                await self.input_queue.put("/quit")
            except KeyboardInterrupt:
                await self.input_queue.put("/quit")

    async def process_command(self, cmd: str):
        """处理命令"""
        if not cmd:
            return True

        if cmd.startswith("/"):
            parts = cmd.split(maxsplit=1)
            command = parts[0].lower()
            arg = parts[1] if len(parts) > 1 else ""

            if command == "/quit" or command == "/q":
                print(f"{Colors.YELLOW}正在退出...{Colors.RESET}")
                self.running = False
                return False

            elif command == "/help" or command == "/h":
                self.print_help()

            elif command == "/clear":
                self.print_chat_history()

            elif command == "/users" or command == "/u":
                self.print_user_list()
                # 等待用户选择
                try:
                    selection = await asyncio.wait_for(
                        self.input_queue.get(), timeout=30.0
                    )
                    if selection.isdigit():
                        idx = int(selection) - 1
                        users = [u for u in sorted(self.online_users) if u != self.phone]
                        if 0 <= idx < len(users):
                            self.selected_target = users[idx]
                            self.print_chat_history()
                    else:
                        self.print_chat_history()
                except asyncio.TimeoutError:
                    self.print_chat_history()

            elif command == "/group" or command == "/g":
                self.selected_target = None
                self.print_chat_history()

            elif command == "/to":
                if arg in self.online_users and arg != self.phone:
                    self.selected_target = arg
                    self.print_chat_history()
                else:
                    print(f"{Colors.RED}用户不在线或不存在{Colors.RESET}")

            else:
                print(f"{Colors.RED}未知命令: {command}{Colors.RESET}")
                print(f"{Colors.GRAY}输入 /help 查看可用命令{Colors.RESET}")

        else:
            # 发送消息
            if self.ws and self.connected:
                msg = {
                    "type": "message",
                    "content": cmd,
                    "target": self.selected_target
                }
                await self.ws.send(json.dumps(msg))
            else:
                print(f"{Colors.RED}未连接到服务器{Colors.RESET}")

        return True

    async def websocket_client(self, server_url: str):
        """WebSocket 客户端主循环"""
        try:
            async with websockets.connect(server_url) as ws:
                self.ws = ws
                self.connected = True

                # 发送登录信息
                await ws.send(json.dumps({
                    "type": "login",
                    "phone": self.phone,
                    "password": self.password
                }))

                async for message in ws:
                    data = json.loads(message)
                    await self.handle_message(data)

        except websockets.exceptions.ConnectionClosed:
            print(f"\n{Colors.RED}连接已关闭{Colors.RESET}")
        except Exception as e:
            print(f"\n{Colors.RED}连接错误: {e}{Colors.RESET}")
        finally:
            self.connected = False
            self.running = False

    async def handle_message(self, data: dict):
        """处理收到的消息"""
        msg_type = data.get("type")

        if msg_type == "login_success":
            self.logged_in = True
            self.online_users = data.get("online_users", [])
            self.print_chat_history()

        elif msg_type in ("user_online", "user_offline"):
            self.online_users = data.get("online_users", [])

        elif msg_type == "message":
            self.receive_message(data)

        elif msg_type == "error":
            print(f"\n{Colors.RED}错误: {data.get('message')}{Colors.RESET}")

    def receive_message(self, data: dict):
        """接收并存储消息"""
        from_user = data.get("from")
        is_group = data.get("is_group", False)
        target = data.get("target")

        # 确定存储键
        if is_group:
            key = "group"
        else:
            key = from_user if from_user != self.phone else target

        if key not in self.messages:
            self.messages[key] = []
        self.messages[key].append(data)

        # 如果是当前聊天对象的消息，刷新显示
        current_key = "group" if self.selected_target is None else self.selected_target
        if key == current_key:
            self.print_message(data)

    async def run(self, phone: str, password: str, server_url: str):
        """运行客户端"""
        self.phone = phone
        self.password = password

        self.clear_screen()
        self.print_banner()
        print(f"{Colors.GRAY}正在连接到 {server_url}...{Colors.RESET}\n")

        # 启动 WebSocket 和输入处理
        ws_task = asyncio.create_task(self.websocket_client(server_url))
        input_task = asyncio.create_task(self.handle_input())

        # 主循环
        while self.running:
            try:
                user_input = await asyncio.wait_for(
                    self.input_queue.get(), timeout=0.1
                )
                if not await self.process_command(user_input):
                    break
            except asyncio.TimeoutError:
                continue

        # 清理
        ws_task.cancel()
        input_task.cancel()
        try:
            await ws_task
        except asyncio.CancelledError:
            pass

def main():
    parser = argparse.ArgumentParser(
        description='CTI Chat Client - 纯文字聊天客户端',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
示例:
  %(prog)s                           # 交互式输入手机号
  %(prog)s -p 13800138000            # 直接指定手机号
  %(prog)s -c /path/to/config.json   # 使用自定义配置文件

命令:
  /users, /u    - 查看在线用户
  /group, /g    - 切换到群聊
  /to <手机号>   - 切换到私聊
  /clear        - 清屏
  /quit, /q     - 退出
  /help, /h     - 显示帮助
        """
    )

    parser.add_argument(
        '-p', '--phone',
        help='手机号 (如不指定则交互式输入)'
    )
    parser.add_argument(
        '-c', '--config',
        default='config.json',
        help='配置文件路径 (默认: config.json)'
    )
    parser.add_argument(
        '--host',
        help='服务器地址 (覆盖配置文件)'
    )
    parser.add_argument(
        '--port',
        type=int,
        help='服务器端口 (覆盖配置文件)'
    )

    args = parser.parse_args()

    # 加载配置
    config = load_config()

    # 命令行参数覆盖配置
    if args.host:
        config['server']['host'] = args.host
    if args.port:
        config['server']['port'] = args.port

    server_url = get_server_url(config)

    # 获取手机号 (优先级: 命令行 > 配置文件 > 交互式输入)
    phone = args.phone
    if not phone:
        phone = config.get('user', {}).get('phone', '').strip()

    if not phone:
        print(f"\n{Colors.CYAN}{Colors.BOLD}CTI Chat Client{Colors.RESET}")
        print(f"{Colors.GRAY}服务器: {server_url}{Colors.RESET}\n")
        phone = input(f"{Colors.YELLOW}请输入手机号: {Colors.RESET}").strip()

    if not phone:
        print(f"{Colors.RED}错误: 手机号不能为空{Colors.RESET}")
        sys.exit(1)

    # 获取密码 (优先级: 配置文件 > 默认值)
    password = config.get('user', {}).get('password', 'aaaaaa').strip()
    if not password:
        password = 'aaaaaa'

    # 运行客户端
    client = CTIChatClient()

    try:
        asyncio.run(client.run(phone, password, server_url))
    except KeyboardInterrupt:
        print(f"\n{Colors.YELLOW}已退出{Colors.RESET}")
    except Exception as e:
        print(f"\n{Colors.RED}错误: {e}{Colors.RESET}")

if __name__ == "__main__":
    main()
