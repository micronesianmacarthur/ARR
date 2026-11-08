# Omarchy Quattro–style UI — Intent & Build Plan

- **Host:** `ui-test` (Ubuntu 26.04.1 LTS, VM)
- **Prepared:** 2026-11-07
- **Status:** Intent for approval. No system changes have been made.
- **Scope decision:** Build a **custom Omarchy Quattro–style desktop UI** on the existing Ubuntu + Hyprland + stock Quickshell stack.
- **Application scope:** **UI only.** No application pack (Nautilus, btop, LibreOffice, Obsidian, etc.) is installed as part of this intent.
- **Elevation:** All privileged and network/audio/Bluetooth changes are documented in §6 as **intent only**. They will not be executed without explicit approval and a working sudo path.

---

## 1. Why this approach

Omarchy Quattro is an Arch-based distribution. Its v4 desktop shell targets:

- a patched Quickshell with an Omarchy plugin loader, and
- a Lua-enabled Hyprland 0.56-era build (`hyprland.lua`, `hl.*`, `o.bind`).

This machine has:

| Component | Present |
|---|---|
| OS | Ubuntu 26.04.1 (resolute) |
| Compositor | Hyprland 0.53.3 (Ubuntu package, hyprlang config) |
| Shell toolkit | Quickshell 0.3.2 (stock, from `ppa:avengemedia/danklinux`) |
| Login | SDDM 0.21 |
| Existing UI | Minimal Quickshell bar + wallpaper, basic Hyprland config |
| Terminal | kitty 0.45 |
| Browser | Chromium (snap) |

Installing Omarchy itself would mean replacing Ubuntu. Porting the real Quattro QML is possible in principle but depends on the patched Quickshell/Hyprland APIs above and Omarchy's Arch-specific CLI (`pacman`, `uwsm`, `limine`, etc.). That path is high-risk and not chosen.

**Decision:** reproduce the *experience* — layout, theme system, keybindings, workflows, visual language — with a self-contained Quickshell shell written for Quickshell 0.3.2 and Hyprland 0.53.

---

## 2. Current environment constraints

