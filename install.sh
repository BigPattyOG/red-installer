#!/usr/bin/env bash

# Below is the Windows detection, someone runs this script on a Windows machine it will tell them to run the install.ps1 instead.
# Doesn't affect WSL

case "$(uname -s 2>/dev/null)" in
    MINGW*|CYGWIN*|MSYS*)
        echo ""
        echo "  +----------------------------------------------------------+"
        echo "  |                Wrong script for Windows!                 |"
        echo "  +----------------------------------------------------------+"
        echo ""
        echo "  Hey there! Looks like you ran this script on Windows."
        echo ""
        echo "  This script is designed for Linux and Unix based"
        echo "  systems (like Ubuntu or MacOS)"
        echo ""
        echo "  However, fear not little one, you can run the Powershell one"
        echo "  instead. Open PowerShell as Administrator and run:"
        echo ""
        echo "    irm https://raw.githubusercontent.com/BigPattyOG/red-installer/main/install.ps1 | iex"
        echo ""
        echo "  This powershell script will work exactly like its shell"
        echo "  counterpart"
        echo ""
        echo "  Thanks for using this installer. If you wanna do me a solid, please"
        echo "  star this on github if you have an account."
        echo ""
        echo "  https://github.com/BigPattyOG/red-installer/"
        echo ""
        exit 1
        ;;
esac

# ─────────────────────────────────────────────
# WSL DETECTION
# When someone runs curl | bash in PowerShell
# it lands in WSL. We check three places:
#   1) WSL_DISTRO_NAME — always set by WSL itself
#   2) /proc/version   — contains "microsoft" on WSL
#   3) /proc/sys/kernel/osrelease — fallback for
#      older WSL builds where /proc/version varies
# We give them a choice — run the ps1 for a
# native Windows install, or open WSL directly
# if they actually want Red inside WSL.
# ─────────────────────────────────────────────
if [[ -n "${WSL_DISTRO_NAME:-}" ]] || \
   grep -qi microsoft /proc/version 2>/dev/null || \
   grep -qi microsoft /proc/sys/kernel/osrelease 2>/dev/null; then
    echo ""
    echo "  +----------------------------------------------------------+"
    echo "  |              Looks like you're using WSL!                |"
    echo "  +----------------------------------------------------------+"
    echo ""
    echo "  From Powershell to WSL, sneaky computer..."
    echo ""
    echo "  While you are technically using a linux system (via WSL)"
    echo "  It could possibly break. So, I provide you with 2 options:"
    echo ""
    echo "  1) Run the Windows friendly install.ps1 script (looks the same as this script)"
    echo "     Open PowerShell as Administrator and run:"
    echo ""
    echo "       irm https://raw.githubusercontent.com/BigPattyOG/red-installer/main/install.ps1 | iex"
    echo ""
    echo "  2) Run your curl command again directly in WSL"
    echo "     Open your WSL terminal directly (e.g. Ubuntu from the"
    echo "     Start Menu) and run this script from there:"
    echo ""
    echo "       curl -fsSL https://raw.githubusercontent.com/BigPattyOG/red-installer/main/install.sh | bash"
    echo ""
    echo "  Either way works great — it's just down to where you want"
    echo "  Red to live!"
    echo ""
    echo "  https://github.com/BigPattyOG/red-installer/"
    echo ""
    exit 1
fi

# Exit on error
set -Eeuo pipefail

# Colours (to make it pretty)
RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
CYAN='\e[36m'
BOLD='\e[1m'
RESET='\e[0m'

cecho() {
    local colour="$1"; shift
    printf "${colour}%s${RESET}\n" "$*"
}

# ASCII Banner
show_banner() {
    clear
    printf "${CYAN}${BOLD}"
    cat <<'EOF'

 ____  ____  ____    __  __ _  ____  ____  __   __    __    ____  ____
(  _ \(  __)(    \  (  )(  ( \/ ___)(_  _)/ _\ (  )  (  )  (  __)(  _ \
 )   / ) _)  ) D (   )( /    /\___ \  )( /    \/ (_/\/ (_/\ ) _)  )   /
(__\_)(____)(____/  (__)\_)__)(____/ (__)\_/\_/\____/\____/(____)(__\_)

            Unofficial Community Installer - By BigPattyOG

EOF
    printf "${RESET}\n"
}

# ─────────────────────────────────────────────
# macOS DETECTION
# uname -s returns "Darwin" on macOS.
# We detect it early and hand off to the
# dedicated macOS installer function.
# ─────────────────────────────────────────────
check_macos() {
    if [[ "$(uname -s)" == "Darwin" ]]; then
        install_macos
        exit 0
    fi
}

# ─────────────────────────────────────────────
# OS DETECTION
# /etc/os-release is a standard file on all
# modern Linux distros containing ID (distro
# name), VERSION_ID (version number) and
# ID_LIKE (parent distro family).
# We source it to get those as shell variables.
# ─────────────────────────────────────────────
detect_os() {
    if [[ ! -f /etc/os-release ]]; then
        cecho "$RED" "  Cannot detect OS — /etc/os-release not found."
        cecho "$RED" "  Sorry, you'll have to do this all manually:"
        echo   "  https://docs.discord.red/en/stable/install_guides/"
        exit 1
    fi

    # shellcheck disable=SC1091
    source /etc/os-release

    OS_ID="${ID:-unknown}"
    OS_VERSION="${VERSION_ID:-unknown}"
    OS_ID_LIKE="${ID_LIKE:-}"
    OS_NAME="${PRETTY_NAME:-$OS_ID}"
}

