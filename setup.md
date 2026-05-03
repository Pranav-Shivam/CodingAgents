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

## Install

### Option A — curl (no clone required)

**Global install** — agents and commands available in all projects (`~/.claude/`):

```bash
curl -fsSL https://raw.githubusercontent.com/Pranav-Shivam/CodingAgents/main/install.sh | bash
```

**Project-scoped install** — installs into current directory's `.claude/`:

```bash
curl -fsSL https://raw.githubusercontent.com/Pranav-Shivam/CodingAgents/main/install.sh | bash -s -- --project
```

### Option B — clone then install

```bash
git clone https://github.com/Pranav-Shivam/CodingAgents.git
cd CodingAgents

# Global (default)
bash install.sh

# Project-scoped into a specific directory
bash install.sh --project /path/to/your/project
```

### Windows (Git Bash)

```bash
curl -fsSL https://raw.githubusercontent.com/Pranav-Shivam/CodingAgents/main/install.sh | bash -s -- --project
```

### Windows (PowerShell)

```powershell
# Download then run
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Pranav-Shivam/CodingAgents/main/install.sh" -OutFile install.sh
bash install.sh --project
```

What `install.sh` does:
- Installs 11 security agents into `.claude/agents/`
- Installs 5 commands (`/security-scan`, `/auto-terminal`, `/git-commit`, `/pr-description`, `/learn`) into `.claude/commands/`
- Installs agentic coding rules into `.claude/rules/`
- Installs `spawn-subagent.sh`, `notify.sh` into `.claude/scripts/`
- Project mode also installs hooks and updates `.gitignore`

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