- 1280×800 display, 4 vCPU, 5.3 GiB RAM, ~20 GiB free disk.
- Virtio GPU → expect software rendering. Heavy blur/shadows/animations are avoided (this also matches Omarchy's software-rendering defaults).
- No Nerd Fonts, Yaru/Papirus icon themes, or cursor theme installed.
- No NetworkManager, PipeWire/WirePlumber, or BlueZ.
- No clipboard tools (`wl-clipboard`, `cliphist`), screenshot tools (`grim`, `slurp`), `wtype`, `hyprpicker`, `playerctl`, `brightnessctl`, `pamixer`, or notification CLI.
- `upower` is installed; `hyprlock`, `hypridle`, `hyprpaper`, `hyprpolkitagent`, `xdg-desktop-portal-hyprland` are installed.
- `sudo` requires an interactive password; the agent cannot elevate non-interactively.
- Existing configs to preserve: `~/.config/hypr/hyprland.conf`, `~/.config/quickshell/shell.qml`, `~/.config/kitty/kitty.conf`, `~/.bashrc`.

---

## 3. Definition of done (UI)

A normal login (SDDM → Hyprland) presents an Omarchy Quattro–like desktop that survives logout/reboot:

1. **Top bar** — 26 px, Tokyo Night colors, left: Omarchy logo/menu + workspace indicators; center: status indicators + `dddd HH:mm` clock; right: system tray + keyboard/network/audio/battery/power widgets.
2. **Menu / launcher** — `Super+Space` opens a searchable overlay covering installed `.desktop` apps and UI actions (theme, wallpaper, system, capture, settings). Fuzzy search, keyboard-first navigation, `Esc` closes.
3. **Panels** — audio, network, Bluetooth, power, calendar, notifications, theme. Each opens from the bar or a hotkey and degrades gracefully when the underlying daemon/tool is absent.
4. **Notifications** — Quickshell notification server, Omarchy-style toasts, history, DND toggle, keyboard dismissal.
5. **OSD** — volume/brightness overlay when corresponding tools exist; otherwise the binding reports a missing dependency without breaking the shell.
6. **Wallpaper** — rendered by Quickshell as a background layer, per theme, with fade and `Super+Ctrl+W` cycling. No dependency on `hyprpaper` (its GBM allocation fails on this virtio GPU).
7. **Theme engine** — `omarchy-theme set <name>` live-switches Tokyo Night, Catppuccin, Gruvbox, Nord, Everforest, Rosé Pine, Kanagawa, Matte Black, Vantablack across Hyprland, kitty, btop, GTK and the shell. `Super+Ctrl+T` opens the picker.
8. **Hyprland** — Omarchy layout and keybindings: gaps 5/10, 2 px accent-gradient border, square corners, no blur/shadow; dwindle with `force_split=2`; 10 workspaces per monitor; scratchpad; quake console; grouping; sensible window rules.
9. **Lock / idle** — themed `hyprlock`, `hypridle` with 150 s screensaver and 300 s lock, fail-safe unlock.
10. **Persistence & safety** — timestamped backups of every replaced config; `hyprctl configerrors` clean; shell log free of QML errors; documented rollback.
11. **Documentation** — this intent plus a concise `~/.config/omarchy/README.md` with hotkeys, theme commands and dependency status.

**Non-goals:** Arch packages/updates, Omarchy's exact plugin host, Limine/Plymouth boot, Snapper, `omacalc`/`omawrite`/`herdr`, AI agent integration, app installs, unified clipboard interception that requires `wtype` until the system intent is approved.

---

## 4. Visual specification (Tokyo Night default)

Source: Omarchy `themes/tokyo-night/colors.toml` and `default/themed/shell.toml.tpl`.

| Token | Value |
|---|---|
| background | `#1a1b26` |
| dark/darker/lighter bg | `#13141c` / `#0e0e14` / `#24283b` |
| foreground | `#a9b1d6` |
| bright foreground | `#c0caf5` |
| accent | `#7aa2f7` |
| selection | `#292e42` |
| muted | `#414868` |
| red / green / yellow | `#f7768e` / `#9ece6a` / `#e0af68` |
| blue / magenta / cyan | `#7aa2f7` / `#ad8ee6` / `#449dab` |
| mode | dark |

Layout rules:

- Bar height 26 px; opaque `background`; 12 px JetBrainsMono Nerd Font; 14 px icons.
- Hyprland: `gaps_in=5`, `gaps_out=10`, `border_size=2`, `rounding=0`, no blur, no shadow. Active border = accent gradient at 45°; inactive `rgba(595959aa)`.
- Launcher: centered card ~640×440, 50 % scrim, 95 % opaque card, 2 px accent/foreground gradient border, selected row 8 % foreground + accent text.
- Panels: 320–360 px wide, 18 px padding, 2 px gradient border, opaque background.
- Notifications: top-right, ~380 px, accent border/countdown.
- OSD: bottom-center, slim card, auto-hide 1.2 s.
- Lock: background wallpaper with blur, large clock, minimal password card with accent border.

All colors are generated from the active theme's `colors.toml`; nothing is hard-coded in components beyond fallbacks.

---

## 5. User-level implementation (no sudo)

Everything in this section can be done as user `mac` in the home directory.

### 5.1 File layout

```text
~/.local/share/omarchy/
  themes/<theme>/colors.toml, backgrounds/, icons.theme
  templates/{kitty.conf,shell.toml,btop.theme,hyprland.conf,gtk.css}
  README.md
~/.local/state/omarchy/
  current/theme/{colors.toml,kitty.conf,shell.toml,btop.theme,hyprland.conf,gtk.css}
  current/background
~/.local/bin/
  omarchy-theme            # set/list/current/next-bg
  omarchy-apps             # .desktop scanner → JSON
  omarchy-notify           # optional internal notify helper
  omarchy-screenshot       # guarded: reports if grim/slurp missing
~/.config/omarchy/
  shell.json               # bar layout / idle timings
  theme -> ~/.local/state/omarchy/current/theme
  README.md
~/.config/hypr/
  hyprland.conf            # sources conf.d/*
  conf.d/{env,looknfeel,input,bindings,windowrules,autostart}.conf
  hyprlock.conf
  hypridle.conf
  theme.conf               # generated active-border colors
~/.config/quickshell/
  shell.qml                # ShellRoot
  Theme.qml / Config.qml
  components/ (Bar, Menu, Panel, Toast, Osd, Background, Widgets)
  panels/ (Audio, Network, Bluetooth, Power, Calendar, Notifications, Theme)
  services/ (Apps, Audio, Network, Battery, Mpris)
~/.config/kitty/kitty.conf # include generated theme
~/.config/gtk-3.0/gtk.css  # accent overrides for Adwaita-dark
~/.local/share/fonts/      # JetBrainsMono Nerd Font
~/.local/share/icons/      # downloaded icon/cursor themes if needed
~/.config/omarchy/backups/ # timestamped backups of replaced configs
```

### 5.2 Phases

**Phase 0 — Safety**
- Timestamp backups of `~/.config/hypr`, `~/.config/quickshell`, `~/.config/kitty`, `~/.bashrc`.
- Keep the current working Quickshell config runnable until the replacement is validated from a temporary path (`qs -p`).

**Phase 1 — Assets**
- Download JetBrainsMono Nerd Font TTFs (Regular/Medium/Bold/Italic) into `~/.local/share/fonts`; run `fc-cache -f`.
- Download Omarchy Tokyo Night wallpapers (`2-quattro.webp`, `0-liftoff.webp`, `4-sunset-lake.webp`, etc.) and one background per extra theme.
- Download 8 theme `colors.toml` files and `icons.theme` files.
- Optional user-level icon/cursor themes: Papirus-Dark and Bibata-Modern-Ice into `~/.local/share/icons`; otherwise keep Adwaita until §6.

**Phase 2 — Theme engine**
- `omarchy-theme` reads `colors.toml`, derives missing tokens (`selection_foreground`, ghost colors), renders templates, writes `~/.local/state/omarchy/current/theme/*`.
- Updates: kitty include, Hyprland active/inactive borders via generated `theme.conf` + `hyprctl reload`, GTK CSS, btop theme, shell palette (`shell.toml`/`colors.toml` watched by Quickshell).
- Wallpaper: set `current/background`, notify Quickshell via IPC to crossfade; `next-bg` cycles the active theme's backgrounds.
- Commands: `omarchy-theme list|current|set <name>|next|next-bg`.

**Phase 3 — Hyprland**
- Split config into `hyprland.conf` + `conf.d/`; include generated theme colors.
- Look & feel per §4; software-rendering-safe (no blur/shadow; subtle window fade only if performance allows).
- Keybindings (translated from Omarchy `tiling.lua`, `applications.lua`, `utilities.lua`):
  - `Super+Space` menu, `Super+Escape` system menu, `Super+Tab`/`Shift+Tab` workspaces, `Super+1..0` workspace focus, `Super+Shift+1..0` move window.
  - `Super+Q`/`Super+W` close, `Super+T` float, `Super+F` fullscreen, `Super+Alt+F` full width, `Super+J` split, `Super+P` pseudo, `Super+O` pop-out, `Super+L` layout cycle, `Super+S` scratchpad, `Super+grave` quake console.
  - Arrows focus/swap, `Super+Shift+Alt+arrows` move workspace to monitor, `Super+Ctrl+arrows` move window to monitor.
  - Resize on physical `code:20/21` (minus/equal), mouse drag/resize, scroll workspaces.
  - Grouping (`Super+G`, `Super+Alt+G`, `Super+Alt+Tab`).
  - Panels: `Super+Ctrl+A/N/B/D/P`, calendar `Super+Ctrl+Alt+D`, theme `Super+Ctrl+T`, wallpaper `Super+Ctrl+W`, lock `Super+Ctrl+L`.
  - Capture/OCR/record bindings call guarded helpers; missing tools produce a notification, not a shell error.
- Window rules: float/center dialogs, file pickers, pavucontrol/blueman when later installed; terminal scroll factor; XWayland scaling.
- Autostart: `qs -n`, `hypridle`, `hyprpolkitagent`, clipboard watcher only when `wl-paste`/`cliphist` exist.

**Phase 4 — Quickshell shell**
- `ShellRoot` with per-screen `Variants`.
- `PanelWindow` bar: exclusive zone 26; click/hover popups; tray via `Quickshell.Services.SystemTray`; workspaces/active window via `Quickshell.Hyprland`; clock via `SystemClock`.
- Launcher/menu: overlay `PanelWindow` with scrim, search field, fuzzy filter, sections (Apps, Theme, Wallpaper, System, Capture). App list comes from `omarchy-apps` (parses `/usr/share/applications`, `~/.local/share/applications`).
- Panels: use `Quickshell.Services.Pipewire`, `Quickshell.Networking`, `Quickshell.Bluetooth`, `Quickshell.Services.UPower`; each checks availability and shows an explanatory empty state.
- Notifications: `NotificationServer` + `Toast.qml` + history store; DND toggle; actions.
- OSD: IPC `osd show volume|brightness <value>`; auto-hide timer.
- Background: full-screen background `PanelWindow` per screen with `Image`, crossfade animation.
- Screensaver: full-screen clock overlay via IPC for `hypridle` at 150 s; lock via `hyprlock` at 300 s.
- IPC targets: `launcher`, `menu`, `panel`, `osd`, `background`, `idle`, `notifications`, `theme`. Used by keybindings and `hypridle`.
- Logging: warnings only for genuinely missing optional deps; no repeated QML errors.

**Phase 5 — Lock/idle/polkit**
- `hyprlock.conf`: Tokyo Night colors, wallpaper, clock, user, password field, accent border; PAM auth.
- `hypridle.conf`: 150 s screensaver IPC, 300 s lock; `before_sleep_cmd = loginctl lock-session`; `after_sleep_cmd = hyprctl dispatch dpms on`; ignore when already locked.
- Keep `hyprpolkitagent` running for GUI auth prompts.

**Phase 6 — Finalize**
- Validate in a throwaway Quickshell instance first; then swap the default config and restart `qs`.
- `hyprctl reload`; confirm `hyprctl configerrors` empty.
- Write `~/.config/omarchy/README.md` (hotkeys, theme commands, dependency status, rollback).
- Report what works now vs. what waits on §6.

---

## 6. System intent (privileged; NOT executed)

These are the changes that require sudo. They are listed for approval and can be run later as one script. Nothing here is part of the initial user-level build.

### 6.1 Desktop utilities (UI dependencies)

```bash
sudo apt update
sudo apt install -y \
  grim slurp wl-clipboard cliphist wtype hyprpicker \
  libnotify-bin playerctl brightnessctl pamixer \
  tesseract-ocr wf-recorder
```

Purpose: screenshots/OCR/recording, clipboard history, keyboard injection for unified clipboard, media keys, brightness/volume OSD, notification CLI.

### 6.2 Network / audio / Bluetooth

```bash
sudo apt install -y \
  network-manager \
  pipewire pipewire-pulse wireplumber alsa-utils \
  bluez bluez-tools
```

Purpose: working network/audio/Bluetooth panels and keybindings.

**Risk & rollback:** this VM currently uses `systemd-networkd` + netplan (`/etc/netplan/00-installer-config.yaml`). Installing NetworkManager may take over `enp1s0`. Before switching:

1. Back up `/etc/netplan` and record `systemctl is-enabled systemd-networkd`.
2. Install; test `nmcli general status`, DHCP lease, DNS, and outbound HTTPS.
3. If connectivity fails: `sudo systemctl disable --now NetworkManager; sudo systemctl enable --now systemd-networkd; sudo netplan apply`, restore the backup.

PipeWire/BlueZ are additive and low risk. QEMU has an ICH9 audio device; BlueZ will report no adapter, which the UI handles.

### 6.3 Visual themes / fonts (optional, if user-level downloads are not used)

```bash
sudo apt install -y \
  yaru-theme-icon yaru-theme-gtk \
  papirus-icon-theme bibata-cursor-theme \
  fonts-jetbrains-mono
```

Preferred route is user-level: JetBrainsMono Nerd Font into `~/.local/share/fonts`, Papirus/Bibata into `~/.local/share/icons`. The apt packages are a fallback.

### 6.4 SDDM Omarchy login theme (optional)

- Copy Omarchy's `default/sddm/omarchy` theme to `/usr/share/sddm/themes/omarchy`.
- Back up `/etc/sddm.conf.d/50-ubuntu-budgie.conf`.
- Test with `sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/omarchy`.
- Keep the Budgie theme one command away if the greeter fails.

### 6.5 Explicitly not planned

- Replacing Ubuntu with Arch/Omarchy.
- Limine, Plymouth, Snapper, ZRAM, kernel changes.
- Installing application suites (Nautilus, LibreOffice, Obsidian, OBS, Spotify, Signal, etc.).
- Enabling `hyprpaper` on this GPU (it currently fails GBM allocation).

---

## 7. Acceptance tests

| Test | Expected |
|---|---|
| `qs -p ~/.config/quickshell` (temp instance) | Loads to shell; no fatal errors |
| `hyprctl layers` | `quickshell:bar` present with exclusive zone 26 |
| `qs ipc call launcher toggle` | Launcher opens/closes; search filters installed apps |
| `qs ipc call panel toggle audio` | Audio panel opens; explains if PipeWire absent |
| `qs ipc call osd show volume 40` | OSD appears and auto-hides |
| `qs ipc call background next` | Wallpaper crossfades |
| `omarchy-theme set gruvbox` / `set tokyo-night` | All generated files update; borders, kitty, shell colors change |
| `hyprctl configerrors` | Empty |
| `hyprctl reload` | No errors; session intact |
| `Super+Space`, `Super+Return`, `Super+1..0`, `Super+Q`, `Super+Tab`, `Super+S` | Work as specified |
| `hyprlock` (manual, with user present) | Themed lock screen; PAM unlock works |
| Logout → login | Bar, theme, wallpaper and keybindings restored |
| Reboot | SDDM → Hyprland session → shell restored |

Screenshots will be captured with `grim` when §6.1 is approved; until then, validation is via logs, `hyprctl`, and QML IPC. Pixel-level checks (bar height, palette, panel geometry) will use screenshot analysis once available.

---

## 8. Risks and mitigations

| Risk | Mitigation |
|---|---|
| Quickshell 0.3.2 API differences from Omarchy's patched build | Custom QML against verified 0.3.2 modules: `Quickshell.Hyprland`, `Io`, `Wayland`, `Widgets`, `Networking`, `Bluetooth`, `Services.{SystemTray,Notifications,UPower,Mpris,Pipewire}` |
| Hyprland 0.53 lacks Omarchy's Lua config | Translate to `hyprland.conf` with `conf.d` includes |
| Software rendering | No blur/shadows; limited animations; 26 px bar; lightweight QML |
| Restarting the shell disrupts the current session | Develop in `qs -p`, keep old config, swap only after clean load |
| Missing daemons/tools | Panels/bindings degrade with a clear message; no shell crashes |
| Kitty live theme switching | `allow_remote_control socket-only` + `kitty @ set-colors`; restart fallback |
| Network takeover breaks connectivity | Snapshot + rollback procedure in §6.2 |
| Lost existing work | Timestamped backups in `~/.config/omarchy/backups/` |

---

## 9. Execution order / handoff

1. **Approve this intent** (and optionally approve §6).
2. Switch from Plan to Build agent.
3. Implement §5 (user-level UI) and run the §7 tests that do not need missing tools.
4. If §6 is approved: run the install script, then re-run the full acceptance tests and enable the panels/clipboard/screenshot features.
5. Optional later phases: SDDM theme, icon/cursor polish, additional panels/widgets.

Until step 1–2, this document is the only artifact; no files outside `~/.opencode/plan` have been changed.