# ─────────────────────────────────────────────
# DISK SPACE CHECK
# Makes sure there's at least 2 GB free before
# we start downloading and installing things.
# df outputs disk usage — awk grabs the 4th
# column (available KB) from the second row.
# ─────────────────────────────────────────────
check_disk_space() {
    local required_kb=2097152
    local available_kb
    available_kb=$(df / | awk 'NR==2 {print $4}')

    if [[ "$available_kb" -lt "$required_kb" ]]; then
        echo
        cecho "$RED" "  Oops! Space you not have, mmm"
        cecho "$RED" "  Required: 2 GB  |  Available: $(( available_kb / 1024 )) MB"
        cecho "$RED" "  Feel free to run this script again when you have the space"
        echo
        exit 1
    fi
}

# ─────────────────────────────────────────────
# INTERNET CHECK
# Tries to reach github.com silently before
# doing anything. --max-time 5 means give up
# after 5 seconds if there's no response.
# ─────────────────────────────────────────────
check_internet() {
    if ! curl -s --max-time 5 https://github.com > /dev/null 2>&1; then
        echo
        cecho "$RED" "  Installing things from the internet works best when you have internet"
        cecho "$RED" "  Shame I didn't add a dino game for you to play..."
        echo
        exit 1
    fi
}

# ─────────────────────────────────────────────
# REQUIRE SUDO
# Gets sudo credentials upfront so we don't
# get a password prompt mid-install.
# sudo -n = non-interactive (won't prompt)
# if that fails, we prompt once here instead.
# ─────────────────────────────────────────────
require_sudo() {
    if ! sudo -n true 2>/dev/null; then
        cecho "$YELLOW" "  Calling all superusers, we need your password to continue"
        echo
        sudo true </dev/tty
    fi
}

# ─────────────────────────────────────────────
# SPINNER
# Shows an animation while a background process
# runs. kill -0 checks if the process is still
# alive without actually killing it.
# tput civis/cnorm hides and shows the cursor.
# ─────────────────────────────────────────────
CURRENT_STEP=""
LOG_FILE="$(mktemp /tmp/redbot_install.XXXXXX.log)"
STEP_NUM=0
TOTAL_STEPS=0

spinner() {
    local pid="$1"
    local delay=0.08
    local spin='|/-\'
    local i=0
    tput civis 2>/dev/null || true
    while kill -0 "$pid" 2>/dev/null; do
        i=$(( (i + 1) % 4 ))
        printf "\r    ${CYAN}[%s]${RESET} %s" "${spin:$i:1}" "$CURRENT_STEP"
        sleep "$delay"
    done
    tput cnorm 2>/dev/null || true
}

# ─────────────────────────────────────────────
# PROGRESS BAR
# Renders a filled/empty block bar that grows
# as each step completes.  Called after every
# successful run_step so the user can see at
# a glance how far along the install is.
# ─────────────────────────────────────────────
show_progress_bar() {
    local current="$1"
    local total="$2"
    [[ "$total" -le 0 ]] && return
    local bar_width=30
    local filled=$(( current * bar_width / total ))
    local empty
    [[ "$current" -eq "$total" ]] && filled=$bar_width
    empty=$(( bar_width - filled ))
    local bar="" i
    for (( i=0; i<filled; i++ )); do bar+="█"; done
    for (( i=0; i<empty; i++ )); do bar+="░"; done
    # Omit trailing newline so the next step's \r can overwrite this bar line.
    # Only the final step adds \n to leave a clean terminal state.
    if [[ "$current" -eq "$total" ]]; then
        printf "  ${CYAN}[%s]${RESET} %d of %d steps complete\n" "$bar" "$current" "$total"
    else
        printf "  ${CYAN}[%s]${RESET} %d of %d steps complete" "$bar" "$current" "$total"
    fi
}

# ─────────────────────────────────────────────
# RUN STEP
# Wraps any function with a step counter,
# spinner, and ✓ or ✗ result.
# $@ = all arguments after the message.
# $? = the exit code of the last command.
# ─────────────────────────────────────────────
run_step() {
    local message="$1"; shift
    STEP_NUM=$(( STEP_NUM + 1 ))
    CURRENT_STEP="$message"
    # Step 1 starts on a fresh line; steps 2+ overwrite the progress bar with \r.
    # \e[K clears any leftover characters from the bar to the end of the line.
    if [[ "$STEP_NUM" -eq 1 ]]; then
        printf "\n  ${BOLD}[Step %d/%d]${RESET} %s\e[K" "$STEP_NUM" "$TOTAL_STEPS" "$message"
    else
        printf "\r  ${BOLD}[Step %d/%d]${RESET} %s\e[K" "$STEP_NUM" "$TOTAL_STEPS" "$message"
    fi

    ( "$@" ) >"$LOG_FILE" 2>&1 &
    local pid=$!
    spinner "$pid"

    set +e; wait "$pid"; local rc=$?; set -e

    if [[ "$rc" -eq 0 ]]; then
        printf "\r  ${GREEN}${BOLD}[Step %d/%d]${RESET} ${GREEN}✓${RESET} %s\e[K\n" \
            "$STEP_NUM" "$TOTAL_STEPS" "$message"
        show_progress_bar "$STEP_NUM" "$TOTAL_STEPS"
    else
        printf "\r  ${RED}${BOLD}[Step %d/%d]${RESET} ${RED}✗${RESET} %s\e[K\n" \
            "$STEP_NUM" "$TOTAL_STEPS" "$message"
        echo
        cecho "$RED" "  Oopsie, something went wrong during: '${message}'"
        cecho "$RED" "  Full error log: ${LOG_FILE}"
        echo
        echo "  ---- error details ----"
        sed 's/^/  /' "$LOG_FILE"
        echo "  -----------------------"
        echo
        exit "$rc"
    fi
}

