#!/usr/bin/env python3
import os
import sys
import re
import subprocess
import tempfile
from urllib.parse import urlparse

from PyQt5.QtGui import QPixmap, QIcon
from PyQt5.QtCore import Qt
from PyQt5.QtWidgets import (
    QApplication,
    QWizard,
    QWizardPage,
    QLabel,
    QLineEdit,
    QVBoxLayout,
    QComboBox,
    QMessageBox,
    QFormLayout,
    QHBoxLayout,
    QListWidget,
    QPushButton,
)

CONFIG_FILE = "/usr/share/kdg-kiosk/kiosk-config.sh"
WHITELIST_FILE = "/etc/squid/whitelist.acl/whitelist.acl"
LOGO_PATH = "/usr/share/pixmaps/kiosk.png"
DISALLOWED_KEYS = [
    Qt.Key_Escape,
    Qt.Key_Tab,
    Qt.Key_Super_L,
    Qt.Key_Super_R,
    Qt.Key_Control,
]


# ---------- Config Loader ----------
def load_existing_config():
    config = {}
    if os.path.exists(CONFIG_FILE):
        try:
            with open(CONFIG_FILE, "r") as f:
                content = f.read()
            for line in content.splitlines():
                m = re.match(r'export\s+(\w+)="?(.*?)"?$', line)
                if m:
                    key, value = m.groups()
                    config[key] = value
        except Exception as e:
            print(f"Warning: could not parse config: {e}")
    return config


# ---------- Whitelist Helpers ----------
def load_whitelist():
    if os.path.exists(WHITELIST_FILE):
        with open(WHITELIST_FILE, "r") as f:
            return [line.strip() for line in f if line.strip()]
    return []


def save_whitelist_tmp(domains):
    tmp_file = tempfile.mktemp()
    with open(tmp_file, "w") as f:
        f.write("\n".join(domains) + "\n")
    return tmp_file


# ---------- Header ----------
def create_header(title_text):
    layout = QHBoxLayout()
    title = QLabel(f"<h2>{title_text}</h2>")
    title.setAlignment(Qt.AlignVCenter | Qt.AlignLeft)
    logo = QLabel()
    if os.path.exists(LOGO_PATH):
        pixmap = QPixmap(LOGO_PATH)
        logo.setPixmap(pixmap.scaledToHeight(60, Qt.SmoothTransformation))
    layout.addWidget(logo)
    layout.addWidget(title)
    layout.addStretch(1)
    return layout


# ---------- Wizard Pages ----------
class WelcomePage(QWizardPage):
    def __init__(self):
        super().__init__()
        self.setTitle("Welcome")
        layout = QVBoxLayout()
        layout.addLayout(create_header("Welcome to the KdG Kiosk Setup Wizard"))
        layout.addSpacing(10)
        layout.addWidget(
            QLabel(
                "This wizard will guide you through the configuration of the KdG Kiosk environment.\n\n"
                "Existing settings will be loaded automatically if available.\n"
                "Click 'Next' to continue."
            )
        )
        self.setLayout(layout)


class BrowserPage(QWizardPage):
    def __init__(self, config):
        super().__init__()
        self.setTitle("Browser Configuration")
        layout = QVBoxLayout()
        layout.addLayout(create_header("Browser Configuration"))
        form = QFormLayout()
        self.browser = QComboBox()
        self.browser.addItems(["firefox", "chromium", "other"])
        self.url = QLineEdit(config.get("URL", "https://www.kdg.be"))
        if "BROWSER" in config:
            idx = self.browser.findText(config["BROWSER"])
            if idx != -1:
                self.browser.setCurrentIndex(idx)
        form.addRow("Browser:", self.browser)
        form.addRow("Homepage URL:", self.url)
        layout.addLayout(form)
        layout.addStretch(1)
        self.setLayout(layout)

    def validatePage(self):
        url = self.url.text().strip()
        if not url.startswith("http"):
            QMessageBox.warning(self, "Invalid URL", "Please enter a valid URL.")
            return False
        return True


class ProxyPage(QWizardPage):
    def __init__(self, config):
        super().__init__()
        self.setTitle("Proxy Settings")
        layout = QVBoxLayout()
        layout.addLayout(create_header("Proxy Settings"))
        form = QFormLayout()
        self.proxy_ip = QLineEdit(config.get("PROXY_IP", "127.0.0.1"))
        self.proxy_port = QLineEdit(config.get("PROXY_PORT", "3128"))
        form.addRow("Proxy IP:", self.proxy_ip)
        form.addRow("Proxy Port:", self.proxy_port)
        layout.addLayout(form)
        layout.addStretch(1)
        self.setLayout(layout)


