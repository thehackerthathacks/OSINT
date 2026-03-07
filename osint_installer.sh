#!/usr/bin/env bash
# =============================================================================
#  OSINT Tools Installer for Kali Linux
#  Focus: People OSINT > Web Recon
#  Usage: sudo bash osint_installer.sh [--category <cat>] [--dry-run] [--skip-apt]
# =============================================================================

set -uo pipefail

# ── Colours ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BLUE='\033[0;34m'; BOLD='\033[1m'; RESET='\033[0m'

# ── Globals ───────────────────────────────────────────────────────────────────
INSTALL_BASE="/opt/osint"
LOG_FILE="/var/log/osint_installer_$(date +%Y%m%d_%H%M%S).log"
VENV_BASE="${INSTALL_BASE}/venvs"
DRY_RUN=false
SKIP_APT=false
FILTER_CATEGORY=""
declare -A RESULTS   # tool_name -> "ok" | "fail" | "skip"
TOTAL=0; OK=0; FAIL=0; SKIP=0

# ── Argument parsing ──────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run)    DRY_RUN=true ;;
        --skip-apt)   SKIP_APT=true ;;
        --category)   FILTER_CATEGORY="${2:-}"; shift ;;
        --help|-h)
            echo "Usage: sudo $0 [--dry-run] [--skip-apt] [--category <people|phone|email|username|geo|web|framework|metadata>]"
            exit 0 ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
    shift
done

# ── Helpers ───────────────────────────────────────────────────────────────────
log()     { echo -e "$(date '+%H:%M:%S') $*" | tee -a "$LOG_FILE"; }
info()    { log "${CYAN}[*]${RESET} $*"; }
success() { log "${GREEN}[+]${RESET} $*"; }
warn()    { log "${YELLOW}[!]${RESET} $*"; }
error()   { log "${RED}[-]${RESET} $*"; }
header()  { echo -e "\n${BOLD}${BLUE}══════════════════════════════════════════${RESET}"; \
            echo -e "${BOLD}${BLUE}  $*${RESET}"; \
            echo -e "${BOLD}${BLUE}══════════════════════════════════════════${RESET}"; }
banner()  {
    clear
    echo -e "${BOLD}${CYAN}"
    cat <<'EOF'
  ██████╗ ███████╗██╗███╗   ██╗████████╗
 ██╔═══██╗██╔════╝██║████╗  ██║╚══██╔══╝
 ██║   ██║███████╗██║██╔██╗ ██║   ██║
 ██║   ██║╚════██║██║██║╚██╗██║   ██║
 ╚██████╔╝███████║██║██║ ╚████║   ██║
  ╚═════╝ ╚══════╝╚═╝╚═╝  ╚═══╝   ╚═╝
   Kali Linux Installer — People-First
EOF
    echo -e "${RESET}"
}

check_root() {
    [[ $EUID -eq 0 ]] || { error "Run as root: sudo bash $0"; exit 1; }
}

check_kali() {
    grep -qi kali /etc/os-release 2>/dev/null || warn "Not Kali Linux — some apt packages may be unavailable."
}

check_internet() {
    info "Checking internet connectivity..."
    curl -s --max-time 5 https://github.com >/dev/null 2>&1 || { error "No internet access. Aborting."; exit 1; }
}

# ── Track result ──────────────────────────────────────────────────────────────
record() {
    local name="$1" status="$2"
    RESULTS["$name"]="$status"
    ((TOTAL++))
    case "$status" in
        ok)   ((OK++));   success "$name installed successfully." ;;
        fail) ((FAIL++)); error   "$name FAILED — check $LOG_FILE" ;;
        skip) ((SKIP++)); warn    "$name skipped (already installed)." ;;
    esac
}

# ── Installation primitives ───────────────────────────────────────────────────
run_cmd() {
    if $DRY_RUN; then
        info "[DRY-RUN] $*"
        return 0
    fi
    eval "$@" >> "$LOG_FILE" 2>&1
}