# ─────────────────────────────────────────────
# PROMPT CONTINUE ANYWAY
# Used when a distro is known but not fully
# supported — gives the user a choice.
# ─────────────────────────────────────────────
prompt_continue_anyway() {
    printf "${YELLOW}  Wanna proceed? [y/N]: ${RESET}"
    read -r answer </dev/tty
    if [[ ! "$answer" =~ ^[Yy]$ ]]; then
        cecho "$YELLOW" "  Cancelled."
        exit 0
    fi
}

# ─────────────────────────────────────────────
# UNSUPPORTED OS
# ─────────────────────────────────────────────
unsupported() {
    echo
    cecho "$RED" "  (${OS_NAME}) isn't supported by this installer just yet."
    echo   "  For now, you'll need to do this manually via"
    echo   "  https://docs.discord.red/en/stable/install_guides/"
    echo   ""
    echo   "  Let me know what OS you're using and I'll add support as soon as possible"
    echo   "  https://github.com/BigPattyOG/red-installer/issues"
    echo
    exit 1
}

# ─────────────────────────────────────────────
# INTERACTIVE RED SETUP
# Collects all choices from the user before
# any installation begins, so the install
# itself can run without interruption.
# Every read uses </dev/tty so it always reads
# from the terminal even when stdin is a pipe.
# printf is used separately from read because
# -p and </dev/tty conflict with each other.
# ─────────────────────────────────────────────
interactive_red_setup() {
    echo
    cecho "$BOLD" "  ── Red Instance Setup ──────────────────────────────────"
    echo

    # Instance name
    echo   "  This helps Red know what your bot is on this device"
    echo   "  Example: mybot, redbot, mainbot"
    echo   "  This won't (and can't) change the bot's name on Discord"
    echo
    while true; do
        printf "  Instance name: "
        read -r INSTANCE_NAME </dev/tty
        [[ -n "${INSTANCE_NAME// }" ]] && break
        cecho "$RED" "  Cannot be empty."
    done

    # Data path
    local default_data="${HOME}/.local/share/Red-DiscordBot/${INSTANCE_NAME}"
    echo
    echo   "  Where should Red store its data?"
    echo   "  Press Enter to use the default: ${default_data}"
    printf "  Data path: "
    read -r DATA_DIR </dev/tty
    DATA_DIR="${DATA_DIR:-$default_data}"

    # Backend
    echo
    echo   "  How do you want to store data for the bot?"
    echo   "  1) JSON  (simple, no extra setup — recommended)"
    echo   "  2) PostgreSQL  (advanced, requires a running PostgreSQL server)"
    echo
    printf "  Choice [1/2, default 1]: "
    read -r backend_choice </dev/tty
    case "${backend_choice:-1}" in
        2) BACKEND="postgres" ;;
        *) BACKEND="json"     ;;
    esac

    # Audio
    echo
    echo   "  Do you wanna blast your tunes through your bot?"
    echo   "  (Audio support uses Java 17 + Lavalink — see the README for setup)"
    printf "  Enable audio? [y/N]: "
    read -r audio_choice </dev/tty
    WANT_AUDIO=false
    [[ "$audio_choice" =~ ^[Yy]$ ]] && WANT_AUDIO=true

    # Bot token
    echo
    echo   "  Next is your bot token, grab it from:"
    echo   "  https://discord.com/developers/applications"
    cecho  "$RED" "  NOTE: It will not be shown as you type."
    echo
    while true; do
        printf "  Bot token: "
        read -r -s BOT_TOKEN </dev/tty
        echo
        [[ -n "${BOT_TOKEN// }" ]] && break
        cecho "$RED" "  With no token, you have no bot"
    done

    # Prefix
    echo
    echo   "  Choose a command prefix for your bot (e.g. ! or ? or .)"
    echo
    echo   "  e.g. ?help, !help, etc."
    echo
    cecho  "$RED" "  IT CAN'T BE /. DOESN'T WORK WELL WITH SLASH COMMANDS!"
    printf "  Prefix [default: !]: "
    read -r BOT_PREFIX </dev/tty
    BOT_PREFIX="${BOT_PREFIX:-!}"

    # Systemd (Linux only)
    WANT_SYSTEMD=false
    if command -v systemctl &>/dev/null; then
        echo
        echo   "  Want this bot to always be on? We can set it up as a service"
        echo   "  so it starts automatically whenever this machine boots up."
        printf "  Set up service? [Y/n]: "
        read -r svc_choice </dev/tty
        [[ ! "$svc_choice" =~ ^[Nn]$ ]] && WANT_SYSTEMD=true
    fi

    export INSTANCE_NAME DATA_DIR BACKEND BOT_TOKEN BOT_PREFIX WANT_AUDIO WANT_SYSTEMD

    echo
    cecho "$GREEN" "  ✓ Setup details saved. Starting installation..."
    echo
}

# ─────────────────────────────────────────────
# SHARED: CREATE VENV
# A virtual environment is an isolated Python
# installation just for Red, so its packages
# don't conflict with system Python packages.
# $1 = the python binary to use (e.g. python3.11)
# ─────────────────────────────────────────────
create_venv() {
    local python_bin="$1"
    if [[ ! -d "${HOME}/redenv" ]]; then
        "$python_bin" -m venv "${HOME}/redenv"
    fi
}

