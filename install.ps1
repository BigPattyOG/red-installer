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
# STEP COUNTER
# Tracks progress through the install steps.
# Script-scoped so all functions can update it.
# ─────────────────────────────────────────────
$script:StepNum    = 0
$script:TotalSteps = 0

# ─────────────────────────────────────────────
# RUN STEP
# Wraps a script block with a step counter and
# success/failure output.
# ─────────────────────────────────────────────
function Invoke-Step {
    param(
        [string]$Message,
        [scriptblock]$Action
    )

    $script:StepNum++
    Write-Host ""
    Write-Host "  " -NoNewline
    Write-Host "[Step $($script:StepNum)/$($script:TotalSteps)]" -ForegroundColor Cyan -NoNewline
    Write-Host " $Message"

    try {
        & $Action
        Write-Host "  " -NoNewline
        Write-Host "[Step $($script:StepNum)/$($script:TotalSteps)]" -ForegroundColor Green -NoNewline
        Write-Host " v " -ForegroundColor Green -NoNewline
        Write-Host "$Message"
    }
    catch {
        Write-Host "  " -NoNewline
        Write-Host "[Step $($script:StepNum)/$($script:TotalSteps)]" -ForegroundColor Red -NoNewline
        Write-Host " x " -ForegroundColor Red -NoNewline
        Write-Host "$Message"
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
        Write-Colour ""
        if ($isWSL) {
            Write-Colour "  +----------------------------------------------------------+" "Yellow"
            Write-Colour "  |   Powershell in WSL is an interesting move, but not      |" "Yellow"
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
# INTERACTIVE SETUP
# Collects all choices from the user before
# any installation begins so the install itself
# can run without interruption.
# Read-Host in PowerShell always reads from the
# console directly so no /dev/tty equivalent
# is needed here unlike the bash script.
# ─────────────────────────────────────────────
function Get-InstallOptions {
    Write-Colour ""
    Write-Colour "  ── Red Instance Setup ──────────────────────────────────" "White"
    Write-Colour ""

    # Instance name
    Write-Colour "  This helps Red know what your bot is on this device" "White"
    Write-Colour "  Example: mybot, redbot, mainbot" "White"
    Write-Colour "  This won't (and can't) change the bot's name on Discord" "White"
    Write-Colour ""
    do {
        $script:InstanceName = Read-Host "  Instance name"
    } while ([string]::IsNullOrWhiteSpace($script:InstanceName))

    # Data path
    $defaultData = "$env:APPDATA\Red-DiscordBot\$($script:InstanceName)"
    Write-Colour ""
    Write-Colour "  Where should Red store its data?" "White"
    Write-Colour "  Press Enter to use the default: $defaultData" "White"
    $inputPath = Read-Host "  Data path"
    $script:DataDir = if ([string]::IsNullOrWhiteSpace($inputPath)) { $defaultData } else { $inputPath }

    # Backend
    Write-Colour ""
    Write-Colour "  How do you want to store data for the bot?" "White"
    Write-Colour "  1) JSON  (simple, no extra setup — recommended)" "White"
    Write-Colour "  2) PostgreSQL  (advanced, requires a running PostgreSQL server)" "White"
    Write-Colour ""
    $backendChoice = Read-Host "  Choice [1/2, default 1]"
    $script:Backend = if ($backendChoice -eq "2") { "postgres" } else { "json" }

    # Audio
    Write-Colour ""
    Write-Colour "  Do you wanna blast your tunes through your bot?" "White"
    Write-Colour "  (Audio support uses Java 17 + Lavalink — see the README for setup)" "White"
    $audioChoice = Read-Host "  Enable audio? [y/N]"
    $script:WantAudio = ($audioChoice -match '^[Yy]$')

    # Bot token
    Write-Colour ""
    Write-Colour "  Next is your bot token, grab it from:" "White"
    Write-Colour "  https://discord.com/developers/applications" "Cyan"
    Write-Colour "  NOTE: It will not be shown as you type." "Red"
    Write-Colour ""
    do {
        # Read-Host -AsSecureString hides input like a password field
        $secureToken = Read-Host "  Bot token" -AsSecureString
        # Convert secure string back to plain text so we can pass it to redbot
        $script:BotToken = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
            [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureToken)
        )
    } while ([string]::IsNullOrWhiteSpace($script:BotToken))

    # Prefix
    Write-Colour ""
    Write-Colour "  Choose a command prefix for your bot (e.g. ! or ? or .)" "White"
    Write-Colour ""
    Write-Colour "  e.g. ?help, !help, etc." "White"
    Write-Colour ""
    Write-Colour "  IT CAN'T BE /. DOESN'T WORK WELL WITH SLASH COMMANDS!" "Red"
    $prefixInput = Read-Host "  Prefix [default: !]"
    $script:BotPrefix = if ([string]::IsNullOrWhiteSpace($prefixInput)) { "!" } else { $prefixInput }

    Write-Colour ""
    Write-Colour "  v Setup details saved. Starting installation..." "Green"
    Write-Colour ""
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
# Runs redbot-setup with all options as flags
# so no interactive prompts are needed.
# mkdir with -Force creates the data dir if it
# doesn't already exist, silently if it does.
# ─────────────────────────────────────────────
function Set-RedInstance {
    $activate = "$env:USERPROFILE\redenv\Scripts\activate.bat"
    New-Item -ItemType Directory -Force -Path $script:DataDir | Out-Null
    $cmd = "$activate && redbot-setup " +
           "--instance-name `"$($script:InstanceName)`" " +
           "--data-path `"$($script:DataDir)`" " +
           "--backend $($script:Backend) " +
           "--no-prompt"
    cmd /c $cmd
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
        Write-Colour "  Audio note:" "Yellow"
        Write-Colour "    Java 17 is installed. To finish audio setup you'll need" "White"
        Write-Colour "    to run a Lavalink server alongside your bot." "White"
        Write-Colour "    Check the README for full instructions:" "White"
        Write-Colour "    https://github.com/BigPattyOG/red-installer#audio-setup" "Cyan"
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

    Write-Colour ""
    $answer = Read-Host "  Ready to begin? [y/N]"
    if ($answer -notmatch '^[Yy]$') {
        Write-Colour ""
        Write-Colour "  Cancelled. No changes were made." "Yellow"
        Write-Colour ""
        exit 0
    }

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