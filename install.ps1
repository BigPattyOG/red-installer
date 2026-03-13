# ============================================================
#  Red-DiscordBot Community Installer — Windows
#  Run this in PowerShell as Administrator:
#  irm https://raw.githubusercontent.com/BigPattyOG/red-installer/main/install.ps1 | iex
#
#  Official guide this is based on:
#  https://docs.discord.red/en/stable/install_guides/windows.html
# ============================================================

# ─────────────────────────────────────────────
# COLOURS
# PowerShell uses Write-Host with -ForegroundColor
# to print coloured text. We wrap it in a helper
# function so it's easy to reuse throughout.
# ─────────────────────────────────────────────
function Write-Colour {
    param(
        [string]$Text,
        [string]$Colour = "White"
    )
    Write-Host $Text -ForegroundColor $Colour
}

# ─────────────────────────────────────────────
# BANNER
# ─────────────────────────────────────────────
function Show-Banner {
    Clear-Host
    Write-Colour ""
    Write-Colour " ____  ____  ____    __  __ _  ____  ____  __   __    __    ____  ____ " "Cyan"
    Write-Colour "(  _ \(  __)(    \  (  )(  ( \/ ___)(_  _)/ _\ (  )  (  )  (  __)(  _ \" "Cyan"
    Write-Colour " )   / ) _)  ) D (   )( /    /\___ \  )( /    \/ (_/\/ (_/\ ) _)  )   /" "Cyan"
    Write-Colour "(__\_)(____)(____/  (__)\_)__)(____/ (__)\_/\_/\____/\____/(____)(__\_)" "Cyan"
    Write-Colour ""
    Write-Colour "            Unofficial Community Installer - By BigPattyOG" "Cyan"
    Write-Colour ""
}

# ─────────────────────────────────────────────
# SETUP STEP HEADER
# Clears screen, shows banner, then shows which
# step of the interactive setup we're on.
# ─────────────────────────────────────────────
function Show-SetupHeader {
    param([int]$Step, [int]$Total, [string]$Title)
    Show-Banner
    Write-Host "  " -NoNewline
    Write-Host "[Setup: Step $Step of $Total]" -ForegroundColor Cyan -NoNewline
    Write-Host "  $Title"
    Write-Colour "  ──────────────────────────────────────────────" "Cyan"
    Write-Colour ""
}

# ─────────────────────────────────────────────
# STEP TRACKING
# Script-scoped arrays that keep a history of
# completed steps for the install screen.
# ─────────────────────────────────────────────
$script:StepNum          = 0
$script:TotalSteps       = 0
$script:StepHistoryLabels = @()
$script:StepHistoryOK     = @()

# ─────────────────────────────────────────────
# DRAW INSTALL SCREEN
# Clears the terminal and redraws the banner
# plus all completed steps so the user gets a
# live tally of progress before each new step.
# ─────────────────────────────────────────────
function Draw-InstallScreen {
    Show-Banner
    Write-Host "  " -NoNewline
    Write-Host "Installing Red-DiscordBot" -ForegroundColor Cyan
    Write-Colour "  ──────────────────────────────────────────────" "Cyan"
    Write-Colour ""

    for ($i = 0; $i -lt $script:StepHistoryLabels.Count; $i++) {
        if ($script:StepHistoryOK[$i]) {
            Write-Host "  " -NoNewline
            Write-Host "✓" -ForegroundColor Green -NoNewline
            Write-Host "  $($script:StepHistoryLabels[$i])"
        } else {
            Write-Host "  " -NoNewline
            Write-Host "✗" -ForegroundColor Red -NoNewline
            Write-Host "  $($script:StepHistoryLabels[$i])"
        }
    }
}

