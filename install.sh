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

echo "install started: $TIMESTAMP"
echo "mode: $MODE"
if $USE_VENV; then
  echo "using virtualenv mode"
else
  echo "system-wide pip install (will use --break-system-packages)"
fi

trap 'rc=$?; echo "install failed with code $rc"; echo "see $LOG_FILE"; exit $rc' ERR

if command -v apt-get >/dev/null 2>&1; then
  sudo apt-get update -y
  sudo apt-get install -y git curl wget build-essential python3 python3-venv python3-dev python3-pip libssl-dev libffi-dev libxml2-dev libxslt1-dev zlib1g-dev libjpeg-dev jq
fi

if $USE_VENV; then
  PYEXEC="python3"
  VENV_DIR="$BASE_DIR/.venv_osint"
  rm -rf "$VENV_DIR"
  python3 -m venv "$VENV_DIR"
  source "$VENV_DIR/bin/activate"
  PYEXEC="$VENV_DIR/bin/python"
  PIP="$VENV_DIR/bin/pip"
  $PYEXEC -m pip install --upgrade pip
else
  PYEXEC="python3"
  PIP="sudo python3 -m pip"
  $PYEXEC -m pip install --upgrade pip --break-system-packages
fi

echo "installing python packages from requirements.txt"
if $USE_VENV; then
  "$PIP" install -r requirements.txt
else
  $PIP install --break-system-packages -r requirements.txt
fi

cd "$TOOLS_DIR"

repos=(
  "https://github.com/sherlock-project/sherlock.git"
  "https://github.com/laramies/theHarvester.git"
  "https://github.com/s0md3v/Photon.git"
  "https://github.com/smicallef/spiderfoot.git"
  "https://github.com/elceef/dnstwist.git"
  "https://github.com/aboul3la/Sublist3r.git"
  "https://github.com/trufflesecurity/truffleHog.git"
  "https://github.com/megadose/holehe.git"
  "https://github.com/soxoj/maigret.git"
  "https://github.com/i3visio/osrframework.git"
  "https://github.com/urbanadventurer/urlcrazy.git"
  "https://github.com/blechschmidt/massdns.git"
  "https://github.com/philpep/testssl.sh.git"
  "https://github.com/sa7mon/SecLists.git"
  "https://github.com/byt3bl33d3r/TruffleHog.git"
)

for repo in "${repos[@]}"; do
  name="$(basename "$repo" .git)"
  if [ -d "$name" ]; then
    echo "updating $name"
    cd "$name"
    git pull --rebase || true
    cd ..
  else
    echo "cloning $name"
    git clone "$repo" || echo "clone failed for $repo"
  fi
done

for d in "$TOOLS_DIR"/*; do
  if [ -d "$d" ]; then
    if [ -f "$d/requirements.txt" ]; then
      echo "installing requirements for $(basename "$d")"
      if $USE_VENV; then
        "$PIP" install -r "$d/requirements.txt" || true
      else
        $PIP install --break-system-packages -r "$d/requirements.txt" || true
      fi
    fi
    if [ -f "$d/setup.py" ]; then
      echo "attempting pip install . for $(basename "$d")"
      if $USE_VENV; then
        (cd "$d" && "$PIP" install .) || true
      else
        (cd "$d" && $PIP install --break-system-packages .) || true
      fi
    fi
  fi
done

echo "post-install checks"
if command -v git >/dev/null 2>&1; then
  echo "git OK"
fi

echo "install finished: $(date +%F_%T)"
echo "logs: $LOG_FILE"
if $USE_VENV; then
  echo "virtualenv at: $VENV_DIR"
fi
