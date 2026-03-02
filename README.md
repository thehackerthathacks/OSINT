OSINT Toolkit Installer

Overview
This repository contains a single installer script and a curated list of Python packages and OSINT tools useful for investigations, threat intelligence, and research. The goal is to give you a reproducible starting point so you can clone the repo and set up a usable toolkit quickly.

What you get
- install.sh: installer with minimal/full modes and an option to use a Python virtual environment.

Quick start
1. clone this repo
2. make the installer executable
   chmod +x install.sh
3. run one of:
   ./install.sh minimal
   ./install.sh full
   ./install.sh full --venv

Notes on flags
- minimal: installs the core Python packages from requirements.txt and clones a small set of repos.
- full: installs the entire requirements list and a longer set of repos.
- --venv: create and use a local virtual environment (.venv_osint). When using --venv the script will not pass --break-system-packages to pip.

Where tools are put
Cloned projects go to:
~/osint-tools

API keys and credentials
Several tools (Shodan, Censys, SerpAPI, SpiderFoot modules, etc.) require API keys to be useful. Configure API keys in the environment or per-tool configuration after installation. Do not check secrets into source control.

Permissions and system-wide installs
By default the script will perform system-wide pip installs using:
--break-system-packages
If you prefer isolation, use the --venv option. If you run system-wide installs, be aware of possible conflicts with your OS packages.

Security and acceptable use
Only use these tools for legitimate, authorized, and ethical work. Do not scan or collect data from systems without explicit permission. This toolkit is provided for education and authorized investigations.

Contributing and improvements
If you want this to live in a public repo, consider:
- splitting tools into optional groups (social, domain, metadata)
- adding a Dockerfile for a reproducible environment
- adding an API-key vault helper or .env template
- adding an interactive installer to choose groups

## License
Use at your own risk. For authorized, educational, or defensive purposes only.