class KeyboardPage(QWizardPage):
    def __init__(self, config):
        super().__init__()
        self.setTitle("Keyboard Configuration")
        layout = QVBoxLayout()
        layout.addLayout(create_header("Keyboard Settings"))
        form = QFormLayout()
        self.language = QComboBox()
        self.language.addItems(["be", "us", "fr", "nl"])
        lang = config.get("KEYMAP_LANG", "be")
        idx = self.language.findText(lang)
        if idx != -1:
            self.language.setCurrentIndex(idx)
        form.addRow("Keyboard layout when exiting kiosk mode:", self.language)
        layout.addLayout(form)
        layout.addStretch(1)
        self.setLayout(layout)


class KeybindPage(QWizardPage):
    def __init__(self, config):
        super().__init__()
        self.setTitle("Custom Keybind")
        self.key_sequence = config.get("CUSTOM_KEYBIND", "Alt+5")
        layout = QVBoxLayout()
        layout.addLayout(create_header("Custom Keybind"))
        self.key_input = QLineEdit(self.key_sequence)
        self.key_input.setPlaceholderText(
            "Press your desired key combination (Avoid Windows, Esc, Ctrl, Tab keys)..."
        )
        self.key_input.setReadOnly(True)
        help_label = QLabel(
            "Note: Windows/Super, Escape, Ctrl and Tab keys are not allowed for security reasons."
        )
        help_label.setStyleSheet("color: #666; font-size: 11px; font-style: italic;")
        layout.addWidget(self.key_input)
        layout.addWidget(help_label)
        layout.addStretch(1)
        self.setLayout(layout)
        self.key_input.installEventFilter(self)

    def eventFilter(self, obj, event):
        if obj == self.key_input and event.type() == event.KeyPress:
            key = event.key()
            if key in DISALLOWED_KEYS:
                key_names = {
                    Qt.Key_Escape: "Escape",
                    Qt.Key_Tab: "Tab",
                    Qt.Key_Super_L: "Windows/Super (Left)",
                    Qt.Key_Super_R: "Windows/Super (Right)",
                    Qt.Key_Control: "Ctrl",
                }
                key_name = key_names.get(key, "Unknown")
                QMessageBox.warning(
                    self,
                    "Invalid Key",
                    f"The {key_name} key is not allowed for security reasons.\n\nPlease choose a different key combination.",
                )
                self.key_input.clear()
                return True
            mods = []
            if event.modifiers() & Qt.ShiftModifier:
                mods.append("Shift")
            if event.modifiers() & Qt.ControlModifier:
                mods.append("Ctrl")
            if event.modifiers() & Qt.AltModifier:
                mods.append("Alt")
            key_name = event.text().upper() if event.text() else f"Key{key}"
            mods.append(key_name)
            self.key_sequence = "+".join(mods)
            self.key_input.setText(self.key_sequence)
            return True
        return super().eventFilter(obj, event)


class WhitelistPage(QWizardPage):
    def __init__(self):
        super().__init__()
        self.setTitle("Whitelist Configuration")
        layout = QVBoxLayout()
        layout.addLayout(create_header("Whitelist Domains"))
        self.list_widget = QListWidget()
        self.list_widget.addItems(load_whitelist())
        add_layout = QHBoxLayout()
        self.add_input = QLineEdit()
        self.add_input.setPlaceholderText("Add domain (e.g. .kdg.be)")
        self.add_button = QPushButton("Add")
        self.remove_button = QPushButton("Remove Selected")
        add_layout.addWidget(self.add_input)
        add_layout.addWidget(self.add_button)
        layout.addWidget(self.list_widget)
        layout.addLayout(add_layout)
        layout.addWidget(self.remove_button)
        layout.addStretch(1)
        self.setLayout(layout)
        self.add_button.clicked.connect(self.add_domain)
        self.remove_button.clicked.connect(self.remove_selected)

    def add_domain(self):
        domain = self.add_input.text().strip()
        existing = [
            self.list_widget.item(i).text() for i in range(self.list_widget.count())
        ]
        if domain and domain not in existing:
            self.list_widget.addItem(domain)
            self.add_input.clear()

    def remove_selected(self):
        for item in self.list_widget.selectedItems():
            self.list_widget.takeItem(self.list_widget.row(item))

    def get_domains(self):
        return [
            self.list_widget.item(i).text() for i in range(self.list_widget.count())
        ]