# ─────────────────────────────────────────────
# SHARED: INSTALL RED INTO VENV
# Activates the venv then installs Red via pip.
# -U means upgrade if already installed.
# If the user chose PostgreSQL as the backend
# we install with the [postgres] extra so the
# required database driver is included.
# ─────────────────────────────────────────────
install_red_into_venv() {
    # shellcheck disable=SC1091
    source "${HOME}/redenv/bin/activate"
    python -m pip install -U pip wheel
    if [[ "$BACKEND" == "postgres" ]]; then
        python -m pip install -U "Red-DiscordBot[postgres]"
    else
        python -m pip install -U Red-DiscordBot
    fi
}

# ─────────────────────────────────────────────
# SHARED: CONFIGURE RED INSTANCE
# Runs redbot-setup with all options as flags
# so no interactive prompts are needed.
# ─────────────────────────────────────────────
configure_red_instance() {
    # shellcheck disable=SC1091
    source "${HOME}/redenv/bin/activate"
    mkdir -p "$DATA_DIR"
    redbot-setup \
        --instance-name "$INSTANCE_NAME" \
        --data-path "$DATA_DIR" \
        --backend "$BACKEND" \
        --no-prompt
}

# ─────────────────────────────────────────────
# SHARED: SET TOKEN AND PREFIX
# Uses redbot --edit to save the bot token and
# prefix into this instance's config file.
# --no-prompt means it won't ask for anything.
# ─────────────────────────────────────────────
set_token_and_prefix() {
    # shellcheck disable=SC1091
    source "${HOME}/redenv/bin/activate"
    redbot "$INSTANCE_NAME" \
        --edit \
        --token "$BOT_TOKEN" \
        --prefix "$BOT_PREFIX" \
        --no-prompt
}

# ─────────────────────────────────────────────
# SHARED: CREATE SYSTEMD SERVICE
# Creates a systemd template service file so
# Red starts automatically on boot.
# Only runs if the user opted in.
# ─────────────────────────────────────────────
create_systemd_service() {
    if [[ "$WANT_SYSTEMD" != true ]]; then return 0; fi

    sudo tee "/etc/systemd/system/red@.service" >/dev/null <<EOF
[Unit]
Description=%I redbot
After=multi-user.target network-online.target
Wants=network-online.target

[Service]
Type=idle
User=${USER}
Group=${USER}
WorkingDirectory=${HOME}
ExecStart=${HOME}/redenv/bin/python -O -m redbot %I --no-prompt
Restart=on-abnormal
RestartSec=15
TimeoutStopSec=10

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable "red@${INSTANCE_NAME}"
    sudo systemctl start  "red@${INSTANCE_NAME}"
}

# ─────────────────────────────────────────────
# SHARED: FINAL SUMMARY
# Prints a clean summary of what was installed
# and how to manage the bot going forward.
# ─────────────────────────────────────────────
show_summary() {
    echo
    printf "${GREEN}${BOLD}"
    cat <<EOF
  +----------------------------------------------------------+
  |                 Installation Complete!                   |
  +----------------------------------------------------------+

  Instance   : ${INSTANCE_NAME}
  Data path  : ${DATA_DIR}
  Backend    : ${BACKEND}
  Prefix     : ${BOT_PREFIX}
  Venv       : ${HOME}/redenv

EOF

    if [[ "$WANT_SYSTEMD" == true ]]; then
        cat <<EOF
  Service    : red@${INSTANCE_NAME}

  Useful commands:
    sudo systemctl status  red@${INSTANCE_NAME}
    sudo journalctl -eu    red@${INSTANCE_NAME} -f
    sudo systemctl restart red@${INSTANCE_NAME}
    sudo systemctl stop    red@${INSTANCE_NAME}
EOF
    else
        cat <<EOF
  To start Red manually:
    source ~/redenv/bin/activate
    redbot ${INSTANCE_NAME}
EOF
    fi

    if [[ "$WANT_AUDIO" == true ]]; then
        cat <<EOF

  Audio note:
    Java is installed. To finish audio setup you'll need to run
    a Lavalink server. Check the README for instructions:
    https://github.com/BigPattyOG/red-installer#audio-setup
EOF
    fi

    cat <<EOF

  Thanks for using this installer! If you wanna do me a solid,
  please star this on GitHub if you have an account.
  https://github.com/BigPattyOG/red-installer/

  +----------------------------------------------------------+
EOF
    printf "${RESET}\n"
}

# ═══════════════════════════════════════════════════════════
# OS-SPECIFIC INSTALLERS
# ═══════════════════════════════════════════════════════════

# ─────────────────────────────────────────────
# UBUNTU 24.04 LTS
# https://docs.discord.red/en/stable/install_guides/ubuntu-2404.html
# ─────────────────────────────────────────────
install_ubuntu_2404() {
    TOTAL_STEPS=6
    [[ "$WANT_SYSTEMD" == true ]] && TOTAL_STEPS=7

    run_step "Updating package lists" \
        sudo apt-get update -q

    run_step "Adding deadsnakes PPA for Python 3.11" \
        bash -c "sudo apt-get install -y -q software-properties-common && \
                 sudo add-apt-repository -y ppa:deadsnakes/ppa && \
                 sudo apt-get update -q"

    run_step "Installing system packages" \
        sudo apt-get install -y -q \
            python3.11 python3.11-dev python3.11-venv \
            git build-essential nano openjdk-17-jre-headless

    run_step "Creating Python virtual environment" \
        create_venv python3.11

    run_step "Installing Red-DiscordBot" \
        install_red_into_venv

    run_step "Configuring Red instance" \
        bash -c "$(declare -f configure_red_instance); \
                 INSTANCE_NAME='$INSTANCE_NAME' DATA_DIR='$DATA_DIR' \
                 BACKEND='$BACKEND' configure_red_instance"

    run_step "Setting bot token and prefix" \
        bash -c "$(declare -f set_token_and_prefix); \
                 INSTANCE_NAME='$INSTANCE_NAME' BOT_TOKEN='$BOT_TOKEN' \
                 BOT_PREFIX='$BOT_PREFIX' set_token_and_prefix"

    [[ "$WANT_SYSTEMD" == true ]] && \
        run_step "Setting up systemd service" create_systemd_service

    show_summary
}

