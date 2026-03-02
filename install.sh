#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-full}"
USE_VENV=false
for arg in "$@"; do
  if [ "$arg" = "--venv" ] || [ "$arg" = "-v" ]; then
    USE_VENV=true
  fi
done

BASE_DIR="$(pwd)"
LOG_DIR="$BASE_DIR/logs"
TOOLS_DIR="$HOME/osint-tools"
TIMESTAMP="$(date +%F_%T)"
LOG_FILE="$LOG_DIR/install_$TIMESTAMP.log"

mkdir -p "$LOG_DIR"
mkdir -p "$TOOLS_DIR"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "INSTALL STARTED: $TIMESTAMP"
echo "Mode: $MODE"
if $USE_VENV; then
  echo "Using virtualenv mode"
else
  echo "System-wide pip install (using --break-system-packages)"
fi

trap 'rc=$?; echo "INSTALL FAILED with code $rc"; echo "See log: $LOG_FILE"; exit $rc' ERR

if command -v apt-get >/dev/null 2>&1; then
  sudo apt-get update -y
  sudo apt-get install -y git curl wget build-essential python3 python3-venv python3-dev python3-pip \
    libssl-dev libffi-dev libxml2-dev libxslt1-dev zlib1g-dev libjpeg-dev jq unzip
fi

if $USE_VENV; then
  VENV_DIR="$BASE_DIR/.venv_osint"
  rm -rf "$VENV_DIR"
  python3 -m venv "$VENV_DIR"
  source "$VENV_DIR/bin/activate"
  PYEXEC="$VENV_DIR/bin/python"
  PIP="$VENV_DIR/bin/pip"
  "$PYEXEC" -m pip install --upgrade pip
else
  PYEXEC="python3"
  PIP="sudo python3 -m pip"
  "$PYEXEC" -m pip install --upgrade pip --break-system-packages
fi

echo "Installing Python packages from requirements.txt"
if $USE_VENV; then
  "$PIP" install -r requirements.txt || true
else
  $PIP install --break-system-packages -r requirements.txt || true
fi

cd "$TOOLS_DIR"

repos=(
"https://github.com/sherlock-project/sherlock.git"
"https://github.com/soxoj/maigret.git"
"https://github.com/megadose/holehe.git"
"https://github.com/twintproject/twint.git"
"https://github.com/Ice3man543/sointgram.git"
"https://github.com/xtekky/toutatis.git"
"https://github.com/xtekky/xeuledoc.git"
"https://github.com/smicallef/spiderfoot.git"
"https://github.com/laramies/theHarvester.git"
"https://github.com/s0md3v/Photon.git"
"https://github.com/elceef/dnstwist.git"
"https://github.com/aboul3la/Sublist3r.git"
"https://github.com/trufflesecurity/truffleHog.git"
"https://github.com/i3visio/osrframework.git"
"https://github.com/urbanadventurer/urlcrazy.git"
"https://github.com/blechschmidt/massdns.git"
"https://github.com/philpep/testssl.sh.git"
"https://github.com/danielmiessler/SecLists.git"
"https://github.com/laramies/metagoofil.git"
"https://github.com/zricethezav/gitleaks.git"
"https://github.com/s0md3v/social-analyzer.git"
"https://github.com/tomnomnom/waybackurls.git"
"https://github.com/tomnomnom/gau.git"
"https://github.com/projectdiscovery/subfinder.git"
"https://github.com/OWASP/Amass.git"
"https://github.com/tomnomnom/httprobe.git"
"https://github.com/ChrisTruncer/EyeWitness.git"
"https://github.com/sullo/nikto.git"
"https://github.com/robertdavidgraham/masscan.git"
"https://github.com/sqlmapproject/sqlmap.git"
"https://github.com/1N3/Sn1per.git"
"https://github.com/sundowndev/PhoneInfoga.git"
"https://github.com/sundowndev/ReconDog.git"
"https://github.com/byt3bl33d3r/CrackMapExec.git"
"https://github.com/projectdiscovery/nuclei.git"
"https://github.com/projectdiscovery/nuclei-templates.git"
"https://github.com/projectdiscovery/httpx.git"
"https://github.com/projectdiscovery/naabu.git"
"https://github.com/michenriksen/aquatone.git"
"https://github.com/0xsha/OSINTgram.git"
"https://github.com/instaloader/instaloader.git"
"https://github.com/maurosoria/dirsearch.git"
"https://github.com/urlscan/urlscan-cli.git"
"https://github.com/opsdisk/whatweb.git"
"https://github.com/arkadiyt/bulk_extractor.git"
"https://github.com/SEKOIA-IO/threat-intel-collector.git"
"https://github.com/blacktop/ios-deploy.git"
"https://github.com/marklodato/awesome-ctf.git"
"https://github.com/aidansteele/osint-workbench.git"
"https://github.com/larvalabs/rolling-cuckoo.git"
"https://github.com/dxa4481/truffleHog.git"
"https://github.com/harshjv/oneforall.git"
"https://github.com/blechschmidt/OWASP-Nettacker.git"
"https://github.com/urbanadventurer/UDR.git"
)

count=0
for repo in "${repos[@]}"; do
  name="$(basename "$repo" .git)"
  if [ -d "$name" ]; then
    echo "Updating $name"
    cd "$name"
    git pull --rebase || true
    cd ..
  else
    echo "Cloning $name"
    git clone "$repo" || echo "Clone failed for $name"
  fi
  count=$((count+1))
done

echo "Cloned $count repos (attempted)."

for d in "$TOOLS_DIR"/*; do
  if [ -d "$d" ]; then
    if [ -f "$d/requirements.txt" ]; then
      echo "Installing requirements for $(basename "$d")"
      if $USE_VENV; then
        "$PIP" install -r "$d/requirements.txt" || true
      else
        $PIP install --break-system-packages -r "$d/requirements.txt" || true
      fi
    fi
    if [ -f "$d/setup.py" ]; then
      echo "Running pip install . for $(basename "$d")"
      if $USE_VENV; then
        (cd "$d" && "$PIP" install .) || true
      else
        (cd "$d" && $PIP install --break-system-packages .) || true
      fi
    fi
  fi
done

echo "Post-install checks"
command -v git >/dev/null && echo "git OK"

echo "INSTALL FINISHED: $(date +%F_%T)"
echo "Logs: $LOG_FILE"
if $USE_VENV; then
  echo "Virtualenv: $VENV_DIR"
fi
