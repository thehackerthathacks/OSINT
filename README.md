# OSINT Tools Installer for Kali Linux

A bash installer for ~100 OSINT tools, weighted toward **people intelligence** (username, email, phone, social media) over web recon. Tools are pulled from Kali's apt repos, pip, and GitHub. Each GitHub tool gets its own Python venv to avoid dependency conflicts.

---

## Requirements

- Kali Linux (will warn but still run on other Debian-based distros)
- Root / sudo
- Internet access
- ~4–8 GB free disk space (depends on which categories you install)

---

## Usage

```bash
chmod +x osint_installer.sh
sudo bash osint_installer.sh
```

### Flags

| Flag | Description |
|---|---|
| `--dry-run` | Preview all actions without making any changes |
| `--skip-apt` | Skip apt packages, only install GitHub/pip tools |
| `--category <name>` | Install a single category only |
| `--help` | Show usage |

### Install a single category

```bash
sudo bash osint_installer.sh --category phone
sudo bash osint_installer.sh --category email
sudo bash osint_installer.sh --category username
```

### Preview without installing

```bash
sudo bash osint_installer.sh --dry-run
```

---

## Categories

### People OSINT (General)
General-purpose people intelligence frameworks that span multiple data sources.

| Tool | Source | Description |
|---|---|---|
| SpiderFoot | apt | Automated OSINT across 200+ sources |
| Recon-ng | apt | Full-featured web recon framework |
| Maltego | apt | Visual link analysis platform |
| OSRFramework | apt | Username, email, phone across networks |
| SocialScan | pip | Checks username/email availability |
| Profil3r | GitHub | Finds profiles across social networks |
| OSINT-SPY | GitHub | Multi-source people lookup |
| Moriarty-Project | GitHub | Social media aggregation |
| Social-Analyzer | GitHub | Profile analysis across 900+ sites |
| Sn0int | GitHub | Semi-automated OSINT framework (Rust) |
| Orbit | GitHub | Twitter network mapper |

---

### Username / Handle OSINT
Find where a username exists across the internet.

| Tool | Source | Description |
|---|---|---|
| Sherlock | apt | Username hunt across 300+ social networks |
| Maigret | pip | Deep username profiling |
| Nexfil | pip | Username search across 350+ sites |
| WhatsMyName | GitHub | Community-maintained site list |
| Blackbird | GitHub | Fast username search |
| UserFinder | GitHub | Username enumeration |
| Namechk | GitHub | Domain and username checker |
| Marple | GitHub | Username lookup with context |

---

### Email OSINT
Investigate email addresses — breaches, linked accounts, identity.

| Tool | Source | Description |
|---|---|---|
| theHarvester | apt | Email harvesting from public sources |
| Holehe | pip | Check if email is registered on 120+ sites |
| h8mail | pip | Breach data lookup |
| GHunt | GitHub | Google account profiling from email |
| Infoga | GitHub | Email information gathering |
| EmailHarvester | GitHub | Email harvesting via search engines |
| Buster | GitHub | Email OSINT and verification |
| email2phonenumber | GitHub | Link emails to phone numbers |
| EMAGNET | GitHub | Exposed credential harvesting |
| Mosint | GitHub | Fast email OSINT (Go) |

---

### Phone Number OSINT
Carrier lookups, country/region data, linked account discovery.

| Tool | Source | Description |
|---|---|---|
| PhoneInfoga | apt | Advanced phone number recon |
| Ignorant | pip | Check if number is linked to accounts |
| OSINT-Phone | GitHub | Multi-source phone lookup |
| Callerspy | GitHub | Caller identity research |
| Numspy | GitHub | Phone number intelligence |
| TelSearch | GitHub | Telegram number lookup |

---

### Social Media OSINT
Platform-specific tools for Instagram, Twitter, LinkedIn, TikTok, Reddit, Telegram.

| Tool | Source | Description |
|---|---|---|
| Instaloader | apt | Instagram profile/post downloader |
| Tinfoleak | apt | Twitter intelligence |
| Twint | GitHub | Twitter scraping without API |
| Toutatis | GitHub | Instagram account info via API |
| Osintgram | GitHub | Instagram OSINT toolkit |
| Eyes | GitHub | Multi-platform social OSINT |
| Linkedin2Username | GitHub | LinkedIn username enumeration |
| Reddit OSINT | GitHub | Reddit user analysis |
| Stweet | GitHub | Twitter scraping library |
| Telegram OSINT | GitHub | Telegram research tools |
| TikTok OSINT | GitHub | TikTok profile research |

---

### Geolocation OSINT
Image geolocation, IP tracking, and location-based profiling.

| Tool | Source | Description |
|---|---|---|
| Creepy | apt | Geolocation from social media |
| GeoSpy | GitHub | AI-based image geolocation |
| Ipinfo CLI | GitHub | IP geolocation and ASN data (Go) |
| Carbon14 | GitHub | Website dating via resource timestamps |
| GeoRecon | GitHub | IP-based geolocation recon |
| IVRE | GitHub | Network recon and mapping platform |