# ─────────────────────────────────────────────
# UBUNTU 22.04 LTS
# https://docs.discord.red/en/stable/install_guides/ubuntu-2204.html
# ─────────────────────────────────────────────
install_ubuntu_2204() {
    TOTAL_STEPS=5
    [[ "$WANT_SYSTEMD" == true ]] && TOTAL_STEPS=6

    run_step "Updating package lists" \
        sudo apt-get update -q

    run_step "Installing system packages" \
        sudo apt-get install -y -q \
            python3.10 python3.10-dev python3.10-venv \
            git build-essential nano openjdk-17-jre-headless

    run_step "Creating Python virtual environment" \
        create_venv python3.10

    run_step "Installing Red-DiscordBot" \
        install_red_into_venv

    run_step "Configuring Red instance" \
        bash -c "$(declare -f configure_red_instance); \
                 INSTANCE_NAME='$INSTANCE_NAME' DATA_DIR='$DATA_DIR' \
                 BACKEND='$BACKEND' configure_red_instance"

    run_step "Setting bot token and prefix" \
        bash -c "$(declare -f set_token_and_prefix); \
                 INSTANCE_NAME='$INSTANCE_NAME' BOT_TOKEN='$BOT_TOKEN' \
                 BOT_PREFIX='$BOT_PREFIX' set_token_and_prefix"

    [[ "$WANT_SYSTEMD" == true ]] && \
        run_step "Setting up systemd service" create_systemd_service

    show_summary
}

# ─────────────────────────────────────────────
# UBUNTU NON-LTS
# https://docs.discord.red/en/stable/install_guides/ubuntu-non-lts.html
# ─────────────────────────────────────────────
install_ubuntu_nonlts() {
    echo
    cecho "$RED"    "  Ubuntu ${OS_VERSION} (non-LTS) is not supported by Red."
    cecho "$RED"    "  The official docs confirm Python 3.11 isn't available"
    cecho "$RED"    "  on non-LTS releases right now."
    echo
    cecho "$YELLOW" "  We'd strongly recommend upgrading to Ubuntu 24.04 LTS."
    cecho "$YELLOW" "  Install guide: https://docs.discord.red/en/stable/install_guides/ubuntu-2404.html"
    echo
    exit 1
}

# ─────────────────────────────────────────────
# DEBIAN 12 BOOKWORM
# https://docs.discord.red/en/stable/install_guides/debian-12.html
# ─────────────────────────────────────────────
install_debian() {
    TOTAL_STEPS=5
    [[ "$WANT_SYSTEMD" == true ]] && TOTAL_STEPS=6

    run_step "Updating package lists" \
        sudo apt-get update -q

    run_step "Installing system packages" \
        sudo apt-get install -y -q \
            python3 python3-dev python3-venv \
            git build-essential nano openjdk-17-jre-headless

    run_step "Creating Python virtual environment" \
        create_venv python3.11

    run_step "Installing Red-DiscordBot" \
        install_red_into_venv

    run_step "Configuring Red instance" \
        bash -c "$(declare -f configure_red_instance); \
                 INSTANCE_NAME='$INSTANCE_NAME' DATA_DIR='$DATA_DIR' \
                 BACKEND='$BACKEND' configure_red_instance"

    run_step "Setting bot token and prefix" \
        bash -c "$(declare -f set_token_and_prefix); \
                 INSTANCE_NAME='$INSTANCE_NAME' BOT_TOKEN='$BOT_TOKEN' \
                 BOT_PREFIX='$BOT_PREFIX' set_token_and_prefix"

    [[ "$WANT_SYSTEMD" == true ]] && \
        run_step "Setting up systemd service" create_systemd_service

    show_summary
}

# ─────────────────────────────────────────────
# RASPBERRY PI OS 12 (LEGACY BOOKWORM)
# https://docs.discord.red/en/stable/install_guides/raspberry-pi-os-12.html
# ─────────────────────────────────────────────
install_raspbian() {
    TOTAL_STEPS=5
    [[ "$WANT_SYSTEMD" == true ]] && TOTAL_STEPS=6

    run_step "Updating package lists" \
        sudo apt-get update -q

    run_step "Installing system packages" \
        sudo apt-get install -y -q \
            python3 python3-dev python3-venv \
            git build-essential nano openjdk-17-jre-headless

    run_step "Creating Python virtual environment" \
        create_venv python3.11

    run_step "Installing Red-DiscordBot" \
        install_red_into_venv

    run_step "Configuring Red instance" \
        bash -c "$(declare -f configure_red_instance); \
                 INSTANCE_NAME='$INSTANCE_NAME' DATA_DIR='$DATA_DIR' \
                 BACKEND='$BACKEND' configure_red_instance"

    run_step "Setting bot token and prefix" \
        bash -c "$(declare -f set_token_and_prefix); \
                 INSTANCE_NAME='$INSTANCE_NAME' BOT_TOKEN='$BOT_TOKEN' \
                 BOT_PREFIX='$BOT_PREFIX' set_token_and_prefix"

    [[ "$WANT_SYSTEMD" == true ]] && \
        run_step "Setting up systemd service" create_systemd_service

    show_summary
}