# ─────────────────────────────────────────────
# RUN STEP
# Draws the install screen, shows the current
# step, runs it, then marks it done or failed.
# ─────────────────────────────────────────────
function Invoke-Step {
    param(
        [string]$Message,
        [scriptblock]$Action
    )

    $script:StepNum++
    Draw-InstallScreen
    Write-Host "  " -NoNewline
    Write-Host "►" -ForegroundColor Cyan -NoNewline
    Write-Host "  [$($script:StepNum)/$($script:TotalSteps)] $Message"

    try {
        & $Action
        $script:StepHistoryLabels += $Message
        $script:StepHistoryOK     += $true
        Draw-InstallScreen
        Write-Host "  " -NoNewline
        Write-Host "✓" -ForegroundColor Green -NoNewline
        Write-Host "  [$($script:StepNum)/$($script:TotalSteps)] $Message"
        Write-Colour ""
    }
    catch {
        $script:StepHistoryLabels += "$Message (FAILED)"
        $script:StepHistoryOK     += $false
        Write-Host "  " -NoNewline
        Write-Host "✗" -ForegroundColor Red -NoNewline
        Write-Host "  [$($script:StepNum)/$($script:TotalSteps)] $Message"
        Write-Colour ""
        Write-Colour "  Oopsie, something went wrong during: '$Message'" "Red"
        Write-Colour "  Error: $_" "Red"
        Write-Colour ""
        exit 1
    }
}

# ─────────────────────────────────────────────
# CHECK: Non-Windows environment
# $IsLinux / $IsMacOS are built into PowerShell
# Core and are $true whenever pwsh runs outside
# Windows — including native Linux and macOS.
# WSL_DISTRO_NAME is always set by WSL itself;
# WSL_INTEROP is a fallback for older WSL builds.
# All of these cases are non-Windows and the
# Windows-specific tooling (choco, cmd /c
# activate.bat) will not work in any of them.
# We give them two clear options so they land in
# the right place.
# ─────────────────────────────────────────────
function Assert-NotWSL {
    $isWSL     = ($null -ne $env:WSL_DISTRO_NAME) -or ($null -ne $env:WSL_INTEROP)
    $isNonWin  = ($IsLinux -eq $true) -or ($IsMacOS -eq $true)

    if ($isWSL -or $isNonWin) {
        Clear-Host
        Write-Colour ""
        if ($isWSL) {
            Write-Colour "  +----------------------------------------------------------+" "Yellow"
            Write-Colour "  |   PowerShell in WSL is an interesting move, but not      |" "Yellow"
            Write-Colour "  |                   the right one here!                    |" "Yellow"
            Write-Colour "  +----------------------------------------------------------+" "Yellow"
            Write-Colour ""
            Write-Colour "  This script is built for Windows, not Linux." "White"
            Write-Colour ""
            Write-Colour "  Want Red inside WSL? Run the bash script directly in your" "White"
            Write-Colour "  WSL terminal (e.g. Ubuntu from the Start Menu):" "White"
        } else {
            Write-Colour "  +----------------------------------------------------------+" "Yellow"
            Write-Colour "  |  PowerShell on Linux/macOS is an interesting move, but  |" "Yellow"
            Write-Colour "  |                   not the right one here!                |" "Yellow"
            Write-Colour "  +----------------------------------------------------------+" "Yellow"
            Write-Colour ""
            Write-Colour "  This script is built for Windows, not Linux/macOS." "White"
            Write-Colour ""
            Write-Colour "  Want Red on Linux/macOS? Run the bash script directly in" "White"
            Write-Colour "  your terminal:" "White"
        }
        Write-Colour ""
        Write-Colour "    curl -fsSL https://raw.githubusercontent.com/BigPattyOG/red-installer/main/install.sh | bash" "Cyan"
        Write-Colour ""
        Write-Colour "  Want Red on native Windows instead? Open a real PowerShell" "White"
        Write-Colour "  window as Administrator and run:" "White"
        Write-Colour ""
        Write-Colour "    irm https://raw.githubusercontent.com/BigPattyOG/red-installer/main/install.ps1 | iex" "Cyan"
        Write-Colour ""
        Write-Colour "  Either way works great — it's just down to where you want" "White"
        Write-Colour "  Red to live!" "White"
        Write-Colour ""
        Write-Colour "  https://github.com/BigPattyOG/red-installer/" "Cyan"
        Write-Colour ""
        Read-Host "  Press Enter to exit"
        exit 1
    }
}

