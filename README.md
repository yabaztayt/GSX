# 🎮 GSX (Guide + Start XInput task killing app)

Ultra lightweight AutoHotkey v2 script that runs in the background and sends **WinClose + WinKill** when you press **Guide** (Xbox/Home) **+ Start** at the same time on any XInput-compatible controller. ⚡

The main focus of the app is to be used in an HTPC setup from the couch for closing games that for some reason don't have an option to exit to desktop, but it can pretty much kill any program that is in focus.

On top of that, it also includes an optional **full mouse + keyboard mode** (toggled with **Guide + Back**) so you can control your whole PC from the couch without ever picking up a mouse or keyboard — including a built-in on-screen keyboard.

## ✨ Features

- 🎮 Detects the combo **on any XInput controller** (Xbox 360, One, Series, and most third-party/clone pads), no per-device button mapping needed.
- 👻 Runs 100% in the background, with a system tray icon and no visible windows.
- 🪶 Very low CPU usage: optimized 100ms polling, with a cache of which controller slots are connected to skip unnecessary calls (0% usage in my Ryzen 5600x and only 4mb of RAM usage).
- 🖱️ **Full mouse & keyboard mode** — move the cursor, click, scroll, control media/volume, and even type using a built-in on-screen keyboard, all from the controller.
- 🟢 **On-screen "Mouse Mode ON/OFF" indicator** — a big, centered, auto-fading message every time you toggle Mouse Mode, so you always know its state at a glance from the couch. Doesn't depend on Windows notifications (which are unreliable for unsigned scripts/exes) since it's drawn by GSX itself.
- ⌨️ **Custom on-screen keyboard** — draggable, positions itself above your cursor so it doesn't cover the field you're typing into, with letter/symbol layouts, a caps-lock-style shift key, visual press feedback on every key, and no dependency on Windows' own on-screen keyboard (which can be broken by debloat tools or blocked by UAC elevation on some setups).
- 🔄 **Auto-updates** — checks your GitHub releases in the background on startup (silently, no popups unless there's actually something new) and lets you check manually from the tray menu at any time.
- 🖱️ Tray menu icon (left or right click).
- ⚠️ Shows a requirements notice the first time it runs.

## 🧠 How it works

XInput doesn't expose the Guide button through its public API (`XInputGetState`) — Windows reserves it for its own UI. This script uses `XInputGetStateEx`, an undocumented but rock-solid function that's been stable for over a decade (also used by tools like x360ce and DS4Windows), which does include the Guide button bit in the button state bitmask.

On every timer tick, it queries the state of the 4 possible controller slots (0-3) via `DllCall` into `xinput1_4.dll`, and if the button bitmask matches `START | GUIDE`, it sends `WinClose + WinKill` with `Send()`.

Polling speeds up automatically (from 100ms to 16ms) whenever Mouse Mode is active, so cursor movement feels smooth, and slows back down when it's off to keep CPU usage minimal.

## 📋 Requirements

- 🤖 **[AutoHotkey v2](https://www.autohotkey.com/)** — only needed if you're running the `.ahk` script directly. If you use the compiled `.exe` from the Releases page, the AutoHotkey runtime is bundled in and you don't need to install anything else.
- 🪟 Windows 8 or later (uses `xinput1_4.dll`, included by default on the system).

Note: *[SuperF4](https://github.com/stefansundin/superf4) installed and running — only needed if you're using the older 0.1 release.*

## 📦 Installation

### Option A: Compiled executable
1. Download the `.exe` from [Releases](../../releases) (or compile it yourself, see below).
2. Run the executable. A tray icon with a cute calm dog will appear. 🎮
3. *(Optional)* Add it to the Windows startup folder by right clicking the tray icon and selecting "Run at startup". 🚀

### Option B: From source
1. Install [AutoHotkey v2](https://www.autohotkey.com/).
2. Download `gsx.ahk` from this repo.
3. Run the script by double-clicking it, or compile it yourself with Ahk2Exe (right-click the `.ahk` → *Compile Script*).

## ▶️ Usage

1. Run this script (or its `.exe`). 🎮
2. With the window you want to close in the foreground, press **Guide + Start** on your controller. 💥
3. Press **Guide + Back** to toggle Mouse Mode on/off and take full control of your PC from the couch (see the table below).

## 🖱️ Mouse Mode

Toggle with **Guide + Back**. While active, every button on the controller does something useful — nothing is left unmapped:

| Button | Action | Notes |
|---|---|---|
| **Guide + Back** | Toggle Mouse Mode on/off | Works at any time, from anywhere |
| **Guide + Start** | Close/kill active window | Still works even while Mouse Mode is on, as a safety net |
| Left Stick | Move cursor | Linear response by default, adjustable deadzone and speed |
| Right Stick (up/down) | Volume up/down | Repeats while tilted |
| Right Stick (left/right) | Previous/Next media track | One shot per tilt (must re-center before it fires again) |
| RT (trigger) | Left click | Analog trigger, held while past the threshold |
| LT (trigger) | Right click | Analog trigger, held while past the threshold |
| RB | Scroll up | One step per press |
| LB | Scroll down | One step per press |
| A | Enter | Held down while the button is held |
| B | Escape | Held down while the button is held |
| X | Middle click | Held down while the button is held |
| Y | Show/hide on-screen keyboard | Custom built-in keyboard, see below |
| D-Pad | Arrow keys | Held down, supports OS key-repeat |
| L3 (left stick click) | Alt+Tab | One tap = one switch |
| R3 (right stick click) | Play/Pause media | One tap |
| Start (alone, no Guide) | Windows key | Opens the Start Menu |
| Back (alone, no Guide) | Tab | Handy for cycling through UI fields |

Turning Mouse Mode off automatically releases any keys/clicks that might still be held down, so nothing gets "stuck."

Every time you toggle it (either way), a big centered message flashes on screen for a couple of seconds and fades out on its own — green **"Mouse Mode ON"** when you turn it on, red **"Mouse Mode OFF"** when you turn it off — so it's obvious at a glance from across the room whether the controller is currently driving the mouse or not.

### ⌨️ On-screen keyboard

Press **Y** while in Mouse Mode to show/hide a custom on-screen keyboard — built entirely in-house, with no dependency on Windows' `osk.exe` or the touch keyboard (`TabTip.exe`), both of which can be unreliable (elevation issues, or missing services after debloating Windows).

- Move the cursor with the left stick and click keys with **RT**, just like any other on-screen button. Every key lights up while pressed, so you always get clear visual feedback.
- Every time you open it, it appears centered above wherever your cursor currently is (falling back to below the cursor if there's no room above), so it stays out of the way of the text field you're about to use. You can still drag it anywhere by its top bar while it's open.
- **⇧ Shift** is a toggle (like caps-lock) — tap it to switch to uppercase, tap it again to go back; the letter keys themselves flip case so you can see which mode you're in.
- **⌫ Backspace** repeats automatically if you keep it held down, instead of needing to press it repeatedly.
- **?123 / ABC** switches between the letter layout and a symbols/punctuation layout (`< >`, `@#$%`, brackets, quotes, etc.).
- **✕** closes the keyboard from its own title bar.

## 🗂️ Tray menu

- ℹ️ **About** — project credits and instructions.
- 🔄 **Check for updates** — manually asks GitHub for the latest release right away. If you're already on the latest version it'll tell you so; if there's an update, it offers to open the download page for you.
- ☕ **Donations** — link to [Patreon](https://www.patreon.com/cw/Yabazta).
- 🚀 **Run at startup** — self-explanatory.
- ❌ **Exit** — closes the script.

Both left and right click on the tray icon open this menu.

On top of the manual check, GSX also checks for updates silently a few seconds after it starts — if there's nothing new, it says nothing at all; if there's a newer release, it shows the same "update available" prompt as the manual check.

## ⚠️ Known limitations

- 🗝️ Your antivirus may block this application, but you can always take a look at the source code if you have any suspicions.
- 🎮 If your controller isn't fully compatible with Windows' XInput driver (e.g. some DirectInput-only pads), the Guide button might not be detected.
- 🔒 GSX runs unelevated by design (safer, and less likely to get flagged by anti-cheat). This means it can't send clicks/keys to windows that are running as Administrator — you'd need to run GSX elevated too for that, which isn't recommended for online games with kernel-level anti-cheat.
- ❌ You'll probably get warned by some anti-cheats about this app because it uses AutoHotkey, **USE IT AT YOUR OWN RISK, BE CAREFUL**.

## 🔧 Configuration

Everything adjustable lives at the top of the `.ahk` file:

| Variable | What it does |
|---|---|
| `APP_VERSION` | Current version number, shown in *About* and compared against the latest GitHub release to detect updates. Bump this on every release you publish. |
| `GITHUB_REPO` | `"user/repo"` used by the auto-updater to query `api.github.com`. If you fork this project, change it to your own repo or the update checks will point at the wrong place. |
| `XI_START` / `XI_GUIDE` / `XI_BACK` | Bits of the combos to detect. Can be swapped for other buttons in the XInput bitmask. |
| `ScanIntervalMs` | How often it checks for newly connected/disconnected controllers (default 3000ms). |
| `POLL_INTERVAL_IDLE_MS` | Combo polling frequency while Mouse Mode is off (default 100ms). |
| `POLL_INTERVAL_MOUSE_MS` | Polling frequency while Mouse Mode is on, for smooth cursor movement (default 16ms). |
| `MOUSE_INDICATOR_DURATION_MS` | How long the on-screen "Mouse Mode ON/OFF" message stays visible before fading out (default 2500ms). |
| `FORCE_KILL_GRACE_SEC` | How long to wait after the polite close attempt before force-killing an unresponsive window (default 2.0 seconds). |
| `LEFT_STICK_DEADZONE` / `RIGHT_STICK_DEADZONE` | Stick deadzones (standard XInput defaults). |
| `CURSOR_MAX_SPEED` | Max cursor speed in pixels per tick at full stick deflection (default 32). |
| `CURSOR_CURVE_EXPONENT` | Stick response curve. `1.0` = linear/predictable (default). `>1.0` softens slow/medium movements but keeps the same top speed. `<1.0` makes the cursor more sensitive near the center. |
| `TRIGGER_THRESHOLD` | How far RT/LT need to be pulled (0-255) to register as a click (default 100). |
| `VOLUME_REPEAT_MS` | How often volume repeats while the right stick is tilted vertically (default 120ms). |
| `MEDIA_TRACK_DEADZONE` | How far the right stick needs to tilt horizontally to trigger next/previous track (default 20000, higher than the normal deadzone to avoid accidental skips). |

## 💛 Credits

Made by **Yabazta** with Claude AI. 🤖✨

If you want, you can support me at [Patreon](https://www.patreon.com/cw/Yabazta).

VirusTotal: [Scan](https://www.virustotal.com/gui/file/ad9361158485a797db9cdcefe33f62c4085649fd98153127312ab774633ffc9a).
