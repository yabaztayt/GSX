# 🎮 GuideStartXInput

Lightweight AutoHotkey v2 script that runs in the background and sends **Ctrl+Alt+F4** when you press **Guide** (Xbox/Home) **+ Start** at the same time on any XInput-compatible controller. ⚡

Meant to be used alongside [SuperF4](https://github.com/stefansundin/superf4) 🔪, which is what actually force-closes the foreground window when it receives that key combo. This script only simulates the keypress from the controller — it doesn't kill any process itself.

## ✨ Features

- 🎮 Detects the combo **on any XInput controller** (Xbox 360, One, Series, and most third-party/clone pads), no per-device button mapping needed.
- 👻 Runs 100% in the background, with a system tray icon and no visible windows.
- 🪶 Very low CPU usage: optimized 100ms polling, with a cache of which controller slots are connected to skip unnecessary calls.
- 🖱️ Tray menu (left or right click).
- ⚠️ Shows a requirements notice the first time it runs.

## 🧠 How it works

XInput doesn't expose the Guide button through its public API (`XInputGetState`) — Windows reserves it for its own UI. This script uses `XInputGetStateEx`, an undocumented but rock-solid function that's been stable for over a decade (also used by tools like x360ce and DS4Windows), which does include the Guide button bit in the button state bitmask.

On every timer tick, it queries the state of the 4 possible controller slots (0-3) via `DllCall` into `xinput1_4.dll`, and if the button bitmask matches `START | GUIDE`, it sends `Ctrl+Alt+F4` with `Send()`.

## 📋 Requirements

- 🔪 **[SuperF4](https://github.com/stefansundin/superf4)** installed and running — it's what actually closes/kills the process on receiving Ctrl+Alt+F4.
- 🤖 **[AutoHotkey v2](https://www.autohotkey.com/)** — only needed if you're running the `.ahk` script directly. If you use the compiled `.exe` from the Releases page, the AutoHotkey runtime is bundled in and you don't need to install anything else.
- 🪟 Windows 8 or later (uses `xinput1_4.dll`, included by default on the system).

## 📦 Installation

### Option A: Compiled executable
1. Download the `.exe` from [Releases](../../releases) (or compile it yourself, see below).
2. Run the executable. A tray icon will appear. 🎮
3. *(Optional)* Add it to the Windows startup folder by right clicking the tray icon and selecting "Run at startup". 🚀

### Option B: From source
1. Install [AutoHotkey v2](https://www.autohotkey.com/).
2. Download `guide-start-xinput.ahk` from this repo.
3. Run the script by double-clicking it, or compile it yourself with Ahk2Exe (right-click the `.ahk` → *Compile Script*).

## ▶️ Usage

1. Make sure SuperF4 is running. 🔪
2. Run this script (or its `.exe`). 🎮
3. With the window you want to close in the foreground, press **Guide + Start** on your controller. 💥

## 🗂️ Tray menu

- ℹ️ **About** — project credits.
- ☕ **Donations** — link to [Patreon](https://www.patreon.com/cw/Yabazta).
- 🚀 **Run at startup** — self-explanatory.
- ❌ **Exit** — closes the script.

Both left and right click on the tray icon open this menu.

## ⚠️ Known limitations

- 🗔 Doesn't close `explorer.exe` or some Windows Control Panel / Settings windows — this is a behavior/limitation of **SuperF4**, not this script (the script only sends the keypress; confirmed to arrive correctly even in those cases).
- 🎮 If your controller isn't fully compatible with Windows' XInput driver (e.g. some DirectInput-only pads), the Guide button might not be detected.

## 🔧 Configuration

Everything adjustable lives at the top of the `.ahk` file:

| Variable | What it does |
|---|---|
| `XINPUT_GAMEPAD_START` / `XINPUT_GAMEPAD_GUIDE` | Bits of the combo to detect. Can be swapped for other buttons in the XInput bitmask. |
| `ScanIntervalMs` | How often it checks for newly connected/disconnected controllers (default 3000ms). |
| `SetTimer` interval | Combo polling frequency (default 100ms). |

## 💛 Credits

Made by **Yabazta**. Vibecoded btw. 🤖✨