# ─────────────────────────────────────────────
# CHECK: Administrator
# Chocolatey and system installs need Admin.
# WindowsIdentity gets the current user info.
# IsInRole checks if they're an Administrator.
# ─────────────────────────────────────────────
function Assert-IsAdmin {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal   = [Security.Principal.WindowsPrincipal]$currentUser
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Colour ""
        Write-Colour "  [!] This script needs to be run as Administrator." "Red"
        Write-Colour "      Right-click PowerShell and choose 'Run as Administrator'." "Red"
        Write-Colour ""
        exit 1
    }
}

# ─────────────────────────────────────────────
# CHECK: Internet connectivity
# Test-Connection is PowerShell's built-in ping.
# -Quiet returns True/False instead of details.
# ─────────────────────────────────────────────
function Assert-Internet {
    Write-Host "  Checking internet connection..." -NoNewline
    if (-not (Test-Connection -ComputerName "github.com" -Count 1 -Quiet -ErrorAction SilentlyContinue)) {
        Write-Colour " FAILED" "Red"
        Write-Colour ""
        Write-Colour "  Installing things from the internet works best when you have internet" "Red"
        Write-Colour "  Shame I didn't add a dino game for you to play..." "Red"
        Write-Colour ""
        exit 1
    }
    Write-Colour " OK" "Green"
}

# ─────────────────────────────────────────────
# CHECK: Disk space
# Gets free space on the C: drive.
# Get-PSDrive returns drive info — we read the
# Free property and convert bytes to GB.
# ─────────────────────────────────────────────
function Assert-DiskSpace {
    Write-Host "  Checking disk space..." -NoNewline
    $drive    = Get-PSDrive -Name C
    $freeGB   = [math]::Round($drive.Free / 1GB, 1)
    $neededGB = 5

    if ($freeGB -lt $neededGB) {
        Write-Colour " FAILED" "Red"
        Write-Colour ""
        Write-Colour "  Oops! Space you not have, mmm" "Red"
        Write-Colour "  Required: ${neededGB} GB  |  Available: ${freeGB} GB" "Red"
        Write-Colour "  Feel free to run this script again when you have the space" "Red"
        Write-Colour ""
        exit 1
    }
    Write-Colour " OK (${freeGB} GB free)" "Green"
}

# ─────────────────────────────────────────────
# CHECK: Chocolatey installed
# Chocolatey is a package manager for Windows
# (like apt on Ubuntu or brew on macOS).
# We use it to install Python, Git and Java.
# Get-Command checks if 'choco' exists on PATH.
# ─────────────────────────────────────────────
function Test-ChocoInstalled {
    return ($null -ne (Get-Command choco -ErrorAction SilentlyContinue))
}