apt_install() {
    local pkg="$1" name="${2:-$1}"
    $SKIP_APT && { record "$name" skip; return; }
    if dpkg -s "$pkg" &>/dev/null; then
        record "$name" skip
    else
        info "apt: installing $name..."
        run_cmd "DEBIAN_FRONTEND=noninteractive apt-get install -y $pkg" \
            && record "$name" ok || record "$name" fail
    fi
}

pip_install() {
    local pkg="$1" name="${2:-$1}" venv="${3:-}"
    local pip_bin="pip3"
    local extra_flags=""

    if [[ -n "$venv" && -d "${VENV_BASE}/${venv}/bin" ]]; then
        pip_bin="${VENV_BASE}/${venv}/bin/pip"
    else
        extra_flags="--break-system-packages"
    fi

    if $DRY_RUN; then record "$name" ok; return; fi

    if $pip_bin show "$pkg" &>/dev/null 2>&1; then
        record "$name" skip
    else
        info "pip: installing $name..."
        run_cmd "$pip_bin install --quiet $extra_flags $pkg" \
            && record "$name" ok || record "$name" fail
    fi
}

make_venv() {
    local name="$1"
    local vdir="${VENV_BASE}/${name}"
    $DRY_RUN && return
    [[ -d "$vdir" ]] && return
    info "Creating venv: $name"
    python3 -m venv "$vdir" >> "$LOG_FILE" 2>&1 || warn "Could not create venv $name"
}

github_clone() {
    # github_clone <category> <tool-name> <repo-url> [pip-requirements] [post-install-cmd]
    local cat="$1" name="$2" repo="$3" req="${4:-}" post="${5:-}"
    local dest="${INSTALL_BASE}/${cat}/${name}"

    [[ -n "$FILTER_CATEGORY" && "$FILTER_CATEGORY" != "$cat" ]] && return

    if [[ -d "$dest/.git" ]]; then
        record "$name" skip; return
    fi

    info "git: cloning $name..."
    if $DRY_RUN; then record "$name" ok; return; fi

    mkdir -p "${INSTALL_BASE}/${cat}"
    git clone --depth 1 "$repo" "$dest" >> "$LOG_FILE" 2>&1 || { record "$name" fail; return; }

    if [[ -n "$req" && -f "${dest}/${req}" ]]; then
        make_venv "$name"
        "${VENV_BASE}/${name}/bin/pip" install --quiet -r "${dest}/${req}" >> "$LOG_FILE" 2>&1 \
            || warn "$name: requirements install had errors"
    fi

    if [[ -n "$post" ]]; then
        pushd "$dest" >/dev/null
        eval "$post" >> "$LOG_FILE" 2>&1 || warn "$name: post-install step had errors"
        popd >/dev/null
    fi

    make_launcher "$name" "$dest"
    record "$name" ok
}

make_launcher() {
    # Creates a /usr/local/bin wrapper that activates the venv if one exists
    local name="$1" dest="$2"
    local venv="${VENV_BASE}/${name}"
    local launcher="/usr/local/bin/${name,,}"
    $DRY_RUN && return

    local python_bin
    [[ -f "${venv}/bin/python3" ]] && python_bin="${venv}/bin/python3" || python_bin="$(which python3)"

    # Find entry point
    local entry=""
    for f in "${dest}/main.py" "${dest}/${name,,}.py" "${dest}/app.py" "${dest}/run.py"; do
        [[ -f "$f" ]] && entry="$f" && break
    done

    [[ -z "$entry" ]] && return  # no obvious entry point; skip launcher

    cat > "$launcher" <<EOF
#!/usr/bin/env bash
cd "${dest}"
exec "${python_bin}" "${entry}" "\$@"
EOF
    chmod +x "$launcher"
}

# ── Setup ─────────────────────────────────────────────────────────────────────
setup_dirs() {
    info "Creating directory structure under ${INSTALL_BASE}..."
    $DRY_RUN && return
    mkdir -p "${VENV_BASE}"
    for cat in people phone email username geo web framework metadata social; do
        mkdir -p "${INSTALL_BASE}/${cat}"
    done
    touch "$LOG_FILE"
    chmod 600 "$LOG_FILE"
}