---

### Metadata OSINT
Extract hidden metadata from documents, images, and PDFs.

| Tool | Source | Description |
|---|---|---|
| ExifTool | apt | Read/write metadata from any file |
| Metagoofil | apt | Metadata extraction from public documents |
| Exifgrab | GitHub | EXIF data extraction and analysis |
| MetaFinder | GitHub | Metadata from Google-indexed documents |
| PDF-OSINT | GitHub | Author and identity data from PDFs |

---

### Web Recon (Supplementary)
Lighter footprint — just enough for supporting people OSINT.

| Tool | Source | Description |
|---|---|---|
| Amass | apt | Subdomain enumeration |
| Sublist3r | apt | Fast subdomain brute-forcing |
| DNSrecon | apt | DNS enumeration |
| Whois | apt | Domain registration lookup |
| Nmap | apt | Network/service discovery |
| Shodan CLI | GitHub | Shodan search from terminal |
| Waybackpy | GitHub | Wayback Machine API wrapper |
| Photon | pip | OSINT-focused web crawler |

---

### Frameworks & Platforms
All-in-one OSINT orchestration tools.

| Tool | Source | Description |
|---|---|---|
| SpiderFoot | apt | Multi-source automated OSINT |
| OpenCTI Client | GitHub | Threat intelligence platform client |
| IntelOwl Client | GitHub | OSINT analysis platform API |
| OSINTer | GitHub | Automated OSINT collection |
| Datasploit | GitHub | Multi-target OSINT framework |
| Mr.Holmes | GitHub | All-in-one recon toolkit |
| Maltego TRX | GitHub | Maltego transform library |

---

## File Structure

```
/opt/osint/
├── people/
├── username/
├── email/
├── phone/
├── social/
├── geo/
├── metadata/
├── web/
├── framework/
└── venvs/          ← isolated Python environments per tool

/usr/local/bin/     ← auto-generated launchers for cloned tools
/etc/profile.d/osint.sh  ← PATH additions
/var/log/osint_installer_<timestamp>.log
```

---

## Notes

- Tools with a `main.py` or obvious entry point get an auto-generated launcher in `/usr/local/bin/` so you can call them directly by name.
- Tools written in Go (`Mosint`, `PhoneInfoga`, `Ipinfo`) require `golang-go` — installed automatically in base deps.
- `Sn0int` requires Rust (`cargo`) — the script attempts to build it but won't abort if it fails.
- After install, either re-login or run `source /etc/profile.d/osint.sh` to update your PATH.
- Some tools (GHunt, Twint, Osintgram) require API keys or credentials at runtime — check each tool's own docs.

---

## Troubleshooting

### Script exits silently after "Base Dependencies"

Caused by `set -e` killing the script when any command returns non-zero. Check what actually failed:

```bash
cat /var/log/osint_installer_*.log | tail -30
```

To skip apt and only install GitHub/pip tools:

```bash
sudo bash osint_installer.sh --skip-apt
```

---

### `error: externally-managed-environment` (PEP 668)

Kali's Python 3.13 blocks system-wide `pip install` by default. You'll see this error if the script tries to install pip packages outside a venv.

**Fix 1 — patch the script in place:**

```bash
sudo sed -i \
  's/pip3 install --quiet --upgrade pip setuptools wheel/pip3 install --quiet --upgrade pip setuptools wheel --break-system-packages/' \
  osint_installer.sh
```

Then in the `pip_install` function, add `--break-system-packages` to the pip call for installs that run outside a venv (i.e. when no `$venv` argument is passed).

**Fix 2 — use pipx for standalone tools (cleaner):**

```bash
sudo apt install pipx -y
pipx install holehe
pipx install maigret
pipx install h8mail
# etc.
```

`pipx` automatically manages a venv per tool and adds launchers to `~/.local/bin`.

**Fix 3 — force it (fine on a dedicated Kali box):**

```bash
pip3 install <package> --break-system-packages
```

This won't break anything if this machine is solely for OSINT work and you're not using the system Python for anything else.

---

### Go tools fail to build (`Mosint`, `PhoneInfoga`, `Ipinfo`)

Make sure `golang-go` is installed and `$GOPATH` is set:

```bash
sudo apt install golang-go -y
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin
```

Then re-run with `--category email` or `--category phone` to retry just that category.

---

### Rust tools fail to build (`Sn0int`)

Install the Rust toolchain via rustup (the `rustc` from apt is often too old):

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source "$HOME/.cargo/env"
```

Then manually build:

```bash
cd /opt/osint/people/Sn0int
cargo build --release
```

---

### A specific tool failed but everything else installed fine

The script records per-tool results and won't abort on individual failures. Check the summary printed at the end, then look up the specific error in the log:

```bash
grep -A5 "tool-name" /var/log/osint_installer_*.log
```

---

## Legal

These tools are for **authorized security research, OSINT investigations, and CTF challenges only**. Using them against systems or individuals without explicit permission is illegal. You are responsible for how you use this.