# ─────────────────────────────────────────────
# RHEL 8 FAMILY
# Covers: RHEL 8, Alma 8, Oracle 8, Rocky 8
# https://docs.discord.red/en/stable/install_guides/rhel-8.html
# ─────────────────────────────────────────────
install_rhel8() {
    TOTAL_STEPS=6
    [[ "$WANT_SYSTEMD" == true ]] && TOTAL_STEPS=7

    run_step "Updating system packages" \
        sudo dnf -y update

    run_step "Installing development tools group" \
        sudo dnf -y group install development

    run_step "Installing Python 3.11, Git, Java 17 and nano" \
        sudo dnf -y install \
            python3.11 python3.11-devel \
            git java-17-openjdk-headless nano

    run_step "Setting Java 17 as default" \
        sudo alternatives --set java "java-17-openjdk.$(uname -i)"

    run_step "Creating Python virtual environment" \
        create_venv python3.11

    run_step "Installing Red-DiscordBot" \
        install_red_into_venv

    run_step "Configuring Red instance" \
        bash -c "$(declare -f configure_red_instance); \
                 INSTANCE_NAME='$INSTANCE_NAME' DATA_DIR='$DATA_DIR' \
                 BACKEND='$BACKEND' configure_red_instance"

    run_step "Setting bot token and prefix" \
        bash -c "$(declare -f set_token_and_prefix); \
                 INSTANCE_NAME='$INSTANCE_NAME' BOT_TOKEN='$BOT_TOKEN' \
                 BOT_PREFIX='$BOT_PREFIX' set_token_and_prefix"

    [[ "$WANT_SYSTEMD" == true ]] && \
        run_step "Setting up systemd service" create_systemd_service

    show_summary
}

# ─────────────────────────────────────────────
# RHEL 9 FAMILY
# Covers: RHEL 9, Alma 9, Oracle 9, Rocky 9,
#         CentOS Stream 9
# https://docs.discord.red/en/stable/install_guides/rhel-9.html
# ─────────────────────────────────────────────
install_rhel9() {
    TOTAL_STEPS=4
    [[ "$WANT_SYSTEMD" == true ]] && TOTAL_STEPS=5

    run_step "Installing system packages" \
        sudo dnf -y install \
            python3.11 python3.11-devel \
            git java-17-openjdk-headless @development nano

    run_step "Creating Python virtual environment" \
        create_venv python3.11

    run_step "Installing Red-DiscordBot" \
        install_red_into_venv

    run_step "Configuring Red instance" \
        bash -c "$(declare -f configure_red_instance); \
                 INSTANCE_NAME='$INSTANCE_NAME' DATA_DIR='$DATA_DIR' \
                 BACKEND='$BACKEND' configure_red_instance"

    run_step "Setting bot token and prefix" \
        bash -c "$(declare -f set_token_and_prefix); \
                 INSTANCE_NAME='$INSTANCE_NAME' BOT_TOKEN='$BOT_TOKEN' \
                 BOT_PREFIX='$BOT_PREFIX' set_token_and_prefix"

    [[ "$WANT_SYSTEMD" == true ]] && \
        run_step "Setting up systemd service" create_systemd_service

    show_summary
}

# ─────────────────────────────────────────────
# FEDORA
# https://docs.discord.red/en/stable/install_guides/fedora.html
# ─────────────────────────────────────────────
install_fedora() {
    TOTAL_STEPS=4
    [[ "$WANT_AUDIO" == true ]]   && TOTAL_STEPS=$(( TOTAL_STEPS + 1 ))
    [[ "$WANT_SYSTEMD" == true ]] && TOTAL_STEPS=$(( TOTAL_STEPS + 1 ))

    run_step "Installing system packages" \
        sudo dnf -y install \
            python3.11 python3.11-devel \
            git @development-tools nano

    if [[ "$WANT_AUDIO" == true ]]; then
        run_step "Installing Java 17 via Adoptium Temurin" \
            bash -c "sudo dnf -y install adoptium-temurin-java-repository && \
                     sudo dnf config-manager setopt adoptium-temurin-java-repository.enabled=1 && \
                     sudo dnf -y install temurin-17-jre"
    fi

    run_step "Creating Python virtual environment" \
        create_venv python3.11

    run_step "Installing Red-DiscordBot" \
        install_red_into_venv

    run_step "Configuring Red instance" \
        bash -c "$(declare -f configure_red_instance); \
                 INSTANCE_NAME='$INSTANCE_NAME' DATA_DIR='$DATA_DIR' \
                 BACKEND='$BACKEND' configure_red_instance"

    run_step "Setting bot token and prefix" \
        bash -c "$(declare -f set_token_and_prefix); \
                 INSTANCE_NAME='$INSTANCE_NAME' BOT_TOKEN='$BOT_TOKEN' \
                 BOT_PREFIX='$BOT_PREFIX' set_token_and_prefix"

    [[ "$WANT_SYSTEMD" == true ]] && \
        run_step "Setting up systemd service" create_systemd_service

    show_summary
}