apt_update() {
    $SKIP_APT && return
    info "Updating apt cache..."
    run_cmd "apt-get update -qq"
}

install_base_deps() {
    $SKIP_APT && return
    header "Base Dependencies"
    local deps=(python3 python3-pip python3-venv python3-dev git curl wget \
                libssl-dev libffi-dev build-essential libxml2-dev libxslt1-dev \
                zlib1g-dev libjpeg-dev jq tor proxychains4 golang-go ruby ruby-dev)
    DEBIAN_FRONTEND=noninteractive apt-get install -y "${deps[@]}" >> "$LOG_FILE" 2>&1 \
        || warn "Some base deps failed — continuing anyway (check $LOG_FILE)"
    pip3 install --quiet --upgrade pip setuptools wheel --break-system-packages >> "$LOG_FILE" 2>&1 \
        || warn "pip upgrade failed — continuing anyway"
}

# =============================================================================
#  CATEGORY: People OSINT (General)
# =============================================================================
install_people() {
    [[ -n "$FILTER_CATEGORY" && "$FILTER_CATEGORY" != "people" ]] && return
    header "People OSINT (General)"

    # Kali apt
    apt_install "spiderfoot"          "SpiderFoot"
    apt_install "recon-ng"            "Recon-ng"
    apt_install "maltego"             "Maltego"
    apt_install "osrframework"        "OSRFramework"

    # pip global
    pip_install "socialscan"          "SocialScan"
    pip_install "datasploit"          "DataSploit"

    # GitHub
    github_clone people "Profil3r" \
        "https://github.com/Greyjedix/Profil3r" \
        "requirements.txt"

    github_clone people "OSINT-SPY" \
        "https://github.com/SharadKumar97/OSINT-SPY" \
        "requirements.txt"

    github_clone people "Moriarty-Project" \
        "https://github.com/AzizKpln/Moriarty-Project" \
        "requirements.txt"

    github_clone people "Social-Analyzer" \
        "https://github.com/qeeqbox/social-analyzer" \
        "requirements.txt"

    github_clone people "Lampyre" \
        "https://github.com/MichaelBonny/lampyre-osint-scripts" \
        ""

    github_clone people "Sn0int" \
        "https://github.com/kpcyrd/sn0int" \
        "" \
        "cargo build --release 2>/dev/null || true"

    github_clone people "Orbit" \
        "https://github.com/orbitalsquad/orbit" \
        "requirements.txt"
}

# =============================================================================
#  CATEGORY: Username / Handle OSINT
# =============================================================================
install_username() {
    [[ -n "$FILTER_CATEGORY" && "$FILTER_CATEGORY" != "username" ]] && return
    header "Username / Handle OSINT"

    apt_install "sherlock"  "Sherlock"

    pip_install "maigret"   "Maigret"
    pip_install "nexfil"    "Nexfil"

    github_clone username "WhatsMyName" \
        "https://github.com/webbreacher/whats-my-name" \
        "requirements.txt"

    github_clone username "Blackbird" \
        "https://github.com/p1ngul1n0/blackbird" \
        "requirements.txt"

    github_clone username "UserFinder" \
        "https://github.com/mishakorzik/UserFinder" \
        "requirements.txt"

    github_clone username "Sherlock-Project-Extended" \
        "https://github.com/sherlock-project/sherlock" \
        "requirements.txt" \
        "pip install -e . --quiet"

    github_clone username "Recon-User" \
        "https://github.com/rezaaksa/recon-user" \
        "requirements.txt"

    github_clone username "Namechk" \
        "https://github.com/HA71/Namechk" \
        "requirements.txt"

    github_clone username "Marple" \
        "https://github.com/d0nk/marple" \
        "requirements.txt"
}