class SummaryPage(QWizardPage):
    def __init__(self, wizard):
        super().__init__()
        self.wizard_ref = wizard
        self.setTitle("Summary & Finish")
        layout = QVBoxLayout()
        layout.addLayout(create_header("Summary & Finish"))
        layout.addWidget(QLabel("Please review your configuration before finishing:"))
        self.label = QLabel()
        self.label.setTextFormat(Qt.RichText)
        self.label.setWordWrap(True)
        layout.addWidget(self.label)
        layout.addStretch(1)
        self.setLayout(layout)

    def initializePage(self):
        w = self.wizard_ref

        whitelist_domains = [
            w.whitelist_page.list_widget.item(i).text()
            for i in range(w.whitelist_page.list_widget.count())
        ]
        if whitelist_domains:
            whitelist_html = (
                "<ul>" + "".join(f"<li>{d}</li>" for d in whitelist_domains) + "</ul>"
            )
        else:
            whitelist_html = "<i>(none)</i>"

        summary = (
            f"<b>Browser:</b> {w.browser_page.browser.currentText()}<br>"
            f"<b>Homepage:</b> {w.browser_page.url.text()}<br>"
            f"<b>Proxy:</b> {w.proxy_page.proxy_ip.text()}:{w.proxy_page.proxy_port.text()}<br>"
            f"<b>Keyboard Layout:</b> {w.keyboard_page.language.currentText()}<br>"
            f"<b>Custom Keybind:</b> {w.keybind_page.key_sequence}<br>"
            f"<b>Whitelisted Domains:</b>{whitelist_html}"
        )

        self.label.setText(summary)

    def validatePage(self):
        self.wizard_ref.save_config()
        return True


# ---------- Main Wizard ----------
class KioskWizard(QWizard):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("KdG Kiosk Setup Wizard")
        self.resize(600, 400)
        if os.path.exists(LOGO_PATH):
            self.setWindowIcon(QIcon(LOGO_PATH))

        config = load_existing_config()
        self.welcome_page = WelcomePage()
        self.browser_page = BrowserPage(config)
        self.proxy_page = ProxyPage(config)
        self.keyboard_page = KeyboardPage(config)
        self.keybind_page = KeybindPage(config)
        self.whitelist_page = WhitelistPage()
        self.summary_page = SummaryPage(self)

        self.addPage(self.welcome_page)
        self.addPage(self.browser_page)
        self.addPage(self.proxy_page)
        self.addPage(self.keyboard_page)
        self.addPage(self.keybind_page)
        self.addPage(self.whitelist_page)
        self.addPage(self.summary_page)

    def save_config(self):
        browser = self.browser_page.browser.currentText()
        url = self.browser_page.url.text().strip()
        proxy_ip = self.proxy_page.proxy_ip.text().strip()
        proxy_port = self.proxy_page.proxy_port.text().strip()
        lang = self.keyboard_page.language.currentText()
        custom_keybind = self.keybind_page.key_sequence
        proxy_url = f"http://{proxy_ip}:{proxy_port}" if proxy_ip else ""

        # Add homepage domain automatically if not present
        domains = self.whitelist_page.get_domains()
        parsed = urlparse(url)
        if parsed.hostname and parsed.hostname not in domains:
            domains.append(parsed.hostname)

        whitelist_tmp = save_whitelist_tmp(domains)
        config_tmp = tempfile.mktemp(suffix=".sh")
        content = f"""#!/bin/bash
# ==========================
# KIOSK CONFIGURATION
# ==========================

export BROWSER="{browser}"
export URL="{url}"

export PROXY_IP="{proxy_ip}"
export PROXY_PORT="{proxy_port}"
export PROXY_URL="{proxy_url}"

export SQUID_TEMPLATE="/etc/squid/conf.d/squid.conf.template"
export SQUID_CONFIG="/etc/squid/squid.conf"

export LOGFILE="/tmp/kiosk.log"
export PIDFILE="/tmp/kiosk-main.pid"

export DEFAULT_KEYMAP_FILE="$HOME/.xmodmap-default"
export XBINDKEYS_CONFIG="$HOME/.xbindkeysrc_kiosk"
export KEYMAP_LANG="{lang}"

export BLOCKED_PAGE_URL="http://{proxy_ip}/blocked.html"
export DENIED_PAGE_URL="http://{proxy_ip}/denied.html"

export CUSTOM_KEYBIND="{custom_keybind}"
"""
        try:
            with open(config_tmp, "w") as f:
                f.write(content)

            subprocess.run(
                [
                    "pkexec",
                    "bash",
                    "-c",
                    f"mv {config_tmp} {CONFIG_FILE} && chmod 644 {CONFIG_FILE} "
                    f"&& mv {whitelist_tmp} {WHITELIST_FILE} && chmod 644 {WHITELIST_FILE}",
                ],
                check=True,
            )

            QMessageBox.information(
                self, "Success", "Configuration saved successfully!"
            )

            reply = QMessageBox.question(
                self,
                "Start Kiosk",
                "Would you like to start the kiosk now?",
                QMessageBox.Yes | QMessageBox.No,
            )
            if reply == QMessageBox.Yes:
                env = os.environ.copy()
                subprocess.Popen(
                    ["/usr/bin/kdg-kiosk"],
                    env=env,
                    start_new_session=True,
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                )
                self.close()
                sys.exit(0)
        except Exception as e:
            QMessageBox.critical(self, "Error", f"Could not save configuration:\n{e}")


# ---------- Run ----------
if __name__ == "__main__":
    app = QApplication(sys.argv)
    wizard = KioskWizard()
    wizard.show()
    sys.exit(app.exec_())
