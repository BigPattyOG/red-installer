# Red Installer 🤖

An unofficial community installer for [Red-DiscordBot](https://github.com/Cog-Creators/Red-DiscordBot) that takes the pain out of getting Red up and running.

No more copy-pasting commands one by one — just run the script and it'll walk you through everything.

---

## What is this?

Red is a self-hosted, fully modular Discord bot. It's awesome. Setting it up however... not always the most fun experience.

This installer handles all of that for you. It detects your OS, installs the right dependencies, sets up a Python virtual environment, installs Red, and gets your bot configured — all in one go.

---

## Supported Operating Systems

### Linux
| OS | Version |
|---|---|
| Ubuntu | 22.04 LTS, 24.04 LTS |
| Debian | 12 (Bookworm) |
| Raspberry Pi OS | 12 (Bookworm) |
| Fedora | Latest |
| CentOS Stream | 9 |
| RHEL | 8, 9 |
| Alma Linux | 8, 9 |
| Rocky Linux | 8, 9 |
| Oracle Linux | 8, 9 |
| Amazon Linux | 2023 |
| openSUSE Leap | 15.6+ |
| openSUSE Tumbleweed | Latest |
| Arch Linux | Latest |

### Other
| OS | Notes |
|---|---|
| macOS | Intel and Apple Silicon supported |
| Windows | Via PowerShell + Chocolatey |

> **Ubuntu non-LTS (e.g. 24.10)** is not supported. The official Red docs confirm Python 3.11 isn't available on non-LTS releases right now. Stick with 24.04 LTS.

---

## How to Use

### Linux / macOS

Open a terminal and run:

```bash
curl -fsSL https://raw.githubusercontent.com/BigPattyOG/red-installer/main/install.sh | bash
```

### Windows

Open PowerShell **as Administrator** and run:

```powershell
irm https://raw.githubusercontent.com/BigPattyOG/red-installer/main/install.ps1 | iex
```

> **Note:** If you accidentally run the `.sh` script on Windows (e.g. via Git Bash), it'll catch that and tell you to use the PowerShell one instead. No harm done.

### WSL (Windows Subsystem for Linux)

Both scripts detect WSL and guide you to the right place:

- **Running the bash script inside WSL** — it'll spot that and offer you two choices: carry on and install Red inside WSL (by running the bash script directly in your WSL terminal), or switch to the PowerShell script for a native Windows install instead.
- **Running the PowerShell script inside a WSL PowerShell session** — it'll catch that too and redirect you before anything breaks, since the Windows-specific tooling (Chocolatey, `cmd`, etc.) won't work inside WSL.

**Want Red inside WSL?** Open your WSL terminal (e.g. Ubuntu from the Start Menu) and run:

```bash
curl -fsSL https://raw.githubusercontent.com/BigPattyOG/red-installer/main/install.sh | bash
```

**Want Red on native Windows?** Open a regular PowerShell window (not WSL) as Administrator and run the PowerShell script as shown above.

---

## What It Does

Once you kick it off, the installer will:

1. ✅ Check your OS and pick the right install method
2. ✅ Check you have enough disk space and a working internet connection
3. ✅ Install Python, Git and the required build tools for your OS
4. ✅ Create an isolated Python virtual environment for Red
5. ✅ Install Red-DiscordBot (with PostgreSQL support if you choose it)
6. ✅ Ask you to set up your bot instance — name, data path, backend, token and prefix
7. ✅ Optionally set up a systemd service so your bot starts on boot (Linux only)

---

## Setup Options

The installer will ask you a few things before it does anything. Here's what to expect:

**Instance name** — just a label so Red knows which bot is which on this machine. Something like `mybot` or `redbot`. This doesn't change your bot's name on Discord.

**Data path** — where Red stores its data. You can just hit Enter to use the default.

**Backend** — how Red stores data:
- `JSON` — simple, no extra setup needed. Recommended for most people.
- `PostgreSQL` — for advanced users who already have a PostgreSQL server running.

**Audio** — do you want music support? This installs Java 17 on your machine ready to go.

**Bot token** — grab this from the [Discord Developer Portal](https://discord.com/developers/applications). It won't show on screen as you type.

**Prefix** — the character your bot responds to. `!`, `?`, `.` etc.
> ⚠️ Don't use `/` �� it doesn't play nicely with Discord's slash commands.

**Service (Linux only)** — want the bot to start automatically on boot? Say yes and we'll set up a systemd service for you.

---

## After the Install

The installer gets Red fully set up and running. For anything beyond that — like setting up audio cogs, adding cogs, configuring permissions or connecting to PostgreSQL — the official Red docs have you covered:

👉 [Red Documentation](https://docs.discord.red/en/stable/)
👉 [Getting Started with Red](https://docs.discord.red/en/stable/getting_started.html)
👉 [Audio Setup](https://docs.discord.red/en/stable/cog_guides/audio.html)
👉 [Installing Cogs](https://docs.discord.red/en/stable/cog_guides/index.html)
👉 [PostgreSQL Setup](https://docs.discord.red/en/stable/postgres.html)

---

## Managing Your Bot

### If you set up a systemd service (Linux)

```bash
# Check if it's running
sudo systemctl status red@yourinstancename

# See live logs
sudo journalctl -eu red@yourinstancename -f

# Restart it
sudo systemctl restart red@yourinstancename

# Stop it
sudo systemctl stop red@yourinstancename
```

### Starting manually

**Linux / macOS:**

```bash
source ~/redenv/bin/activate
redbot yourinstancename
```

**Windows — open Command Prompt (not PowerShell) and run:**

```cmd
%userprofile%\redenv\Scripts\activate.bat
redbot yourinstancename
```

---

## Updating Red

Whenever a new version of Red drops, just run this inside your activated virtual environment:

**Linux / macOS:**

```bash
source ~/redenv/bin/activate
python -m pip install -U Red-DiscordBot
```

**Windows (Command Prompt):**

```cmd
%userprofile%\redenv\Scripts\activate.bat
python -m pip install -U Red-DiscordBot
```

Or if you're using PostgreSQL:

```bash
python -m pip install -U "Red-DiscordBot[postgres]"
```

---

## Something Went Wrong?

If the installer falls over on a step it'll show you the exact error. On Linux/macOS the full log is saved to `/tmp/redbot_install.log` if you need more detail.

If you're stuck, feel free to [open an issue](https://github.com/BigPattyOG/red-installer/issues) and let me know what OS you're on. I'll take a look as soon as I can.

---

## This Isn't an Official Red Project

This installer is an unofficial community tool. For the official installation guides head to:

👉 [docs.discord.red](https://docs.discord.red/en/stable/install_guides/)

For Red itself:

👉 [Cog-Creators/Red-DiscordBot](https://github.com/Cog-Creators/Red-DiscordBot)

---

## Give It a Star ⭐

If this saved you some time, a star on GitHub would mean a lot!

👉 [https://github.com/BigPattyOG/red-installer](https://github.com/BigPattyOG/red-installer)

---

*Made with ❤️ by BigPattyOG*