# =============================================================================
#  CATEGORY: Email OSINT
# =============================================================================
install_email() {
    [[ -n "$FILTER_CATEGORY" && "$FILTER_CATEGORY" != "email" ]] && return
    header "Email OSINT"

    apt_install "theharvester"  "theHarvester"

    pip_install "holehe"   "Holehe"
    pip_install "h8mail"   "h8mail"

    github_clone email "GHunt" \
        "https://github.com/mxrch/GHunt" \
        "requirements.txt"

    github_clone email "Infoga" \
        "https://github.com/m4ll0k/Infoga" \
        "requirements.txt"

    github_clone email "EmailHarvester" \
        "https://github.com/maldevel/EmailHarvester" \
        "requirements.txt"

    github_clone email "Buster" \
        "https://github.com/sham00n/buster" \
        "requirements.txt"

    github_clone email "email2phonenumber" \
        "https://github.com/martinvigo/email2phonenumber" \
        "requirements.txt"

    github_clone email "H8mail-Extended" \
        "https://github.com/khast3x/h8mail" \
        "requirements.txt" \
        "pip install -e . --quiet"

    github_clone email "EMAGNET" \
        "https://github.com/wuseman/EMAGNET" \
        ""

    github_clone email "Mosint" \
        "https://github.com/alpkeskin/mosint" \
        "" \
        "go build -o mosint . 2>/dev/null || true"
}

# =============================================================================
#  CATEGORY: Phone Number OSINT
# =============================================================================
install_phone() {
    [[ -n "$FILTER_CATEGORY" && "$FILTER_CATEGORY" != "phone" ]] && return
    header "Phone Number OSINT"

    apt_install "phoneinfoga"  "PhoneInfoga"

    pip_install "ignorant"  "Ignorant"

    github_clone phone "PhoneInfoga" \
        "https://github.com/sundowndev/PhoneInfoga" \
        "requirements.txt"

    github_clone phone "Moriarty-Project" \
        "https://github.com/AzizKpln/Moriarty-Project" \
        "requirements.txt"

    github_clone phone "X-osint" \
        "https://github.com/TermuxHackz/X-osint" \
        "requirements.txt"

    github_clone phone "PhoneNumber-OSINT" \
        "https://github.com/spider863644/PhoneNumber-OSINT" \
        "requirements.txt"

    github_clone phone "PhoneOsint" \
        "https://github.com/kalmux1/PhoneOsint" \
        "requirements.txt"

    github_clone phone "Telespot" \
        "https://github.com/thumpersecure/Telespot" \
        "requirements.txt"
}

# =============================================================================
#  CATEGORY: Social Media OSINT
# =============================================================================
install_social() {
    [[ -n "$FILTER_CATEGORY" && "$FILTER_CATEGORY" != "social" ]] && return
    header "Social Media OSINT"

    apt_install  "instaloader"  "Instaloader"
    apt_install  "tinfoleak"    "Tinfoleak"

    pip_install  "snscrape"     "Snscrape"

    github_clone social "Twint" \
        "https://github.com/twintproject/twint" \
        "requirements.txt" \
        "pip install -e . --quiet"

    github_clone social "Toutatis" \
        "https://github.com/megadose/toutatis" \
        "requirements.txt"

    github_clone social "Instalooter" \
        "https://github.com/althonos/InstaLooter" \
        "" \
        "pip install instalooter --quiet"

    github_clone social "Osintgram" \
        "https://github.com/Datalux/Osintgram" \
        "requirements.txt"

    github_clone social "Eyes" \
        "https://github.com/N0rz3/Eyes" \
        "requirements.txt"

    github_clone social "Sterra" \
        "https://github.com/novitae/sterraxcyl" \
        "requirements.txt"

    github_clone social "Reddit-OSINT" \
        "https://github.com/n0toose/reddit-user-analyser" \
        "requirements.txt"

    github_clone social "Linkedin2Username" \
        "https://github.com/initstring/linkedin2username" \
        "requirements.txt"

    github_clone social "Stweet" \
        "https://github.com/markowanga/stweet" \
        "requirements.txt"

    github_clone social "Telegram-OSINT" \
        "https://github.com/ItIsMeCall911/Awesome-Telegram-OSINT" \
        ""

    github_clone social "TikTok-OSINT" \
        "https://github.com/tr33cr1me/TikTok-OSINT" \
        "requirements.txt"
}

