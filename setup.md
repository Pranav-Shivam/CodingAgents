# Setup

## Detect your OS

```bash
uname -s
# Darwin  → macOS
# Linux   → Linux
# *_NT*   → Windows (Git Bash / WSL)
```

Or on Windows PowerShell:
```powershell
[System.Environment]::OSVersion.Platform
```

---

## Prerequisites

| Tool | Install |
|------|---------|
| [Claude Code](https://docs.anthropic.com/en/docs/claude-code) | `npm install -g @anthropic-ai/claude-code` |
| Git | [git-scm.com](https://git-scm.com) |
| Node.js 18+ | [nodejs.org](https://nodejs.org) |
| Python 3.9+ | [python.org](https://python.org) |

---

## Clone

```bash
git clone https://github.com/Pranav-Shivam/CodingAgents.git
cd CodingAgents
```

---

## Install auto-terminal into your project

Run from the cloned repo root, passing your target project directory:

### macOS / Linux

```bash
bash install.sh /path/to/your/project
```

### Windows (Git Bash)

```bash
bash install.sh "C:/path/to/your/project"
```

### Windows (PowerShell)

```powershell
bash install.sh "$env:USERPROFILE\your-project"
```

Omit the path to install into the current directory:

```bash
bash install.sh
```

What `install.sh` does:
- Creates `.claude/commands/`, `.claude/scripts/`, `.claude/logs/`, `reports/`
- Copies `auto-terminal.md`, `spawn-subagent.sh`, `notify.sh`, `report-template.md`
- Appends the `## auto-terminal` section to `CLAUDE.md`
- Adds runtime artifacts to `.gitignore`

---

## Security scan dependencies

The `/security-scan` skill dispatches 10 subagents. Install their tools:

### macOS

```bash
# Python tools
pip install bandit semgrep pip-audit safety detect-secrets

# Node tools (in your project)
npm install --save-dev

# Container / IaC
pip install checkov

# Secrets scanning
brew install trufflehog gitleaks

# TLS
pip install sslyze
```

### Linux (Debian / Ubuntu)

```bash
# Python tools
pip install bandit semgrep pip-audit safety detect-secrets checkov sslyze

# Secrets scanning
curl -sSfL https://raw.githubusercontent.com/trufflesecurity/trufflehog/main/scripts/install.sh | sh -s -- -b /usr/local/bin
curl -sSfL https://raw.githubusercontent.com/zricethezav/gitleaks/master/scripts/install.sh | sh -s -- -b /usr/local/bin
```

### Windows (PowerShell / Git Bash)

```powershell
# Python tools
pip install bandit semgrep pip-audit safety detect-secrets checkov sslyze

# Secrets scanning — download binaries from GitHub releases
# trufflehog: https://github.com/trufflesecurity/trufflehog/releases
# gitleaks:   https://github.com/zricethezav/gitleaks/releases
# Add both to PATH
```

---

## Verify install

```bash
# auto-terminal scripts present
ls .claude/scripts/spawn-subagent.sh .claude/scripts/notify.sh

# security tools
bandit --version
semgrep --version
pip-audit --version
checkov --version
trufflehog --version
gitleaks version
```

---

## Usage

```
# Spawn autonomous child agent
/auto-terminal <task description>

# Run full security scan
/security-scan
```

Reports land in `reports/<slug>-report.md`.
