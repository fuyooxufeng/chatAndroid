import asyncio
import websockets
import json
import threading
import tkinter as tk
from tkinter import messagebox
from datetime import datetime
from queue import Queue
import os

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
    except FileNotFoundError:
        # 创建默认配置文件
        with open(config_path, 'w', encoding='utf-8') as f:
            json.dump(default_config, f, indent=2, ensure_ascii=False)
        return default_config
    except json.JSONDecodeError:
        print("配置文件格式错误，使用默认配置")
        return default_config

def get_server_url(config):
    """根据配置生成 WebSocket URL"""
    server = config.get('server', {})
    protocol = server.get('ws_protocol', 'ws')
    host = server.get('host', 'localhost')
    port = server.get('port', 8765)
    return f"{protocol}://{host}:{port}"

class ChatClient:
    def __init__(self, root):
        self.root = root
        self.root.title("Chat App")
        self.root.geometry("900x600")
        self.root.configure(bg="#f0f0f0")

        self.phone = None
        self.ws = None
        self.ws_thread = None
        self.loop = None
        self.selected_user = None
        self.messages = {}
        self.msg_queue = Queue()

        # 加载配置
        self.config = load_config()
        self.server_url = get_server_url(self.config)

        self.setup_ui()

        # 检查配置中是否有手机号，有则自动登录
        config_phone = self.config.get('user', {}).get('phone', '').strip()
        if config_phone:
            self.phone = config_phone
            self.user_label.config(text=self.phone)
            self.start_websocket(self.phone)
        else:
            self.show_login_dialog()

        # 启动消息处理循环
        self.process_messages()

    def setup_ui(self):
        # 主框架
        self.main_frame = tk.Frame(self.root, bg="#f0f0f0")
        self.main_frame.pack(fill=tk.BOTH, expand=True)

        # 左侧用户列表面板
        self.left_panel = tk.Frame(self.main_frame, bg="#128c7e", width=280)
        self.left_panel.pack(side=tk.LEFT, fill=tk.Y)
        self.left_panel.pack_propagate(False)

        # 顶部标题栏
        self.header = tk.Frame(self.left_panel, bg="#075e54", height=60)
        self.header.pack(fill=tk.X)
        self.header.pack_propagate(False)

        self.title_label = tk.Label(
            self.header,
            text="Chat App",
            font=("Helvetica", 16, "bold"),
            bg="#075e54",
            fg="white"
        )
        self.title_label.pack(side=tk.LEFT, padx=15, pady=15)

        self.user_label = tk.Label(
            self.header,
            text="",
            font=("Helvetica", 10),
            bg="#075e54",
            fg="#ddd"
        )
        self.user_label.pack(side=tk.RIGHT, padx=15, pady=20)

        # 搜索框
        self.search_frame = tk.Frame(self.left_panel, bg="#128c7e", height=50)
        self.search_frame.pack(fill=tk.X, padx=10, pady=10)
        self.search_frame.pack_propagate(False)

        self.search_entry = tk.Entry(
            self.search_frame,
            font=("Helvetica", 12),
            bg="#1ebea5",
            fg="white",
            insertbackground="white",
            relief=tk.FLAT
        )
        self.search_entry.pack(fill=tk.BOTH, expand=True, padx=5, pady=5)
        self.search_entry.insert(0, " 搜索或开始新聊天")
        self.search_entry.bind('<FocusIn>', lambda e: self.search_entry.delete(0, tk.END) if self.search_entry.get() == " 搜索或开始新聊天" else None)
        self.search_entry.bind('<FocusOut>', lambda e: self.search_entry.insert(0, " 搜索或开始新聊天") if self.search_entry.get() == "" else None)

        # 群聊按钮
        self.group_btn = tk.Frame(self.left_panel, bg="#128c7e", height=60, cursor="hand2")
        self.group_btn.pack(fill=tk.X)
        self.group_btn.pack_propagate(False)
        self.group_btn.bind('<Button-1>', lambda e: self.select_chat(None))

        tk.Label(
            self.group_btn,
            text="👥",
            font=("Helvetica", 24),
            bg="#128c7e",
            fg="white"
        ).pack(side=tk.LEFT, padx=15, pady=5)

        tk.Label(
            self.group_btn,
            text="群聊",
            font=("Helvetica", 14, "bold"),
            bg="#128c7e",
            fg="white"
        ).pack(side=tk.LEFT, pady=15)

        # 分隔线
        tk.Frame(self.left_panel, bg="#0d6b5d", height=1).pack(fill=tk.X, padx=10)

        # 用户列表容器
        self.users_canvas = tk.Canvas(self.left_panel, bg="#128c7e", highlightthickness=0)
        self.users_canvas.pack(fill=tk.BOTH, expand=True, side=tk.LEFT)

        self.users_scrollbar = tk.Scrollbar(self.left_panel, orient="vertical", command=self.users_canvas.yview)
        self.users_scrollbar.pack(side=tk.RIGHT, fill=tk.Y)
        self.users_canvas.configure(yscrollcommand=self.users_scrollbar.set)

        self.users_frame = tk.Frame(self.users_canvas, bg="#128c7e")
        self.users_canvas.create_window((0, 0), window=self.users_frame, anchor="nw", width=260)

        self.users_frame.bind("<Configure>", lambda e: self.users_canvas.configure(scrollregion=self.users_canvas.bbox("all")))

        # 右侧聊天区域
        self.right_panel = tk.Frame(self.main_frame, bg="#e5ddd5")
        self.right_panel.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)

        # 聊天头部
        self.chat_header = tk.Frame(self.right_panel, bg="#075e54", height=60)
        self.chat_header.pack(fill=tk.X)
        self.chat_header.pack_propagate(False)

        self.chat_title = tk.Label(
            self.chat_header,
            text="选择一个聊天",
            font=("Helvetica", 14, "bold"),
            bg="#075e54",
            fg="white"
        )
        self.chat_title.pack(side=tk.LEFT, padx=15, pady=15)

        # 消息区域
        self.messages_frame = tk.Frame(self.right_panel, bg="#e5ddd5")
        self.messages_frame.pack(fill=tk.BOTH, expand=True)

        self.messages_canvas = tk.Canvas(self.messages_frame, bg="#e5ddd5", highlightthickness=0)
        self.messages_canvas.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)

        self.msg_scrollbar = tk.Scrollbar(self.messages_frame, orient="vertical", command=self.messages_canvas.yview)
        self.msg_scrollbar.pack(side=tk.RIGHT, fill=tk.Y)
        self.messages_canvas.configure(yscrollcommand=self.msg_scrollbar.set)

        self.msg_container = tk.Frame(self.messages_canvas, bg="#e5ddd5")
        self.messages_canvas.create_window((0, 0), window=self.msg_container, anchor="nw", width=580)

        self.msg_container.bind("<Configure>", lambda e: self.messages_canvas.configure(scrollregion=self.messages_canvas.bbox("all")))

        # 输入区域
        self.input_frame = tk.Frame(self.right_panel, bg="#f0f0f0", height=60)
        self.input_frame.pack(fill=tk.X, side=tk.BOTTOM)
        self.input_frame.pack_propagate(False)

        self.msg_entry = tk.Entry(
            self.input_frame,
            font=("Helvetica", 14),
            bg="white",
            relief=tk.FLAT
        )
        self.msg_entry.pack(side=tk.LEFT, fill=tk.BOTH, expand=True, padx=10, pady=10)
        self.msg_entry.bind('<Return>', lambda e: self.send_message())

        self.send_btn = tk.Button(
            self.input_frame,
            text="发送",
            font=("Helvetica", 12, "bold"),
            bg="#128c7e",
            fg="white",
            relief=tk.FLAT,
            cursor="hand2",
            command=self.send_message
        )
        self.send_btn.pack(side=tk.RIGHT, padx=10, pady=10)

    def show_login_dialog(self):
        dialog = tk.Toplevel(self.root)
        dialog.title("登录")
        dialog.geometry("300x200")
        dialog.transient(self.root)
        dialog.grab_set()
        dialog.resizable(False, False)

        tk.Label(dialog, text="手机号:", font=("Helvetica", 12)).pack(pady=(30, 5))

        phone_entry = tk.Entry(dialog, font=("Helvetica", 14), width=20)
        phone_entry.pack(pady=5)
        phone_entry.focus()

        tk.Label(dialog, text="密码: aaaaaa", font=("Helvetica", 10), fg="gray").pack(pady=5)

        def do_login():
            phone = phone_entry.get().strip()
            if not phone:
                messagebox.showerror("错误", "请输入手机号")
                return
            dialog.destroy()
            self.phone = phone
            self.user_label.config(text=phone)
            self.start_websocket(phone)

        tk.Button(
            dialog,
            text="登录",
            font=("Helvetica", 12),
            bg="#128c7e",
            fg="white",
            width=15,
            command=do_login
        ).pack(pady=20)

        phone_entry.bind('<Return>', lambda e: do_login())

    def start_websocket(self, phone):
        """在后台线程启动 WebSocket 连接"""
        self.ws_thread = threading.Thread(target=self.run_websocket, args=(phone,), daemon=True)
        self.ws_thread.start()

    def run_websocket(self, phone):
        """在新线程中运行 asyncio 事件循环"""
        self.loop = asyncio.new_event_loop()
        asyncio.set_event_loop(self.loop)
        self.loop.run_until_complete(self.websocket_client(phone))

    async def websocket_client(self, phone):
        """WebSocket 客户端主循环"""
        try:
            async with websockets.connect(self.server_url) as ws:
                self.ws = ws

                # 发送登录信息
                await ws.send(json.dumps({
                    "type": "login",
                    "phone": phone,
                    "password": "aaaaaa"
                }))

                async for message in ws:
                    data = json.loads(message)
                    self.msg_queue.put(data)
        except Exception as e:
            self.msg_queue.put({"type": "error", "message": f"连接错误: {e}"})

    def process_messages(self):
        """处理消息队列（在主线程中）"""
        while not self.msg_queue.empty():
            data = self.msg_queue.get()
            self.handle_message(data)
        self.root.after(100, self.process_messages)

    def handle_message(self, data):
        """处理收到的消息"""
        msg_type = data.get("type")

        if msg_type == "login_success":
            self.update_user_list(data.get("online_users", []))

        elif msg_type == "user_online":
            self.update_user_list(data.get("online_users", []))

        elif msg_type == "user_offline":
            self.update_user_list(data.get("online_users", []))

        elif msg_type == "message":
            self.receive_message(data)

        elif msg_type == "error":
            messagebox.showerror("错误", data.get("message"))

    def update_user_list(self, users):
        """更新用户列表"""
        for widget in self.users_frame.winfo_children():
            widget.destroy()

        for user in users:
            if user == self.phone:
                continue

            user_btn = tk.Frame(self.users_frame, bg="#128c7e", height=60, cursor="hand2")
            user_btn.pack(fill=tk.X)
            user_btn.pack_propagate(False)

            avatar = tk.Label(
                user_btn,
                text=user[0].upper() if user else "?",
                font=("Helvetica", 18, "bold"),
                bg="#ddd",
                fg="#555",
                width=2,
                height=1
            )
            avatar.pack(side=tk.LEFT, padx=10, pady=5)

            name = tk.Label(
                user_btn,
                text=user,
                font=("Helvetica", 14),
                bg="#128c7e",
                fg="white"
            )
            name.pack(side=tk.LEFT, pady=15)

            def on_click(event, u=user):
                self.select_chat(u)

            user_btn.bind('<Button-1>', on_click)
            avatar.bind('<Button-1>', on_click)
            name.bind('<Button-1>', on_click)

        self.users_canvas.update_idletasks()
        self.users_canvas.configure(scrollregion=self.users_canvas.bbox("all"))

    def select_chat(self, user):
        """选择聊天对象"""
        self.selected_user = user
        self.chat_title.config(text="群聊" if user is None else user)

        # 清空消息区域
        for widget in self.msg_container.winfo_children():
            widget.destroy()

        # 显示历史消息
        key = "group" if user is None else user
        if key in self.messages:
            for msg in self.messages[key]:
                self.display_message(msg)

    def receive_message(self, data):
        """接收并存储消息"""
        from_user = data.get("from")
        is_group = data.get("is_group", False)
        target = data.get("target")

        if is_group:
            key = "group"
        else:
            key = from_user if from_user != self.phone else target

        if key not in self.messages:
            self.messages[key] = []
        self.messages[key].append(data)

        current_key = "group" if self.selected_user is None else self.selected_user
        if key == current_key:
            self.display_message(data)

    def display_message(self, data):
        """在界面上显示消息"""
        from_user = data.get("from")
        content = data.get("content")
        time_str = data.get("time", datetime.now().strftime("%H:%M"))
        is_me = from_user == self.phone

        msg_frame = tk.Frame(self.msg_container, bg="#e5ddd5")
        msg_frame.pack(fill=tk.X, padx=10, pady=3)

        bubble = tk.Frame(
            msg_frame,
            bg="#dcf8c6" if is_me else "white",
            padx=10,
            pady=6
        )

        if is_me:
            bubble.pack(side=tk.RIGHT)
            msg_frame.pack_configure(anchor="e")
        else:
            bubble.pack(side=tk.LEFT)
            msg_frame.pack_configure(anchor="w")

        if not is_me:
            sender = tk.Label(
                bubble,
                text=from_user,
                font=("Helvetica", 9),
                bg=bubble["bg"],
                fg="#128c7e"
            )
            sender.pack(anchor="w")

        text = tk.Label(
            bubble,
            text=content,
            font=("Helvetica", 12),
            bg=bubble["bg"],
            fg="black",
            wraplength=350,
            justify=tk.LEFT
        )
        text.pack(anchor="w")

        time_label = tk.Label(
            bubble,
            text=time_str,
            font=("Helvetica", 8),
            bg=bubble["bg"],
            fg="#888"
        )
        time_label.pack(anchor="e")

        self.messages_canvas.update_idletasks()
        self.messages_canvas.yview_moveto(1.0)

    def send_message(self):
        """发送消息"""
        content = self.msg_entry.get().strip()
        if not content or not self.ws or not self.loop:
            return

        msg = {
            "type": "message",
            "content": content,
            "target": self.selected_user
        }

        # 在 websocket 线程中发送
        asyncio.run_coroutine_threadsafe(
            self.ws.send(json.dumps(msg)),
            self.loop
        )

        self.msg_entry.delete(0, tk.END)

if __name__ == "__main__":
    root = tk.Tk()
    app = ChatClient(root)
    root.mainloop()