# =============================================================================
#  CATEGORY: Geolocation OSINT
# =============================================================================
install_geo() {
    [[ -n "$FILTER_CATEGORY" && "$FILTER_CATEGORY" != "geo" ]] && return
    header "Geolocation OSINT"

    apt_install "creepy"  "Creepy"

    github_clone geo "GeoSpy" \
        "https://github.com/atiilla/geospy" \
        "requirements.txt"

    github_clone geo "Ipinfo-CLI" \
        "https://github.com/ipinfo/cli" \
        "" \
        "go build -o ipinfo . 2>/dev/null || true"

    github_clone geo "Carbon14" \
        "https://github.com/Lazza/Carbon14" \
        "requirements.txt"

    github_clone geo "GeoRecon" \
        "https://github.com/radioactivetobi/geo-recon" \
        "requirements.txt"

    github_clone geo "IVRE" \
        "https://github.com/ivre/ivre" \
        "" \
        "pip install ivre --quiet"
}

# =============================================================================
#  CATEGORY: Metadata OSINT
# =============================================================================
install_metadata() {
    [[ -n "$FILTER_CATEGORY" && "$FILTER_CATEGORY" != "metadata" ]] && return
    header "Metadata OSINT"

    apt_install "exiftool"   "ExifTool"
    apt_install "metagoofil" "Metagoofil"

    github_clone metadata "FOCA" \
        "https://github.com/ElevenPaths/FOCA" \
        ""

    github_clone metadata "Exifgrab" \
        "https://github.com/Neelakandan-A/ExifGrab" \
        "requirements.txt"

    github_clone metadata "MetaFinder" \
        "https://github.com/Josue87/MetaFinder" \
        "requirements.txt"

    github_clone metadata "PDF-OSINT" \
        "https://github.com/0x09AL/PDF-OSINT" \
        "requirements.txt"
}

# =============================================================================
#  CATEGORY: Web Recon (intentionally lighter)
# =============================================================================
install_web() {
    [[ -n "$FILTER_CATEGORY" && "$FILTER_CATEGORY" != "web" ]] && return
    header "Web Recon (Supplementary)"

    apt_install "amass"      "Amass"
    apt_install "sublist3r"  "Sublist3r"
    apt_install "dnsrecon"   "DNSrecon"
    apt_install "whois"      "Whois"
    apt_install "nmap"       "Nmap"

    pip_install "photon"  "Photon"

    github_clone web "Shodan-CLI" \
        "https://github.com/achillean/shodan-python" \
        "" \
        "pip install shodan --quiet"

    github_clone web "Waybackpy" \
        "https://github.com/akamhy/waybackpy" \
        "" \
        "pip install waybackpy --quiet"

    github_clone web "URLScan-py" \
        "https://github.com/ninoseki/uriorcise" \
        "requirements.txt"
}

# =============================================================================
#  CATEGORY: OSINT Frameworks / Platforms
# =============================================================================
install_framework() {
    [[ -n "$FILTER_CATEGORY" && "$FILTER_CATEGORY" != "framework" ]] && return
    header "OSINT Frameworks & Platforms"

    apt_install "spiderfoot"  "SpiderFoot"

    github_clone framework "OpenCTI-Client" \
        "https://github.com/OpenCTI-Platform/client-python" \
        "requirements.txt"

    github_clone framework "IntelOwl-Client" \
        "https://github.com/intelowlproject/pyintelowl" \
        "" \
        "pip install pyintelowl --quiet"

    github_clone framework "OSINTer" \
        "https://github.com/OSINTer-Platform/OSINTer" \
        "requirements.txt"

    github_clone framework "Datasploit" \
        "https://github.com/DataSploit/datasploit" \
        "requirements.txt"

    github_clone framework "Mr.Holmes" \
        "https://github.com/Lucksi/Mr.Holmes" \
        "requirements.txt"

    github_clone framework "OSINT-Framework-Tools" \
        "https://github.com/lockfale/osint-framework" \
        ""

    github_clone framework "Maltego-TRX" \
        "https://github.com/paterva/maltego-trx" \
        "" \
        "pip install maltego-trx --quiet"
}

