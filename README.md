# Red Installer

> An unofficial community installer for [Red-DiscordBot](https://github.com/Cog-Creators/Red-DiscordBot). Because nobody should have to copy-paste ten commands just to get a bot running.

---

## Star This If It Saves You Time

Seriously. It takes 2 seconds. I'm not going to pretend I don't check the star count.

**[Star on GitHub](https://github.com/BigPattyOG/red-installer)** --- It helps more people find this thing.

---

## What Even Is This?

Red is a powerful, self-hosted, fully modular Discord bot. It's great. The setup process, on the other hand, is a wall of commands that most people really don't want to deal with.

So I made this. One command. It figures out your OS, installs what it needs, sets up Python properly, and walks you through getting your bot configured. No PhD required.

---

## Just Run It

### Linux / macOS

```bash
curl -fsSL https://raw.githubusercontent.com/BigPattyOG/red-installer/main/install.sh | bash
```

### Windows

Open PowerShell **as Administrator** and paste this:

```powershell
irm https://raw.githubusercontent.com/BigPattyOG/red-installer/main/install.ps1 | iex
```

That's it. The script takes it from there.

> **Wrong terminal?** If you accidentally ran the `.sh` script on Windows, it'll catch that and tell you what to do instead. I thought of you.

---

## What It Does To Your Machine

Before doing anything, the installer will show you exactly what it's going to touch and ask you to confirm. No surprises.

The short version:

1. Checks your OS, disk space, and internet (you're welcome)
2. Installs Python, Git, and build tools for your platform
3. Creates an isolated Python virtual environment for Red (so it doesn't stomp on anything else)
4. Downloads and installs Red-DiscordBot
5. Asks you a few questions to set up your bot instance
6. Optionally sets up a systemd service so Red starts when the machine does (Linux only)

---

## The Questions It Will Ask You

The installer walks you through each question on its own screen so it doesn't just dump everything at once. Here's what it'll want:

**Instance name** --- just a label. `mybot`, `redbot`, whatever. It's not your bot's Discord name, just how your machine identifies it.

**Data path** --- where Red stores its stuff. Hit Enter to use the default. You probably want the default.

**Backend** --- how Red stores data internally:
- `JSON` --- simple flat files, no database needed. **Pick this unless you have a reason not to.**
- `PostgreSQL` --- if you actually have a Postgres server running and know what you're doing. The installer will ask for your connection details (host, port, username, password, database name).

**Audio** --- want your bot to play music? Say yes and Java 17 gets installed. Red handles the rest itself (no Lavalink fiddling required from your end). You can skip this and add it later.

**Bot token** --- get it from the [Discord Developer Portal](https://discord.com/developers/applications). It won't show on screen while you type. That's intentional, not a bug.

> The installer validates your token length. If it's shorter than 50 characters, it'll tell you to go back and copy the whole thing.


> **Do not use `/`.** It will cause weirdness with Discord's built-in slash commands. The installer will literally refuse to let you do this and ask you again.

**Systemd service (Linux only)** --- want Red to survive reboots? Say yes and the installer sets up a service that starts your bot automatically.

---

## Supported Systems

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

### Everything Else
| OS | Notes |
|---|---|
| macOS | Intel and Apple Silicon, both work |
| Windows | PowerShell + Chocolatey --- runs as Administrator |

> **Ubuntu non-LTS (23.10, 24.10, etc.)** --- not supported. The Red team themselves say Python 3.11 is not reliably available on non-LTS Ubuntu. Just use 24.04 LTS and save yourself the headache.

---

## WSL Users

Both scripts detect WSL and stop you before things go wrong.

**If you're running the bash script inside WSL:** it'll offer you two options --- stay in WSL and install Red there, or switch to the PowerShell script for a proper native Windows install.

**If you accidentally ran the PowerShell script inside a WSL PowerShell session:** it'll catch that and redirect you, because Chocolatey and cmd.exe have no business being in WSL.

Want Red inside WSL? Open your WSL terminal (Ubuntu from the Start Menu, for example) and run the bash command above directly.

---

## Managing Your Bot

### Systemd (Linux)

```bash
sudo systemctl status  red@yourinstancename
sudo journalctl -eu    red@yourinstancename -f
sudo systemctl restart red@yourinstancename
sudo systemctl stop    red@yourinstancename
```

### Running Manually

**Linux / macOS:**
```bash
source ~/redenv/bin/activate
redbot yourinstancename
```

**Windows (Command Prompt --- not PowerShell):**
```cmd
%userprofile%edenv\Scriptsctivate.bat
redbot yourinstancename
```

---

## Audio Setup

When you say yes to audio, the installer puts Java 17 on your machine. That's all you need.

To actually turn on audio in your bot:
1. Start Red and log in to Discord
2. Run `[p]load audio` in your server
3. Done

Red handles Lavalink internally. You don't need to set up a separate server. If you want the full details anyway: [Audio Cog Docs](https://docs.discord.red/en/stable/cog_guides/audio.html)

---

## Updating Red

When a new version drops:

**Linux / macOS:**
```bash
source ~/redenv/bin/activate
python -m pip install -U Red-DiscordBot
```

**Windows (Command Prompt):**
```cmd
%userprofile%edenv\Scriptsctivate.bat
python -m pip install -U Red-DiscordBot
```

PostgreSQL users:
```bash
python -m pip install -U "Red-DiscordBot[postgres]"
```

---

## Something Broke

If the installer fails on a step, it'll show you the error right there. On Linux/macOS, the full log gets saved to a file in `/tmp` --- the exact path is printed when something goes wrong.

Still stuck? [Open an issue](https://github.com/BigPattyOG/red-installer/issues) and tell me your OS. I'll take a look.

---

## Useful Links

| | |
|---|---|
| Red Documentation | https://docs.discord.red/en/stable/ |
| Official Install Guides | https://docs.discord.red/en/stable/install_guides/ |
| Audio Setup | https://docs.discord.red/en/stable/cog_guides/audio.html |
| PostgreSQL Setup | https://docs.discord.red/en/stable/postgres.html |
| Red on GitHub | https://github.com/Cog-Creators/Red-DiscordBot |

---

## Disclaimer

This is an unofficial community project, not endorsed by the Red team. I'm just a person who got tired of doing this manually. The official docs are at [docs.discord.red](https://docs.discord.red/en/stable/install_guides/).

---

## Seriously Though, Star It

If this saved you 20 minutes of copy-pasting, a star is a nice way to say thanks. It also helps other people find this instead of suffering through the manual process.

**[https://github.com/BigPattyOG/red-installer](https://github.com/BigPattyOG/red-installer)**

*Made by BigPattyOG --- the one watching the star count way too closely*