# ─────────────────────────────────────────────
# INSTALL CHOCOLATEY
# Official install command straight from
# chocolatey.org — same as the Red docs use.
# Set-ExecutionPolicy allows the install script
# to run. SecurityProtocol enables TLS 1.2 so
# the download works on older Windows builds.
# ─────────────────────────────────────────────
function Install-Chocolatey {
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = `
        [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString(
        'https://community.chocolatey.org/install.ps1'
    ))
}

# ─────────────────────────────────────────────
# DISCLAIMER
# Shows what the script will change and asks
# the user to accept before doing anything.
# Also nudges them to star the repo.
# ─────────────────────────────────────────────
function Show-Disclaimer {
    Show-Banner
    Write-Colour "  Before we start — a quick heads up" "Yellow"
    Write-Colour "  ──────────────────────────────────────────────" "Cyan"
    Write-Colour ""
    Write-Colour "  Here's what this script is about to do to your machine:" "White"
    Write-Colour ""
    Write-Colour "    • Install Chocolatey (if not already installed)" "White"
    Write-Colour "    • Install Python 3.11, Git, and Visual C++ build tools via Chocolatey" "White"
    Write-Colour "    • Create a Python virtual environment at %USERPROFILE%\redenv" "White"
    Write-Colour "    • Download and install Red-DiscordBot and its dependencies" "White"
    Write-Colour "    • Create a Red instance config in your AppData folder" "White"
    Write-Colour "    • (Optional) Install Java 17 for audio support" "White"
    Write-Colour ""
    Write-Colour "  This script needs to run as Administrator to install packages." "White"
    Write-Colour "  No funny business — only standard install locations are used." "White"
    Write-Colour ""
    Write-Colour "  ──────────────────────────────────────────────" "Cyan"
    Write-Colour ""
    Write-Colour "  ⭐  Also — if this saves you some headaches, please star the repo:" "White"
    Write-Colour "      https://github.com/BigPattyOG/red-installer" "Cyan"
    Write-Colour ""
    Write-Colour "  Stars help more people find this thing. It takes literally 2 seconds." "White"
    Write-Colour "  I'll pretend I'm not obsessively watching the star count. (I am.)" "White"
    Write-Colour ""
    Write-Colour "  ──────────────────────────────────────────────" "Cyan"
    Write-Colour ""
    $answer = Read-Host "  I've read the above and I'm ready to proceed [y/N]"
    if ($answer -notmatch '^[Yy]$') {
        Write-Colour ""
        Write-Colour "  Fair enough. No changes were made. Come back when you're ready." "Yellow"
        Write-Colour ""
        exit 0
    }
}

# ─────────────────────────────────────────────
# INTERACTIVE SETUP
# Each question gets its own screen with a step
# counter so the display stays clean. Validates
# token length and rejects / as a prefix.
# Collects PostgreSQL credentials if selected.
# Read-Host in PowerShell always reads from the
# console directly so no /dev/tty equivalent
# is needed here unlike the bash script.
# ─────────────────────────────────────────────
function Get-InstallOptions {
    # Base steps: name, path, backend, audio, token, prefix
    $totalSteps = 6
    $step = 0

    # Step: Instance name
    $step++
    Show-SetupHeader -Step $step -Total $totalSteps -Title "Instance Name"
    Write-Colour "  This is just a label so Red knows which bot is which on this machine." "White"
    Write-Colour "  Examples: mybot, redbot, mainbot" "White"
    Write-Colour "  It won't (and can't) change your bot's name on Discord." "White"
    Write-Colour ""
    do {
        $script:InstanceName = Read-Host "  Instance name"
    } while ([string]::IsNullOrWhiteSpace($script:InstanceName))

    # Step: Data path
    $step++
    $defaultData = "$env:APPDATA\Red-DiscordBot\$($script:InstanceName)"
    Show-SetupHeader -Step $step -Total $totalSteps -Title "Data Storage Path"
    Write-Colour "  Where should Red store its data? Configs, cog data, all of it." "White"
    Write-Colour "  Press Enter to use the default, or type a different path." "White"
    Write-Colour ""
    Write-Colour "  Default: $defaultData" "White"
    Write-Colour ""
    $inputPath = Read-Host "  Data path [default: above]"
    $script:DataDir = if ([string]::IsNullOrWhiteSpace($inputPath)) { $defaultData } else { $inputPath }

    # Step: Backend
    $step++
    Show-SetupHeader -Step $step -Total $totalSteps -Title "Data Backend"
    Write-Colour "  How should Red store its data internally?" "White"
    Write-Colour ""
    Write-Colour "  1) JSON  — Simple flat files, no database needed. This is the one" "White"
    Write-Colour "             90% of people should pick. Seriously, just pick this." "White"
    Write-Colour ""
    Write-Colour "  2) PostgreSQL — For the 10% who actually have a Postgres server" "White"
    Write-Colour "                  running and know what they're doing." "White"
    Write-Colour ""
    $backendChoice = Read-Host "  Choice [1/2, default 1]"
    $script:Backend = if ($backendChoice -eq "2") { "postgres" } else { "json" }

    # PostgreSQL credentials (if selected)
    $script:PgHost   = ""
    $script:PgPort   = ""
    $script:PgUser   = ""
    $script:PgPass   = ""
    $script:PgDbname = ""

    if ($script:Backend -eq "postgres") {
        $totalSteps++
        $step++
        Show-SetupHeader -Step $step -Total $totalSteps -Title "PostgreSQL Connection Details"
        Write-Colour "  Alright, you chose PostgreSQL. Let's get the connection details sorted." "White"
        Write-Colour "  Leave any field blank to use its default (shown in brackets)." "White"
        Write-Colour ""

        $h = Read-Host "  Database host [default: localhost]"
        $script:PgHost = if ([string]::IsNullOrWhiteSpace($h)) { "localhost" } else { $h }

        do {
            $p = Read-Host "  Database port [default: 5432]"
            $script:PgPort = if ([string]::IsNullOrWhiteSpace($p)) { "5432" } else { $p }
        } while (-not ($script:PgPort -match '^\d+$'))

        $u = Read-Host "  Database username [default: redbot]"
        $script:PgUser = if ([string]::IsNullOrWhiteSpace($u)) { "redbot" } else { $u }

        Write-Colour ""
        Write-Colour "  NOTE: Password won't show as you type." "Red"
        do {
            $securePgPass   = Read-Host "  Database password" -AsSecureString
            $script:PgPass  = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
                [Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePgPass)
            )
            if ([string]::IsNullOrWhiteSpace($script:PgPass)) {
                Write-Colour "  Password can't be empty — Red needs it to connect." "Red"
            }
        } while ([string]::IsNullOrWhiteSpace($script:PgPass))

        $d = Read-Host "  Database name [default: redbot]"
        $script:PgDbname = if ([string]::IsNullOrWhiteSpace($d)) { "redbot" } else { $d }
    }

    # Step: Audio
    $step++
    Show-SetupHeader -Step $step -Total $totalSteps -Title "Audio Support"
    Write-Colour "  Want your bot to play music? This installs Java 17, which Red's" "White"
    Write-Colour "  Audio cog needs to run its built-in Lavalink server." "White"
    Write-Colour ""
    Write-Colour "  You can skip this and enable it later — just know you'll need" "White"
    Write-Colour "  Java on the system before audio will work." "White"
    Write-Colour ""
    $audioChoice = Read-Host "  Enable audio support? [y/N]"
    $script:WantAudio = ($audioChoice -match '^[Yy]$')

    # Step: Bot token
    $step++
    Show-SetupHeader -Step $step -Total $totalSteps -Title "Discord Bot Token"
    Write-Colour "  Grab your bot token from the Discord Developer Portal:" "White"
    Write-Colour "  https://discord.com/developers/applications" "Cyan"
    Write-Colour ""
    Write-Colour "  Go to your application → Bot → Reset Token." "White"
    Write-Colour "  Copy the whole thing — it's a long string of random characters." "White"
    Write-Colour ""
    Write-Colour "  NOTE: The token won't show as you type. That's on purpose." "Red"
    Write-Colour ""
    do {
        $secureToken = Read-Host "  Bot token" -AsSecureString
        $script:BotToken = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
            [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureToken)
        )
        if ([string]::IsNullOrWhiteSpace($script:BotToken)) {
            Write-Colour "  With no token, you have no bot. Try again." "Red"
        } elseif ($script:BotToken.Length -lt 50) {
            Write-Colour "  That token looks too short (Discord tokens are 50+ characters)." "Red"
            Write-Colour "  Double-check you copied the whole thing." "Red"
            $script:BotToken = ""
        }
    } while ([string]::IsNullOrWhiteSpace($script:BotToken))

    # Step: Prefix
    $step++
    Show-SetupHeader -Step $step -Total $totalSteps -Title "Command Prefix"
    Write-Colour "  This is the character your bot listens to. Like !help or ?play." "White"
    Write-Colour "  Pick something short and memorable." "White"
    Write-Colour ""
    Write-Colour "  DO NOT use / as your prefix — it conflicts with Discord's" "Red"
    Write-Colour "  built-in slash commands and things will get weird fast." "Red"
    Write-Colour ""
    do {
        $prefixInput = Read-Host "  Command prefix [default: !]"
        $script:BotPrefix = if ([string]::IsNullOrWhiteSpace($prefixInput)) { "!" } else { $prefixInput }
        if ($script:BotPrefix.StartsWith("/")) {
            Write-Colour "  Nope. Anything starting with / is off the table." "Red"
            Write-Colour "  Pick something else (!, ?, ., etc.)" "Red"
            $script:BotPrefix = ""
        }
    } while ([string]::IsNullOrWhiteSpace($script:BotPrefix))

    Show-Banner
    Write-Colour "  ✓ Setup details saved. Starting installation..." "Green"
    Write-Colour ""
    Start-Sleep -Seconds 1
}

# ─────────────────────────────────────────────
# INSTALL PACKAGES VIA CHOCOLATEY
# Taken directly from the official Red Windows
# install guide:
# https://docs.discord.red/en/stable/install_guides/windows.html
#
#   - git (GitOnlyOnPath keeps PATH clean,
#     WindowsTerminal adds it to Windows Terminal)
#   - visualstudio2022-workload-vctools provides
#     the C++ build tools pip needs to compile
#     some packages
#   - python311 installs Python 3.11 specifically
#   - temurin17 is Java 17 for audio (optional)
#
# choco upgrade installs if missing or upgrades
# if already present. -y = yes to all prompts.
# ─────────────────────────────────────────────
function Install-Packages {
    choco upgrade git --params "/GitOnlyOnPath /WindowsTerminal" -y
    choco upgrade visualstudio2022-workload-vctools -y
    choco upgrade python311 -y

    if ($script:WantAudio) {
        choco upgrade temurin17 -y
    }

    # Refresh PATH so python/git are available
    # without needing to close and reopen PowerShell.
    # Machine gets system-wide entries, User gets
    # per-user entries — we combine both.
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
                [System.Environment]::GetEnvironmentVariable("Path", "User")
}

# ─────────────────────────────────────────────
# CREATE VIRTUAL ENVIRONMENT
# A venv is an isolated Python install just for
# Red so its packages don't affect system Python.
# Official guide uses: py -3.11 -m venv
# The py launcher selects Python 3.11 specifically
# even if multiple Python versions are installed.
# We create it in %USERPROFILE%\redenv matching
# the official guide's recommended location.
# ─────────────────────────────────────────────
function New-RedVenv {
    $venvPath = "$env:USERPROFILE\redenv"
    if (-not (Test-Path $venvPath)) {
        py -3.11 -m venv $venvPath
    }
}

# ─────────────────────────────────────────────
# INSTALL RED INTO VENV
# Activates the venv then installs Red via pip.
# On Windows the activate script lives in
# Scripts\ not bin\ like on Linux/macOS.
# If the user chose PostgreSQL we install with
# the [postgres] extra to include the db driver.
# cmd /c runs in a regular Command Prompt which
# is required for the activate script — the
# official docs specifically warn that activate
# does not work in PowerShell directly.
# ─────────────────────────────────────────────
function Install-Red {
    $activate = "$env:USERPROFILE\redenv\Scripts\activate.bat"
    $package  = if ($script:Backend -eq "postgres") {
        '"Red-DiscordBot[postgres]"'
    } else {
        "Red-DiscordBot"
    }
    cmd /c "$activate && python -m pip install -U pip wheel && python -m pip install -U $package"
}

# ─────────────────────────────────────────────
# CONFIGURE RED INSTANCE
# For JSON: runs redbot-setup non-interactively.
# For PostgreSQL: writes the config file via
# a Python helper to bypass the interactive
# getpass prompt inside redbot-setup.
# mkdir with -Force creates the data dir if it
# doesn't already exist, silently if it does.
# ─────────────────────────────────────────────
function Set-RedInstance {
    $activate = "$env:USERPROFILE\redenv\Scripts\activate.bat"
    New-Item -ItemType Directory -Force -Path $script:DataDir | Out-Null

    if ($script:Backend -eq "postgres") {
        # Write the postgres config directly using Python.
        # redbot-setup for postgres calls getpass interactively,
        # so we bypass it and write the instance config file ourselves.
        $pyScript = [System.IO.Path]::GetTempFileName() + ".py"
        $pyCode = @"
import json, os
from pathlib import Path

instance_name = os.environ['INSTANCE_NAME']
data_dir      = os.environ['DATA_DIR']
pg_host       = os.environ.get('PG_HOST') or None
pg_port_s     = os.environ.get('PG_PORT', '')
pg_port       = int(pg_port_s) if pg_port_s and pg_port_s.isdigit() else None
pg_user       = os.environ.get('PG_USER') or None
pg_pass       = os.environ.get('PG_PASS') or None
pg_dbname     = os.environ.get('PG_DBNAME') or None

try:
    from platformdirs import user_config_dir
    cfg_dir = Path(user_config_dir('Red-DiscordBot'))
except Exception:
    cfg_dir = Path(os.environ.get('APPDATA', Path.home())) / 'Red-DiscordBot'

cfg_dir.mkdir(parents=True, exist_ok=True)
cfg_file = cfg_dir / 'config.json'

cfg = json.loads(cfg_file.read_text(encoding='utf-8')) if cfg_file.exists() else {}
cfg[instance_name] = {
    'DATA_PATH': data_dir,
    'STORAGE_TYPE': 'postgres',
    'STORAGE_DETAILS': {
        'host':     pg_host,
        'port':     pg_port,
        'user':     pg_user,
        'password': pg_pass,
        'database': pg_dbname,
    },
}
cfg_file.write_text(json.dumps(cfg, indent=4), encoding='utf-8')
print(f'Config written to {cfg_file}')
"@
        Set-Content -Path $pyScript -Value $pyCode -Encoding UTF8
        $env:INSTANCE_NAME = $script:InstanceName
        $env:DATA_DIR       = $script:DataDir
        $env:PG_HOST        = $script:PgHost
        $env:PG_PORT        = $script:PgPort
        $env:PG_USER        = $script:PgUser
        $env:PG_PASS        = $script:PgPass
        $env:PG_DBNAME      = $script:PgDbname
        cmd /c "$activate && python `"$pyScript`""
        Remove-Item -Path $pyScript -ErrorAction SilentlyContinue
    } else {
        $cmd = "$activate && redbot-setup " +
               "--instance-name `"$($script:InstanceName)`" " +
               "--data-path `"$($script:DataDir)`" " +
               "--backend $($script:Backend) " +
               "--no-prompt"
        cmd /c $cmd
    }
}