# =============================================================================
#  Post-install: PATH & summary
# =============================================================================
setup_path() {
    $DRY_RUN && return
    local profile="/etc/profile.d/osint.sh"
    cat > "$profile" <<EOF
# OSINT tools PATH additions
export PATH="\$PATH:${INSTALL_BASE}/bin"
for _venv in ${VENV_BASE}/*/bin; do
    [[ -d "\$_venv" ]] && export PATH="\$PATH:\$_venv"
done
EOF
    chmod +x "$profile"
    info "PATH profile written to $profile — re-login or: source $profile"
}

print_summary() {
    local width=46
    echo
    echo -e "${BOLD}${BLUE}╔$(printf '═%.0s' $(seq 1 $width))╗${RESET}"
    printf "${BOLD}${BLUE}║${RESET}  %-*s${BOLD}${BLUE}║${RESET}\n" $((width-2)) "INSTALLATION SUMMARY"
    echo -e "${BOLD}${BLUE}╠$(printf '═%.0s' $(seq 1 $width))╣${RESET}"
    printf "${BOLD}${BLUE}║${RESET}  %-20s %s %*s${BOLD}${BLUE}║${RESET}\n" "Total tools:" "$TOTAL" $((width-24)) ""
    printf "${BOLD}${BLUE}║${RESET}  ${GREEN}%-20s %s${RESET}%*s${BOLD}${BLUE}║${RESET}\n" "Installed OK:" "$OK" $((width-24)) ""
    printf "${BOLD}${BLUE}║${RESET}  ${YELLOW}%-20s %s${RESET}%*s${BOLD}${BLUE}║${RESET}\n" "Skipped:" "$SKIP" $((width-24)) ""
    printf "${BOLD}${BLUE}║${RESET}  ${RED}%-20s %s${RESET}%*s${BOLD}${BLUE}║${RESET}\n" "Failed:" "$FAIL" $((width-24)) ""
    echo -e "${BOLD}${BLUE}╠$(printf '═%.0s' $(seq 1 $width))╣${RESET}"
    printf "${BOLD}${BLUE}║${RESET}  %-*s${BOLD}${BLUE}║${RESET}\n" $((width-2)) "Install dir : ${INSTALL_BASE}"
    printf "${BOLD}${BLUE}║${RESET}  %-*s${BOLD}${BLUE}║${RESET}\n" $((width-2)) "Log file    : ${LOG_FILE}"
    echo -e "${BOLD}${BLUE}╚$(printf '═%.0s' $(seq 1 $width))╝${RESET}"

    if [[ $FAIL -gt 0 ]]; then
        echo
        warn "Failed tools:"
        for tool in "${!RESULTS[@]}"; do
            [[ "${RESULTS[$tool]}" == "fail" ]] && echo -e "  ${RED}✗${RESET} $tool"
        done
    fi
}

# =============================================================================
#  MAIN
# =============================================================================
main() {
    banner
    check_root
    check_kali
    check_internet
    setup_dirs
    apt_update
    install_base_deps

    if [[ -z "$FILTER_CATEGORY" ]]; then
        install_people
        install_username
        install_email
        install_phone
        install_social
        install_geo
        install_metadata
        install_web
        install_framework
    else
        case "$FILTER_CATEGORY" in
            people)    install_people ;;
            username)  install_username ;;
            email)     install_email ;;
            phone)     install_phone ;;
            social)    install_social ;;
            geo)       install_geo ;;
            metadata)  install_metadata ;;
            web)       install_web ;;
            framework) install_framework ;;
            *) error "Unknown category: $FILTER_CATEGORY"; exit 1 ;;
        esac
    fi

    setup_path
    print_summary
}

main "$@"