# ─────────────────────────────────────────────
# AMAZON LINUX 2023
# https://docs.discord.red/en/stable/install_guides/amazon-linux-2023.html
# ─────────────────────────────────────────────
install_amazon() {
    TOTAL_STEPS=4
    [[ "$WANT_SYSTEMD" == true ]] && TOTAL_STEPS=5

    run_step "Installing system packages" \
        sudo dnf -y install \
            python3.11 python3.11-devel \
            git java-17-amazon-corretto-headless @development nano

    run_step "Creating Python virtual environment" \
        create_venv python3.11

    run_step "Installing Red-DiscordBot" \
        install_red_into_venv

    run_step "Configuring Red instance" \
        bash -c "$(declare -f configure_red_instance); \
                 INSTANCE_NAME='$INSTANCE_NAME' DATA_DIR='$DATA_DIR' \
                 BACKEND='$BACKEND' configure_red_instance"

    run_step "Setting bot token and prefix" \
        bash -c "$(declare -f set_token_and_prefix); \
                 INSTANCE_NAME='$INSTANCE_NAME' BOT_TOKEN='$BOT_TOKEN' \
                 BOT_PREFIX='$BOT_PREFIX' set_token_and_prefix"

    [[ "$WANT_SYSTEMD" == true ]] && \
        run_step "Setting up systemd service" create_systemd_service

    show_summary
}

# ─────────────────────────────────────────────
# openSUSE LEAP 15.6+ AND TUMBLEWEED
# https://docs.discord.red/en/stable/install_guides/opensuse-leap-15.html
# https://docs.discord.red/en/stable/install_guides/opensuse-tumbleweed.html
# ─────────────────────────────────────────────
install_opensuse() {
    TOTAL_STEPS=4
    [[ "$WANT_SYSTEMD" == true ]] && TOTAL_STEPS=5

    run_step "Installing system packages" \
        bash -c "sudo zypper -n install \
                     python311 python311-devel \
                     git-core java-17-openjdk-headless nano && \
                 sudo zypper -n install -t pattern devel_basis"

    run_step "Creating Python virtual environment" \
        create_venv python3.11

    run_step "Installing Red-DiscordBot" \
        install_red_into_venv

    run_step "Configuring Red instance" \
        bash -c "$(declare -f configure_red_instance); \
                 INSTANCE_NAME='$INSTANCE_NAME' DATA_DIR='$DATA_DIR' \
                 BACKEND='$BACKEND' configure_red_instance"

    run_step "Setting bot token and prefix" \
        bash -c "$(declare -f set_token_and_prefix); \
                 INSTANCE_NAME='$INSTANCE_NAME' BOT_TOKEN='$BOT_TOKEN' \
                 BOT_PREFIX='$BOT_PREFIX' set_token_and_prefix"

    [[ "$WANT_SYSTEMD" == true ]] && \
        run_step "Setting up systemd service" create_systemd_service

    show_summary
}

install_opensuse_leap()       { install_opensuse; }
install_opensuse_tumbleweed() { install_opensuse; }

# ─────────────────────────────────────────────
# ARCH LINUX
# https://docs.discord.red/en/stable/install_guides/arch.html
# ─────────────────────────────────────────────
install_arch() {
    TOTAL_STEPS=5
    [[ "$WANT_SYSTEMD" == true ]] && TOTAL_STEPS=6

    local pkgs="git base-devel nano"
    [[ "$WANT_AUDIO" == true ]] && pkgs="$pkgs jre17-openjdk-headless"
    run_step "Installing system packages" \
        sudo pacman -Syu --noconfirm $pkgs

    run_step "Installing Python 3.11 from AUR (this takes a few minutes)" \
        bash -c "git clone https://aur.archlinux.org/python311.git /tmp/python311 && \
                 cd /tmp/python311 && \
                 makepkg -sicL --noconfirm && \
                 cd - && \
                 rm -rf /tmp/python311"

    run_step "Creating Python virtual environment" \
        create_venv python3.11

    run_step "Installing Red-DiscordBot" \
        install_red_into_venv

    run_step "Configuring Red instance" \
        bash -c "$(declare -f configure_red_instance); \
                 INSTANCE_NAME='$INSTANCE_NAME' DATA_DIR='$DATA_DIR' \
                 BACKEND='$BACKEND' configure_red_instance"

    run_step "Setting bot token and prefix" \
        bash -c "$(declare -f set_token_and_prefix); \
                 INSTANCE_NAME='$INSTANCE_NAME' BOT_TOKEN='$BOT_TOKEN' \
                 BOT_PREFIX='$BOT_PREFIX' set_token_and_prefix"

    [[ "$WANT_SYSTEMD" == true ]] && \
        run_step "Setting up systemd service" create_systemd_service

    show_summary
}

