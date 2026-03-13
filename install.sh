#!/usr/bin/env bash

# Below is the Windows detection, someone runs this script on a Windows machine it will tell them to run the install.ps1 instead.
# Doesn't affect WSL

case "$(uname -s 2>/dev/null)" in
    MINGW*|CYGWIN*|MSYS*)
        clear
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
        read -r -p "  Press Enter to exit..." _
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
    clear
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
    read -r -p "  Press Enter to exit..." _
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
# SETUP STEP HEADER
# Clears screen, shows banner, then shows which
# step of the interactive setup we are on so the
# screen stays clean between questions.
# ─────────────────────────────────────────────
show_setup_header() {
    local step="$1"
    local total="$2"
    local title="$3"
    show_banner
    printf "  ${CYAN}${BOLD}[Setup: Step %d of %d]${RESET}  %s\n" "$step" "$total" "$title"
    printf "  ${CYAN}──────────────────────────────────────────────${RESET}\n"
    echo
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

# Arrays that track each completed step for the install screen
declare -a STEP_HISTORY_LABELS=()
declare -a STEP_HISTORY_OK=()

# ─────────────────────────────────────────────
# SPINNER
# Animates on the current step line while the
# background process runs. Uses \r to stay in
# place rather than scrolling the screen.
# ─────────────────────────────────────────────
spinner() {
    local pid="$1"
    local delay=0.08
    local spin='|/-\'
    local i=0
    tput civis 2>/dev/null || true
    while kill -0 "$pid" 2>/dev/null; do
        i=$(( (i + 1) % 4 ))
        printf "\r  ${CYAN}${spin:$i:1}${RESET}  [%d/%d] %s" "$STEP_NUM" "$TOTAL_STEPS" "$CURRENT_STEP"
        sleep "$delay"
    done
    tput cnorm 2>/dev/null || true
}

# ─────────────────────────────────────────────
# DRAW INSTALL SCREEN
# Clears the terminal and redraws the banner
# plus all completed steps before showing the
# current step. Keeps the display clean and
# gives the user a live tally of progress.
# ─────────────────────────────────────────────
draw_install_screen() {
    show_banner
    printf "  ${CYAN}${BOLD}Installing Red-DiscordBot${RESET}\n"
    printf "  ${CYAN}──────────────────────────────────────────────${RESET}\n"
    echo

    for i in "${!STEP_HISTORY_LABELS[@]}"; do
        if [[ "${STEP_HISTORY_OK[$i]}" == "1" ]]; then
            printf "  ${GREEN}✓${RESET}  %s\n" "${STEP_HISTORY_LABELS[$i]}"
        else
            printf "  ${RED}✗${RESET}  %s\n" "${STEP_HISTORY_LABELS[$i]}"
        fi
    done
}

# ─────────────────────────────────────────────
# RUN STEP
# Clears the screen and redraws the install
# status before each step, then runs it with
# a spinner. Marks it done or failed and saves
# it so the next step can display it.
# ─────────────────────────────────────────────
run_step() {
    local message="$1"; shift
    STEP_NUM=$(( STEP_NUM + 1 ))
    CURRENT_STEP="$message"

    draw_install_screen
    printf "  ${CYAN}►${RESET}  [%d/%d] %s" "$STEP_NUM" "$TOTAL_STEPS" "$message"

    ( "$@" ) >"$LOG_FILE" 2>&1 &
    local pid=$!
    spinner "$pid"

    set +e; wait "$pid"; local rc=$?; set -e

    if [[ "$rc" -eq 0 ]]; then
        printf "\r  ${GREEN}✓${RESET}  [%d/%d] %s\e[K\n" "$STEP_NUM" "$TOTAL_STEPS" "$message"
        STEP_HISTORY_LABELS+=("$message")
        STEP_HISTORY_OK+=("1")
    else
        printf "\r  ${RED}✗${RESET}  [%d/%d] %s\e[K\n" "$STEP_NUM" "$TOTAL_STEPS" "$message"
        STEP_HISTORY_LABELS+=("$message (FAILED)")
        STEP_HISTORY_OK+=("0")
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
# DISCLAIMER
# Shows what the script will change on the
# system and asks the user to accept before
# touching anything. Also nudges them to star.
# ─────────────────────────────────────────────
show_disclaimer() {
    show_banner
    printf "  ${YELLOW}${BOLD}Before we start — a quick heads up${RESET}\n"
    printf "  ${CYAN}──────────────────────────────────────────────${RESET}\n"
    echo
    echo "  Here's what this script is about to do to your machine:"
    echo
    echo "    • Install system packages (Python 3.11, Git, build tools, Java if audio)"
    echo "    • Create a Python virtual environment at ~/redenv"
    echo "    • Download and install Red-DiscordBot and its Python dependencies"
    echo "    • Create a Red instance config in your home directory"
    echo "    • (Optional) Set up a systemd service so Red starts on boot"
    echo
    echo "  It uses sudo to install packages. Only standard system paths are touched."
    echo "  No funny business."
    echo
    printf "  ${CYAN}──────────────────────────────────────────────${RESET}\n"
    echo
    printf "  ${BOLD}  ⭐  Also — if this saves you some headaches, please star the repo:${RESET}\n"
    printf "  ${CYAN}      https://github.com/BigPattyOG/red-installer${RESET}\n"
    echo
    echo "  Stars help more people find this thing. It takes literally 2 seconds."
    echo "  I'll pretend I'm not obsessively watching the star count. (I am.)"
    echo
    printf "  ${CYAN}──────────────────────────────────────────────${RESET}\n"
    echo
    printf "  ${BOLD}  I've read the above and I'm ready to proceed [y/N]: ${RESET}"
    read -r answer </dev/tty
    if [[ ! "$answer" =~ ^[Yy]$ ]]; then
        echo
        cecho "$YELLOW" "  Fair enough. No changes were made. Come back when you're ready."
        echo
        exit 0
    fi
}

# ─────────────────────────────────────────────
# INTERACTIVE RED SETUP
# Each question gets its own screen with a step
# counter so the screen stays clean. Validates
# prefix (rejects / prefix) and token length.
# Collects PostgreSQL credentials if needed.
# Every read uses </dev/tty so it always reads
# from the terminal even when stdin is a pipe.
# ─────────────────────────────────────────────
interactive_red_setup() {
    local has_systemd=false
    command -v systemctl &>/dev/null && has_systemd=true

    # Base steps: name, path, backend, audio, token, prefix
    local total_setup_steps=6
    $has_systemd && total_setup_steps=$(( total_setup_steps + 1 ))
    local step=0

    # ── Step: Instance name ──────────────────
    step=$(( step + 1 ))
    show_setup_header "$step" "$total_setup_steps" "Instance Name"
    echo   "  This is just a label so Red knows which bot is which on this machine."
    echo   "  Examples: mybot, redbot, mainbot"
    echo   "  It won't (and can't) change your bot's name on Discord."
    echo
    while true; do
        printf "  Instance name: "
        read -r INSTANCE_NAME </dev/tty
        [[ -n "${INSTANCE_NAME// }" ]] && break
        cecho "$RED" "  Can't be empty. Give it something to go by."
    done

    # ── Step: Data path ──────────────────────
    step=$(( step + 1 ))
    local default_data="${HOME}/.local/share/Red-DiscordBot/${INSTANCE_NAME}"
    show_setup_header "$step" "$total_setup_steps" "Data Storage Path"
    echo   "  Where should Red store its data? Configs, cog data, all of it."
    echo   "  Press Enter to use the default, or type a different path."
    echo
    echo   "  Default: ${default_data}"
    echo
    printf "  Data path [default: above]: "
    read -r DATA_DIR </dev/tty
    DATA_DIR="${DATA_DIR:-$default_data}"

    # ── Step: Backend ────────────────────────
    step=$(( step + 1 ))
    show_setup_header "$step" "$total_setup_steps" "Data Backend"
    echo   "  How should Red store its data internally?"
    echo
    echo   "  1) JSON  — Simple flat files, no database needed. This is the one"
    echo   "             90% of people should pick. Seriously, just pick this."
    echo
    echo   "  2) PostgreSQL — For the 10% who actually have a Postgres server"
    echo   "                  running and know what they're doing."
    echo
    printf "  Choice [1/2, default 1]: "
    read -r backend_choice </dev/tty
    case "${backend_choice:-1}" in
        2) BACKEND="postgres" ;;
        *) BACKEND="json"     ;;
    esac

    # ── Step: PostgreSQL credentials (if needed) ──
    PG_HOST=""
    PG_PORT=""
    PG_USER=""
    PG_PASS=""
    PG_DBNAME=""

    if [[ "$BACKEND" == "postgres" ]]; then
        total_setup_steps=$(( total_setup_steps + 1 ))
        step=$(( step + 1 ))
        show_setup_header "$step" "$total_setup_steps" "PostgreSQL Connection Details"
        echo   "  Alright, you chose PostgreSQL. Let's get the connection details sorted."
        echo   "  Leave any field blank to use its default (shown in brackets)."
        echo
        printf "  Database host [default: localhost]: "
        read -r PG_HOST </dev/tty
        PG_HOST="${PG_HOST:-localhost}"

        while true; do
            printf "  Database port [default: 5432]: "
            read -r PG_PORT </dev/tty
            PG_PORT="${PG_PORT:-5432}"
            if [[ "$PG_PORT" =~ ^[0-9]+$ ]]; then break; fi
            cecho "$RED" "  Port has to be a number. Try again."
        done

        printf "  Database username [default: redbot]: "
        read -r PG_USER </dev/tty
        PG_USER="${PG_USER:-redbot}"

        echo
        cecho  "$RED" "  NOTE: Password won't show as you type."
        while true; do
            printf "  Database password: "
            read -r -s PG_PASS </dev/tty
            echo
            [[ -n "${PG_PASS// }" ]] && break
            cecho "$RED" "  Password can't be empty — Red needs it to connect."
        done

        printf "  Database name [default: redbot]: "
        read -r PG_DBNAME </dev/tty
        PG_DBNAME="${PG_DBNAME:-redbot}"
    fi

    # ── Step: Audio ──────────────────────────
    step=$(( step + 1 ))
    show_setup_header "$step" "$total_setup_steps" "Audio Support"
    echo   "  Want your bot to play music? This installs Java 17, which Red's"
    echo   "  Audio cog needs to run its built-in Lavalink server."
    echo
    echo   "  You can skip this and enable it later — just know you'll need"
    echo   "  Java on the system before audio will work."
    echo
    printf "  Enable audio support? [y/N]: "
    read -r audio_choice </dev/tty
    WANT_AUDIO=false
    [[ "$audio_choice" =~ ^[Yy]$ ]] && WANT_AUDIO=true

    # ── Step: Bot token ──────────────────────
    step=$(( step + 1 ))
    show_setup_header "$step" "$total_setup_steps" "Discord Bot Token"
    echo   "  Grab your bot token from the Discord Developer Portal:"
    echo   "  https://discord.com/developers/applications"
    echo
    echo   "  Go to your application → Bot → Reset Token."
    echo   "  Copy the whole thing — it's a long string of random characters."
    echo
    cecho  "$RED" "  NOTE: The token won't show as you type. That's on purpose."
    echo
    while true; do
        printf "  Bot token: "
        read -r -s BOT_TOKEN </dev/tty
        echo
        if [[ -z "${BOT_TOKEN// }" ]]; then
            cecho "$RED" "  With no token, you have no bot. Try again."
            continue
        fi
        if [[ "${#BOT_TOKEN}" -lt 50 ]]; then
            cecho "$RED" "  That token looks too short (Discord tokens are 50+ characters)."
            cecho "$RED" "  Double-check you copied the whole thing."
            continue
        fi
        break
    done

    # ── Step: Prefix ─────────────────────────
    step=$(( step + 1 ))
    show_setup_header "$step" "$total_setup_steps" "Command Prefix"
    echo   "  This is the character your bot listens to. Like !help or ?play."
    echo   "  Pick something short and memorable."
    echo
    cecho  "$RED"    "  DO NOT use / as your prefix — it conflicts with Discord's"
    cecho  "$RED"    "  built-in slash commands and things will get weird fast."
    echo
    while true; do
        printf "  Command prefix [default: !]: "
        read -r BOT_PREFIX </dev/tty
        BOT_PREFIX="${BOT_PREFIX:-!}"
        if [[ "$BOT_PREFIX" == /* ]]; then
            cecho "$RED" "  Nope. Anything starting with / is off the table."
            cecho "$RED" "  Pick something else (!, ?, ., etc.)"
            BOT_PREFIX=""
            continue
        fi
        break
    done

    # ── Step: Systemd (Linux only) ───────────
    WANT_SYSTEMD=false
    if $has_systemd; then
        step=$(( step + 1 ))
        show_setup_header "$step" "$total_setup_steps" "Auto-Start Service"
        echo   "  Want Red to start automatically whenever this machine boots up?"
        echo   "  We can set it up as a systemd service. Recommended if this is a server."
        echo
        printf "  Set up systemd service? [Y/n]: "
        read -r svc_choice </dev/tty
        [[ ! "$svc_choice" =~ ^[Nn]$ ]] && WANT_SYSTEMD=true
    fi

    export INSTANCE_NAME DATA_DIR BACKEND BOT_TOKEN BOT_PREFIX WANT_AUDIO WANT_SYSTEMD
    export PG_HOST PG_PORT PG_USER PG_PASS PG_DBNAME

    show_banner
    printf "  ${GREEN}${BOLD}✓ Setup details saved. Starting installation...${RESET}\n"
    echo
    sleep 1
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
# For JSON backend: runs redbot-setup with all
# options as flags — fully non-interactive.
# For PostgreSQL: writes the config directly
# via a Python helper to avoid the interactive
# getpass prompt inside redbot-setup.
# ─────────────────────────────────────────────
configure_red_instance() {
    # shellcheck disable=SC1091
    source "${HOME}/redenv/bin/activate"
    mkdir -p "$DATA_DIR"

    if [[ "$BACKEND" == "postgres" ]]; then
        # Write the postgres config via an inline Python script.
        # redbot-setup for postgres calls getpass interactively, so we bypass
        # it and write the instance config file directly.
        local pg_script
        pg_script=$(mktemp /tmp/redbot_pg.XXXXXX.py)
        cat > "$pg_script" << 'PYEOF'
import json, os
from pathlib import Path

instance_name = os.environ["INSTANCE_NAME"]
data_dir      = os.environ["DATA_DIR"]
pg_host       = os.environ.get("PG_HOST") or None
pg_port_s     = os.environ.get("PG_PORT", "")
pg_port       = int(pg_port_s) if pg_port_s and pg_port_s.isdigit() else None
pg_user       = os.environ.get("PG_USER") or None
pg_pass       = os.environ.get("PG_PASS") or None
pg_dbname     = os.environ.get("PG_DBNAME") or None

try:
    from platformdirs import user_config_dir
    cfg_dir = Path(user_config_dir("Red-DiscordBot"))
except Exception:
    cfg_dir = Path.home() / ".config" / "Red-DiscordBot"

cfg_dir.mkdir(parents=True, exist_ok=True)
cfg_file = cfg_dir / "config.json"

cfg = json.loads(cfg_file.read_text(encoding="utf-8")) if cfg_file.exists() else {}
cfg[instance_name] = {
    "DATA_PATH": data_dir,
    "STORAGE_TYPE": "postgres",
    "STORAGE_DETAILS": {
        "host":     pg_host,
        "port":     pg_port,
        "user":     pg_user,
        "password": pg_pass,
        "database": pg_dbname,
    },
}
cfg_file.write_text(json.dumps(cfg, indent=4), encoding="utf-8")
print(f"Config written to {cfg_file}")
PYEOF
        INSTANCE_NAME="$INSTANCE_NAME" DATA_DIR="$DATA_DIR" \
        PG_HOST="$PG_HOST"   PG_PORT="$PG_PORT" \
        PG_USER="$PG_USER"   PG_PASS="$PG_PASS" \
        PG_DBNAME="$PG_DBNAME" \
        python "$pg_script"
        rm -f "$pg_script"
    else
        redbot-setup \
            --instance-name "$INSTANCE_NAME" \
            --data-path "$DATA_DIR" \
            --backend "$BACKEND" \
            --no-prompt
    fi
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

  Audio setup:
    Java 17 is installed and ready. To enable audio in your bot:
      1. Start Red and log in to Discord
      2. Run: [p]load audio
      3. That's it — Red manages Lavalink itself.
    Full audio docs: https://docs.discord.red/en/stable/cog_guides/audio.html
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
    local java_pkg=""
    [[ "$WANT_AUDIO" == true ]] && java_pkg="openjdk-17-jre-headless"

    TOTAL_STEPS=5
    [[ "$WANT_AUDIO" == true ]]   && TOTAL_STEPS=$(( TOTAL_STEPS + 1 ))
    [[ "$WANT_SYSTEMD" == true ]] && TOTAL_STEPS=$(( TOTAL_STEPS + 1 ))

    run_step "Updating package lists" \
        sudo apt-get update -q

    run_step "Adding deadsnakes PPA for Python 3.11" \
        bash -c "sudo apt-get install -y -q software-properties-common && \
                 sudo add-apt-repository -y ppa:deadsnakes/ppa && \
                 sudo apt-get update -q"

    run_step "Installing system packages" \
        bash -c "sudo apt-get install -y -q \
            python3.11 python3.11-dev python3.11-venv \
            git build-essential nano ${java_pkg}"

    run_step "Creating Python virtual environment" \
        create_venv python3.11

    run_step "Installing Red-DiscordBot" \
        install_red_into_venv

    run_step "Configuring Red instance" \
        bash -c "$(declare -f configure_red_instance); \
                 INSTANCE_NAME='$INSTANCE_NAME' DATA_DIR='$DATA_DIR' \
                 BACKEND='$BACKEND' PG_HOST='$PG_HOST' PG_PORT='$PG_PORT' \
                 PG_USER='$PG_USER' PG_PASS='$PG_PASS' PG_DBNAME='$PG_DBNAME' \
                 configure_red_instance"

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
    local java_pkg=""
    [[ "$WANT_AUDIO" == true ]] && java_pkg="openjdk-17-jre-headless"

    TOTAL_STEPS=4
    [[ "$WANT_AUDIO" == true ]]   && TOTAL_STEPS=$(( TOTAL_STEPS + 1 ))
    [[ "$WANT_SYSTEMD" == true ]] && TOTAL_STEPS=$(( TOTAL_STEPS + 1 ))

    run_step "Updating package lists" \
        sudo apt-get update -q

    run_step "Installing system packages" \
        bash -c "sudo apt-get install -y -q \
            python3.10 python3.10-dev python3.10-venv \
            git build-essential nano ${java_pkg}"

    run_step "Creating Python virtual environment" \
        create_venv python3.10

    run_step "Installing Red-DiscordBot" \
        install_red_into_venv

    run_step "Configuring Red instance" \
        bash -c "$(declare -f configure_red_instance); \
                 INSTANCE_NAME='$INSTANCE_NAME' DATA_DIR='$DATA_DIR' \
                 BACKEND='$BACKEND' PG_HOST='$PG_HOST' PG_PORT='$PG_PORT' \
                 PG_USER='$PG_USER' PG_PASS='$PG_PASS' PG_DBNAME='$PG_DBNAME' \
                 configure_red_instance"

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
    local java_pkg=""
    [[ "$WANT_AUDIO" == true ]] && java_pkg="openjdk-17-jre-headless"

    TOTAL_STEPS=4
    [[ "$WANT_AUDIO" == true ]]   && TOTAL_STEPS=$(( TOTAL_STEPS + 1 ))
    [[ "$WANT_SYSTEMD" == true ]] && TOTAL_STEPS=$(( TOTAL_STEPS + 1 ))

    run_step "Updating package lists" \
        sudo apt-get update -q

    run_step "Installing system packages" \
        bash -c "sudo apt-get install -y -q \
            python3 python3-dev python3-venv \
            git build-essential nano ${java_pkg}"

    run_step "Creating Python virtual environment" \
        create_venv python3.11

    run_step "Installing Red-DiscordBot" \
        install_red_into_venv

    run_step "Configuring Red instance" \
        bash -c "$(declare -f configure_red_instance); \
                 INSTANCE_NAME='$INSTANCE_NAME' DATA_DIR='$DATA_DIR' \
                 BACKEND='$BACKEND' PG_HOST='$PG_HOST' PG_PORT='$PG_PORT' \
                 PG_USER='$PG_USER' PG_PASS='$PG_PASS' PG_DBNAME='$PG_DBNAME' \
                 configure_red_instance"

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
    local java_pkg=""
    [[ "$WANT_AUDIO" == true ]] && java_pkg="openjdk-17-jre-headless"

    TOTAL_STEPS=4
    [[ "$WANT_AUDIO" == true ]]   && TOTAL_STEPS=$(( TOTAL_STEPS + 1 ))
    [[ "$WANT_SYSTEMD" == true ]] && TOTAL_STEPS=$(( TOTAL_STEPS + 1 ))

    run_step "Updating package lists" \
        sudo apt-get update -q

    run_step "Installing system packages" \
        bash -c "sudo apt-get install -y -q \
            python3 python3-dev python3-venv \
            git build-essential nano ${java_pkg}"

    run_step "Creating Python virtual environment" \
        create_venv python3.11

    run_step "Installing Red-DiscordBot" \
        install_red_into_venv

    run_step "Configuring Red instance" \
        bash -c "$(declare -f configure_red_instance); \
                 INSTANCE_NAME='$INSTANCE_NAME' DATA_DIR='$DATA_DIR' \
                 BACKEND='$BACKEND' PG_HOST='$PG_HOST' PG_PORT='$PG_PORT' \
                 PG_USER='$PG_USER' PG_PASS='$PG_PASS' PG_DBNAME='$PG_DBNAME' \
                 configure_red_instance"

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
    local java_pkg=""
    [[ "$WANT_AUDIO" == true ]] && java_pkg="java-17-openjdk-headless"

    TOTAL_STEPS=5
    [[ "$WANT_AUDIO" == true ]]   && TOTAL_STEPS=$(( TOTAL_STEPS + 1 ))
    [[ "$WANT_SYSTEMD" == true ]] && TOTAL_STEPS=$(( TOTAL_STEPS + 1 ))

    run_step "Updating system packages" \
        sudo dnf -y update

    run_step "Installing development tools group" \
        sudo dnf -y group install development

    run_step "Installing Python 3.11, Git and nano" \
        bash -c "sudo dnf -y install \
            python3.11 python3.11-devel \
            git nano ${java_pkg}"

    if [[ "$WANT_AUDIO" == true ]]; then
        run_step "Setting Java 17 as default" \
            sudo alternatives --set java "java-17-openjdk.$(uname -i)"
    fi

    run_step "Creating Python virtual environment" \
        create_venv python3.11

    run_step "Installing Red-DiscordBot" \
        install_red_into_venv

    run_step "Configuring Red instance" \
        bash -c "$(declare -f configure_red_instance); \
                 INSTANCE_NAME='$INSTANCE_NAME' DATA_DIR='$DATA_DIR' \
                 BACKEND='$BACKEND' PG_HOST='$PG_HOST' PG_PORT='$PG_PORT' \
                 PG_USER='$PG_USER' PG_PASS='$PG_PASS' PG_DBNAME='$PG_DBNAME' \
                 configure_red_instance"

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
    local java_pkg=""
    [[ "$WANT_AUDIO" == true ]] && java_pkg="java-17-openjdk-headless"

    TOTAL_STEPS=4
    [[ "$WANT_AUDIO" == true ]]   && TOTAL_STEPS=$(( TOTAL_STEPS + 1 ))
    [[ "$WANT_SYSTEMD" == true ]] && TOTAL_STEPS=$(( TOTAL_STEPS + 1 ))

    run_step "Installing system packages" \
        bash -c "sudo dnf -y install \
            python3.11 python3.11-devel \
            git @development nano ${java_pkg}"

    run_step "Creating Python virtual environment" \
        create_venv python3.11

    run_step "Installing Red-DiscordBot" \
        install_red_into_venv

    run_step "Configuring Red instance" \
        bash -c "$(declare -f configure_red_instance); \
                 INSTANCE_NAME='$INSTANCE_NAME' DATA_DIR='$DATA_DIR' \
                 BACKEND='$BACKEND' PG_HOST='$PG_HOST' PG_PORT='$PG_PORT' \
                 PG_USER='$PG_USER' PG_PASS='$PG_PASS' PG_DBNAME='$PG_DBNAME' \
                 configure_red_instance"

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
                 BACKEND='$BACKEND' PG_HOST='$PG_HOST' PG_PORT='$PG_PORT' \
                 PG_USER='$PG_USER' PG_PASS='$PG_PASS' PG_DBNAME='$PG_DBNAME' \
                 configure_red_instance"

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
    local java_pkg=""
    [[ "$WANT_AUDIO" == true ]] && java_pkg="java-17-amazon-corretto-headless"

    TOTAL_STEPS=4
    [[ "$WANT_AUDIO" == true ]]   && TOTAL_STEPS=$(( TOTAL_STEPS + 1 ))
    [[ "$WANT_SYSTEMD" == true ]] && TOTAL_STEPS=$(( TOTAL_STEPS + 1 ))

    run_step "Installing system packages" \
        bash -c "sudo dnf -y install \
            python3.11 python3.11-devel \
            git @development nano ${java_pkg}"

    run_step "Creating Python virtual environment" \
        create_venv python3.11

    run_step "Installing Red-DiscordBot" \
        install_red_into_venv

    run_step "Configuring Red instance" \
        bash -c "$(declare -f configure_red_instance); \
                 INSTANCE_NAME='$INSTANCE_NAME' DATA_DIR='$DATA_DIR' \
                 BACKEND='$BACKEND' PG_HOST='$PG_HOST' PG_PORT='$PG_PORT' \
                 PG_USER='$PG_USER' PG_PASS='$PG_PASS' PG_DBNAME='$PG_DBNAME' \
                 configure_red_instance"

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
    local java_pkg=""
    [[ "$WANT_AUDIO" == true ]] && java_pkg="java-17-openjdk-headless"

    TOTAL_STEPS=4
    [[ "$WANT_AUDIO" == true ]]   && TOTAL_STEPS=$(( TOTAL_STEPS + 1 ))
    [[ "$WANT_SYSTEMD" == true ]] && TOTAL_STEPS=$(( TOTAL_STEPS + 1 ))

    run_step "Installing system packages" \
        bash -c "sudo zypper -n install \
                     python311 python311-devel \
                     git-core nano ${java_pkg} && \
                 sudo zypper -n install -t pattern devel_basis"

    run_step "Creating Python virtual environment" \
        create_venv python3.11

    run_step "Installing Red-DiscordBot" \
        install_red_into_venv

    run_step "Configuring Red instance" \
        bash -c "$(declare -f configure_red_instance); \
                 INSTANCE_NAME='$INSTANCE_NAME' DATA_DIR='$DATA_DIR' \
                 BACKEND='$BACKEND' PG_HOST='$PG_HOST' PG_PORT='$PG_PORT' \
                 PG_USER='$PG_USER' PG_PASS='$PG_PASS' PG_DBNAME='$PG_DBNAME' \
                 configure_red_instance"

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
    [[ "$WANT_AUDIO" == true ]]   && TOTAL_STEPS=$(( TOTAL_STEPS + 1 ))
    [[ "$WANT_SYSTEMD" == true ]] && TOTAL_STEPS=$(( TOTAL_STEPS + 1 ))

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
                 BACKEND='$BACKEND' PG_HOST='$PG_HOST' PG_PORT='$PG_PORT' \
                 PG_USER='$PG_USER' PG_PASS='$PG_PASS' PG_DBNAME='$PG_DBNAME' \
                 configure_red_instance"

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

    show_disclaimer

    check_disk_space
    check_internet
    interactive_red_setup

    TOTAL_STEPS=4
    [[ "$WANT_AUDIO" == true ]] && TOTAL_STEPS=$(( TOTAL_STEPS + 1 ))

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
                 BACKEND='$BACKEND' PG_HOST='$PG_HOST' PG_PORT='$PG_PORT' \
                 PG_USER='$PG_USER' PG_PASS='$PG_PASS' PG_DBNAME='$PG_DBNAME' \
                 configure_red_instance"

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

    show_disclaimer

    check_disk_space
    check_internet
    require_sudo
    interactive_red_setup
    route_os
}

main "$@"