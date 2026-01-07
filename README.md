# NicVox 🎙️

**Native macOS Voice-to-Text for the Terminal Age.**

NicVox is a lightweight, menu-bar application that transcribes your speech directly to your clipboard (or types it directly). Designed for developers, writers, and power users who want privacy-first, on-device dictation with global hotkeys.

<p align="center">
  <img src="nvx.png" width="128" alt="NicVox Icon">
</p>

## ✨ Features

*   **Global Hotkeys:**
    *   `Cmd + Opt + P`: Record in **Portuguese**.
    *   `Cmd + Opt + E`: Record in **English**.
*   **Privacy First:** Uses Apple's native on-device Speech framework. No audio is sent to the cloud.
*   **Auto-Paste:** Automatically pastes the transcribed text into your active application (VS Code, Terminal, Slack, etc.).
*   **Menu Bar App:** Lives quietly in your menu bar.
*   **Zero Dependencies:** Written in pure Swift. No Electron, no Python, just performance.

## 🚀 Installation

### The Magic Command (One-line)
Run this in your terminal to install NicVox:

```bash
curl -sL https://raw.githubusercontent.com/nicolaregattieri/NicVox/main/setup.sh | bash
```

### Manual Install
1.  Download the latest `.dmg` from the [Releases](https://github.com/nicolaregattieri/NicVox/releases) page.
2.  Drag `NicVox.app` to your Applications folder.

## 🛠️ Build from Source

Requirements: macOS 12.0+ and Xcode Command Line Tools.

```bash
git clone https://github.com/nicolaregattieri/NicVox.git
cd NicVox
./install.sh
```

## ⚙️ Configuration
Click the **NVX** icon in the menu bar and select **Preferences** to:
*   Change Hotkeys.
*   Enable/Disable Auto-Paste.
*   Customize Start/Stop sounds.

## 📝 License
MIT License. Feel free to fork and modify!