# ─────────────────────────────────────────────
# SET TOKEN AND PREFIX
# Uses redbot --edit to save the bot token and
# prefix into this instance's config file.
# --no-prompt means it won't ask for anything.
# ─────────────────────────────────────────────
function Set-TokenAndPrefix {
    $activate = "$env:USERPROFILE\redenv\Scripts\activate.bat"
    $cmd = "$activate && redbot `"$($script:InstanceName)`" " +
           "--edit " +
           "--token `"$($script:BotToken)`" " +
           "--prefix `"$($script:BotPrefix)`" " +
           "--no-prompt"
    cmd /c $cmd
}

# ─────────────────────────────────────────────
# FINAL SUMMARY
# Prints a clean summary of what was installed
# and how to start the bot going forward.
# ─────────────────────────────────────────────
function Show-Summary {
    Write-Colour ""
    Write-Colour "  +----------------------------------------------------------+" "Green"
    Write-Colour "  |                 Installation Complete!                   |" "Green"
    Write-Colour "  +----------------------------------------------------------+" "Green"
    Write-Colour ""
    Write-Colour "  Instance   : $($script:InstanceName)" "White"
    Write-Colour "  Data path  : $($script:DataDir)" "White"
    Write-Colour "  Backend    : $($script:Backend)" "White"
    Write-Colour "  Prefix     : $($script:BotPrefix)" "White"
    Write-Colour "  Venv       : $env:USERPROFILE\redenv" "White"
    Write-Colour ""
    Write-Colour "  To start Red, open Command Prompt (not PowerShell) and run:" "Yellow"
    Write-Colour "    $env:USERPROFILE\redenv\Scripts\activate.bat" "Cyan"
    Write-Colour "    redbot $($script:InstanceName)" "Cyan"
    Write-Colour ""
    Write-Colour "  NOTE: The official docs warn that the activate script" "Yellow"
    Write-Colour "  does not work in PowerShell — use Command Prompt instead." "Yellow"

    if ($script:WantAudio) {
        Write-Colour ""
        Write-Colour "  Audio setup:" "Yellow"
        Write-Colour "    Java 17 is installed and ready. To enable audio in your bot:" "White"
        Write-Colour "      1. Start Red and log in to Discord" "White"
        Write-Colour "      2. Run: [p]load audio" "White"
        Write-Colour "      3. That's it — Red manages Lavalink itself." "White"
        Write-Colour "    Full audio docs: https://docs.discord.red/en/stable/cog_guides/audio.html" "Cyan"
    }

    Write-Colour ""
    Write-Colour "  +----------------------------------------------------------+" "Green"
    Write-Colour ""
    Write-Colour "  Thanks for using this installer! If you wanna do me a solid," "White"
    Write-Colour "  please star this on GitHub if you have an account." "White"
    Write-Colour "  https://github.com/BigPattyOG/red-installer/" "Cyan"
    Write-Colour ""
}

# ─────────────────────────────────────────────
# MAIN
# Entry point — runs all checks, collects user
# input, then installs everything in order.
# ─────────────────────────────────────────────
function Main {
    Assert-NotWSL
    Show-Banner

    Write-Colour "  This installer will set up Red-DiscordBot on Windows using" "Yellow"
    Write-Colour "  Chocolatey to manage Python 3.11, Git and build tools." "Yellow"
    Write-Colour ""
    Write-Colour "  You will need:" "White"
    Write-Colour "    - Windows 10 or Windows 11" "White"
    Write-Colour "    - An internet connection" "White"
    Write-Colour "    - ~5 GB free disk space" "White"
    Write-Colour "    - This PowerShell window running as Administrator" "White"
    Write-Colour ""

    # Safety checks — all run before asking the user anything
    Assert-IsAdmin
    Assert-Internet
    Assert-DiskSpace

    Show-Disclaimer

    # Collect all user choices before any installation starts
    Get-InstallOptions

    # Work out total steps based on what the user chose.
    # Base is 5 steps. Chocolatey and audio each add 1 if needed.
    $script:TotalSteps = 5
    if (-not (Test-ChocoInstalled)) { $script:TotalSteps++ }
    if ($script:WantAudio)          { $script:TotalSteps++ }

    # Install everything in order
    if (-not (Test-ChocoInstalled)) {
        Invoke-Step "Installing Chocolatey package manager" {
            Install-Chocolatey
        }
    }

    Invoke-Step "Installing Python 3.11, Git and build tools" {
        Install-Packages
    }

    Invoke-Step "Creating Python virtual environment" {
        New-RedVenv
    }

    Invoke-Step "Installing Red-DiscordBot" {
        Install-Red
    }

    Invoke-Step "Configuring Red instance" {
        Set-RedInstance
    }

    Invoke-Step "Setting bot token and prefix" {
        Set-TokenAndPrefix
    }

    Show-Summary
}

# Run
Main