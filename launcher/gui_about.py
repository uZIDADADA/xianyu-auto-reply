"""桌面启动器系统信息页面。"""
import tkinter as tk
from launcher.gui_theme import COLORS
from launcher.version import CURRENT_VERSION


def render_about_page(app):
    frame = tk.Frame(app._content_frame, bg=COLORS["card_bg"])
    frame.pack(fill=tk.BOTH, expand=True)
    for text in ("闲鱼自动回复管理系统", f"当前版本: v{CURRENT_VERSION}"):
        tk.Label(frame, text=text, font=("微软雅黑", 12),
                 fg=COLORS["text"], bg=COLORS["card_bg"]).pack(anchor=tk.W, padx=20, pady=12)
