"""桌面启动器本地仪表盘。"""
import tkinter as tk
import webbrowser
from launcher.gui_theme import COLORS


def render_dashboard_page(app):
    frame = tk.Frame(app._content_frame, bg=COLORS["card_bg"])
    frame.pack(fill=tk.BOTH, expand=True)
    tk.Label(frame, text="仪表盘", font=("微软雅黑", 14, "bold"),
             fg=COLORS["text"], bg=COLORS["card_bg"]).pack(anchor=tk.W, padx=20, pady=16)
    tk.Label(frame, text="在本地管理后台查看账号、消息和订单统计。",
             fg=COLORS["text_secondary"], bg=COLORS["card_bg"]).pack(anchor=tk.W, padx=20)
    tk.Button(frame, text="打开本地管理后台", command=lambda: webbrowser.open("http://localhost:9000")).pack(anchor=tk.W, padx=20, pady=16)