# ─────────────────────────────────────────────
# macOS
# https://docs.discord.red/en/stable/install_guides/mac.html
# ─────────────────────────────────────────────
install_macos() {
    WANT_SYSTEMD=false

    show_banner

    echo
    cecho "$CYAN"  "  Detected OS: macOS"
    echo
    cecho "$CYAN"  "  This installer will:"
    echo   "    • Install Homebrew (if not already installed)"
    echo   "    • Install Python 3.11, git and dependencies via Homebrew"
    echo   "    • Create a Python virtual environment"
    echo   "    • Install Red-DiscordBot"
    echo   "    • Walk you through instance setup"
    echo
    cecho "$YELLOW" "  ⏱  Estimated time: 5-15 minutes depending on your connection."
    echo

    printf "${BOLD}  Ready to begin? [y/N]: ${RESET}"
    read -r answer </dev/tty
    if [[ ! "$answer" =~ ^[Yy]$ ]]; then
        cecho "$YELLOW" "  Cancelled. No changes were made."
        exit 0
    fi

    check_disk_space
    check_internet
    interactive_red_setup

    TOTAL_STEPS=4

    if ! command -v brew &>/dev/null; then
        TOTAL_STEPS=$(( TOTAL_STEPS + 1 ))
        run_step "Installing Homebrew" \
            bash -c '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'

        local brew_loc
        brew_loc="$([ "$(/usr/bin/uname -m)" = "arm64" ] \
            && echo /opt/homebrew \
            || echo /usr/local)/bin/brew"
        eval "$("$brew_loc" shellenv)"

        printf '\neval "$(%s shellenv)"\n' "$brew_loc" >> \
            "$([ -n "${ZSH_VERSION:-}" ] && echo ~/.zprofile \
               || ([ -f ~/.bash_profile ] && echo ~/.bash_profile || echo ~/.profile))"
    fi

    local brew_pkgs="python@3.11 git"
    [[ "$WANT_AUDIO" == true ]] && brew_pkgs="$brew_pkgs temurin@17"
    run_step "Installing Python 3.11, git${WANT_AUDIO:+ and Java 17} via Homebrew" \
        brew install $brew_pkgs

    local python_path
    python_path="$(brew --prefix)/opt/python@3.11/bin"
    export PATH="${python_path}:$PATH"
    printf '\nexport PATH="%s:$PATH"\n' "$python_path" >> \
        "$([ -n "${ZSH_VERSION:-}" ] && echo ~/.zprofile \
           || ([ -f ~/.bash_profile ] && echo ~/.bash_profile || echo ~/.profile))"

    run_step "Creating Python virtual environment" \
        create_venv python3.11

    run_step "Installing Red-DiscordBot" \
        install_red_into_venv

    run_step "Configuring Red instance" \
        bash -c "$(declare -f configure_red_instance); \
                 INSTANCE_NAME='$INSTANCE_NAME' DATA_DIR='$DATA_DIR' \
                 BACKEND='$BACKEND' configure_red_instance"

    run_step "Setting bot token and prefix" \
        bash -c "$(declare -f set_token_and_prefix); \
                 INSTANCE_NAME='$INSTANCE_NAME' BOT_TOKEN='$BOT_TOKEN' \
                 BOT_PREFIX='$BOT_PREFIX' set_token_and_prefix"

    show_summary

    echo
    cecho "$YELLOW" "  macOS note: To start Red manually:"
    echo   "    source ~/redenv/bin/activate"
    echo   "    redbot ${INSTANCE_NAME}"
    echo
}

# ─────────────────────────────────────────────
# OS ROUTER
# ─────────────────────────────────────────────
route_os() {
    case "$OS_ID" in
        ubuntu)
            case "$OS_VERSION" in
                22.04) install_ubuntu_2204   ;;
                24.04) install_ubuntu_2404   ;;
                *)     install_ubuntu_nonlts ;;
            esac
            ;;
        debian)              install_debian               ;;
        raspbian)            install_raspbian             ;;
        almalinux|rhel|ol)
            case "$OS_VERSION" in
                8*) install_rhel8 ;;
                9*) install_rhel9 ;;
                *)  unsupported   ;;
            esac
            ;;
        rocky)
            case "$OS_VERSION" in
                8*) install_rhel8 ;;
                9*) install_rhel9 ;;
                *)  unsupported   ;;
            esac
            ;;
        centos)              install_rhel9               ;;
        fedora)              install_fedora              ;;
        amzn)                install_amazon              ;;
        opensuse-leap)       install_opensuse_leap       ;;
        opensuse-tumbleweed) install_opensuse_tumbleweed ;;
        arch)                install_arch                ;;
        *)
            if   [[ "$OS_ID_LIKE" == *"debian"* ]] || [[ "$OS_ID_LIKE" == *"ubuntu"* ]]; then
                cecho "$YELLOW" "  Detected Debian-like distro: ${OS_NAME}"
                cecho "$YELLOW" "  Attempting Debian install method..."
                install_debian
            elif [[ "$OS_ID_LIKE" == *"rhel"* ]] || [[ "$OS_ID_LIKE" == *"fedora"* ]]; then
                cecho "$YELLOW" "  Detected RHEL-like distro: ${OS_NAME}"
                cecho "$YELLOW" "  Attempting RHEL 9 install method..."
                install_rhel9
            elif [[ "$OS_ID_LIKE" == *"arch"* ]]; then
                cecho "$YELLOW" "  Detected Arch-like distro: ${OS_NAME}"
                install_arch
            elif [[ "$OS_ID_LIKE" == *"suse"* ]]; then
                cecho "$YELLOW" "  Detected openSUSE-like distro: ${OS_NAME}"
                install_opensuse
            else
                unsupported
            fi
            ;;
    esac
}

# ═══════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════
main() {
    show_banner
    check_macos

    detect_os

    echo
    cecho "$CYAN"  "  Detected OS: ${OS_NAME}"
    echo
    cecho "$CYAN"  "  This installer will:"
    echo   "    • Install Python and system dependencies"
    echo   "    • Create a Python virtual environment"
    echo   "    • Install Red-DiscordBot"
    echo   "    • Walk you through instance setup"
    echo
    cecho "$YELLOW" "  ⏱  Estimated time: 5-15 minutes depending on your connection."
    echo

    printf "${BOLD}  Ready to begin? [y/N]: ${RESET}"
    read -r answer </dev/tty
    if [[ ! "$answer" =~ ^[Yy]$ ]]; then
        echo
        cecho "$YELLOW" "  Cancelled. No changes were made."
        echo
        exit 0
    fi

    echo
    check_disk_space
    check_internet
    require_sudo
    interactive_red_setup
    route_os
}

main "$@"