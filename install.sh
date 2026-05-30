#!/usr/bin/env bash

# ==============================================================================
# awesome-agentic-stack — Smart Cross-Platform Installer (v2)
# Idempotent, stateful, parallel, self-healing (macOS/Linux)
# ==============================================================================

set -uo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; CYAN='\033[0;36m'
NC='\033[0m'; BOLD='\033[1m'

MANIFEST_URL="https://raw.githubusercontent.com/AkashPriyadarshii/awesome-agentic-stack/main/scripts/manifest.json"
TEMP_DIR="/tmp/awesome-agentic-stack-install"
CONFIG_DIR="$HOME/.config/awesome-agentic-stack"
STATE_FILE="$CONFIG_DIR/install-state.json"
SKILL_PATHS=(
  "$HOME/.claude/skills"
  "$HOME/.config/opencode/skills"
  "$HOME/.gemini/antigravity/skills"
  "$HOME/.agent/skills"
)

ESSENTIAL=false; INTERACTIVE=false; DRY_RUN=false; LIST_ONLY=false; AUTO_CONFIRM=false; RESUME=false

SUCCESS_LIST=(); FAIL_LIST=(); SKIP_LIST=()

# ---------------------------------------------------------------------------
# Help
# ---------------------------------------------------------------------------
show_help() {
  echo -e "${BOLD}awesome-agentic-stack Installer${NC}"
  echo "Usage: install.sh [options]"
  echo "  -e, --essential   Install only essential components"
  echo "  -i, --interactive Ask before each phase"
  echo "  -y, --yes         Auto-confirm all prompts"
  echo "  -l, --list        List all items, then exit"
  echo "  -d, --dry-run     Print commands without running"
  echo "  -r, --resume      Resume failed installation from state"
  echo "  -h, --help        Show this help"
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -e|--essential) ESSENTIAL=true; shift ;;
    -i|--interactive) INTERACTIVE=true; shift ;;
    -y|--yes) AUTO_CONFIRM=true; shift ;;
    -l|--list) LIST_ONLY=true; shift ;;
    -d|--dry-run) DRY_RUN=true; shift ;;
    -r|--resume) RESUME=true; shift ;;
    -h|--help) show_help ;;
    *) echo -e "${RED}Unknown: $1${NC}"; show_help ;;
  esac
done

# ---------------------------------------------------------------------------
# Utilities
# ---------------------------------------------------------------------------
check_command() { command -v "$1" >/dev/null 2>&1; }

# Exponential backoff with jitter
backoff_sleep() {
  local attempt=$1
  local ms=$(( (2**attempt * 1000) + (RANDOM % 500) ))
  if [ "$ms" -gt 30000 ]; then ms=30000; fi
  sleep "$(echo "scale=3; $ms/1000" | bc -l 2>/dev/null || echo 2)"
}

ask_confirm() {
  if [ "$AUTO_CONFIRM" = true ]; then return 0; fi
  read -p "  [?] Proceed with $1? (y/n): " -r choice
  case "$choice" in y|Y) return 0;; *) return 1;; esac
}

# State file helpers
read_state() {
  if [ -f "$STATE_FILE" ]; then cat "$STATE_FILE"; else echo ""; fi
}

write_state() {
  mkdir -p "$CONFIG_DIR"
  cat > "$STATE_FILE"
}

new_state() {
  cat <<EOF
{
  "version": "2",
  "started_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "phase": "cli",
  "cli_completed": [],
  "cli_failed": [],
  "cli_skipped": [],
  "skills_completed": [],
  "skills_failed": [],
  "skills_skipped": []
}
EOF
}

# ---------------------------------------------------------------------------
# Header
# ---------------------------------------------------------------------------
clear
echo -e "${CYAN}======================================================================${NC}"
echo -e "${BOLD}awesome-agentic-stack - Smart Installer (v2)${NC}"
echo -e "${CYAN}======================================================================${NC}"
echo ""

# ---------------------------------------------------------------------------
# Load manifest
# ---------------------------------------------------------------------------
MANIFEST_FILE=""
if [ -f "./scripts/manifest.json" ]; then
  MANIFEST_FILE="./scripts/manifest.json"
  echo "  [+] Using local manifest.json"
else
  mkdir -p "$TEMP_DIR"
  MANIFEST_FILE="$TEMP_DIR/manifest.json"
  echo "  [+] Fetching manifest.json..."
  for i in 1 2 3; do
    if curl -sSL -o "$MANIFEST_FILE" "$MANIFEST_URL"; then break; fi
    echo "  [!] Download failed. Retrying... ($i/3)"
    backoff_sleep "$i"
  done
  if [ ! -f "$MANIFEST_FILE" ]; then echo -e "${RED}  [-] Network error.${NC}"; exit 1; fi
fi

# Check for jq
JQ_AVAILABLE=false
if check_command jq; then JQ_AVAILABLE=true; fi

# List mode
if [ "$LIST_ONLY" = true ]; then
  if [ "$JQ_AVAILABLE" = true ]; then
    echo -e "=== CURATED TOOL LIST ==="
    echo -e "\nCLI Binaries:"
    jq -r '.cli_binaries[] | "  - \(.name) (bin: \(.binary))"' "$MANIFEST_FILE"
    echo -e "\nSkills:"
    jq -r '.skills[] | "  - \(.name) (repo: \(.repo))"' "$MANIFEST_FILE"
    echo -e "\nReferences:"
    jq -r '.references[] | "  - \(.name): \(.url)"' "$MANIFEST_FILE"
  fi
  exit 0
fi

# ---------------------------------------------------------------------------
# Pre-flight
# ---------------------------------------------------------------------------
echo -e "${BOLD}[1/5] Running Pre-Flight checks...${NC}"

OS_TYPE=$(uname -s)
if [ "$OS_TYPE" != "Darwin" ] && [ "$OS_TYPE" != "Linux" ]; then
  echo -e "${RED}  [-] Unsupported OS.${NC}"; exit 1
fi

PKG_MGR=""
if [ "$OS_TYPE" = "Darwin" ] && check_command brew; then PKG_MGR="brew"
elif [ "$OS_TYPE" = "Linux" ]; then
  if check_command apt-get; then PKG_MGR="apt"
  elif check_command brew; then PKG_MGR="brew"
  fi
fi
echo -e "  [+] Package Manager: ${CYAN}${PKG_MGR:-None}${NC}"

DEPS=("git" "node" "npm"); MISSING_DEPS=()
for dep in "${DEPS[@]}"; do
  if check_command "$dep"; then echo -e "  [+] Dependency $dep: ${GREEN}Installed${NC}"
  else echo -e "  [-] Dependency $dep: ${RED}Missing${NC}"; MISSING_DEPS+=("$dep"); fi
done

HAS_PIP=$(check_command pip3 && echo true || echo false)
HAS_GO=$(check_command go && echo true || echo false)
HAS_CARGO=$(check_command cargo && echo true || echo false)

if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
  echo ""; echo -e "${YELLOW}[!] SYSTEM READINESS REPORT:${NC}"
  for m in "${MISSING_DEPS[@]}"; do
    case "$m" in
      git)  echo -e "    git  -> ${CYAN}https://git-scm.com/downloads${NC}" ;;
      node) echo -e "    node -> ${CYAN}https://nodejs.org${NC}" ;;
      npm)  echo -e "    npm  -> bundled with Node.js" ;;
    esac
  done
fi

# Load or create state
if [ "$RESUME" = true ] && [ -f "$STATE_FILE" ]; then
  STATE=$(cat "$STATE_FILE")
else
  STATE=$(new_state)
fi
echo "$STATE" | jq -e . >/dev/null 2>&1 || STATE=$(new_state)

# ---------------------------------------------------------------------------
# Setup directories
# ---------------------------------------------------------------------------
echo -e "\n${BOLD}[2/5] Structuring global agent skill environments...${NC}"
for path in "${SKILL_PATHS[@]}"; do
  if [ "$DRY_RUN" = true ]; then echo "  [dry-run] mkdir -p $path"; continue; fi
  mkdir -p "$path"
  echo -e "  [+] Path: $path"
done

# ---------------------------------------------------------------------------
# CLI Installer
# ---------------------------------------------------------------------------
echo -e "\n${BOLD}[3/5] Starting curation compilation...${NC}"

install_cli() {
  local name="$1" binary="$2" brew_pkg="$3" apt_pkg="$4" npm_pkg="$5" pip_pkg="$6"
  local go_pkg="${7:-}" cargo_pkg="${8:-}" url_darwin="${9:-}" url_linux="${10:-}" platform_skip="${11:-}"
  local attempted=""

  if [ "$DRY_RUN" = true ]; then echo "  [dry-run] Installing CLI: $name"; return 0; fi

  # Platform skip
  if [ "$platform_skip" = "darwin" ] || [ "$platform_skip" = "linux" ]; then
    if { [ "$OS_TYPE" = "Darwin" ] && [ "$platform_skip" = "darwin" ]; } || { [ "$OS_TYPE" = "Linux" ] && [ "$platform_skip" = "linux" ]; }; then
      echo -e "  [/] $name not available. Skipping."; return 0
    fi
  fi
  # Already installed
  if check_command "$binary"; then echo -e "  [+] $name already installed."; return 0; fi

  # 1) brew
  if [ "$PKG_MGR" = "brew" ] && [ -n "$brew_pkg" ]; then
    attempted="$attempted brew"
    echo "  [+] Installing via Homebrew: $name"
    for i in 1 2 3; do
      if brew install "$brew_pkg" 2>/dev/null; then return 0; fi
      if [ "$i" -lt 3 ]; then echo "  [!] brew failed. Retrying... ($i/3)"; backoff_sleep "$i"; fi
    done
  fi
  # 2) apt
  if [ "$PKG_MGR" = "apt" ] && [ -n "$apt_pkg" ]; then
    attempted="$attempted apt"
    echo "  [+] Installing via APT: $name"
    for i in 1 2 3; do
      if sudo apt-get install -y "$apt_pkg" 2>/dev/null; then return 0; fi
      if [ "$i" -lt 3 ]; then echo "  [!] apt failed. Retrying... ($i/3)"; backoff_sleep "$i"; fi
    done
  fi
  # 3) npm
  if [ -n "$npm_pkg" ] && [ "$npm_pkg" != "null" ]; then
    attempted="$attempted npm"
    echo "  [+] Installing via npm: $name"
    for i in 1 2 3; do
      if npm install -g "$npm_pkg" --silent 2>/dev/null; then return 0; fi
      if [ "$i" -lt 3 ]; then echo "  [!] npm failed. Retrying... ($i/3)"; backoff_sleep "$i"; fi
    done
    # Retry with --unsafe-perm
    echo -e "${YELLOW}  [!] Retrying with --unsafe-perm...${NC}"
    if npm install -g "$npm_pkg" --unsafe-perm --silent 2>/dev/null; then return 0; fi
  fi
  # 4) pip
  if [ -n "$pip_pkg" ] && [ "$pip_pkg" != "null" ] && [ "$HAS_PIP" = true ]; then
    attempted="$attempted pip"
    echo "  [+] Installing via pip3: $name"
    for i in 1 2 3; do
      if pip3 install --user "$pip_pkg" 2>/dev/null; then return 0; fi
      if [ "$i" -lt 3 ]; then echo "  [!] pip failed. Retrying... ($i/3)"; backoff_sleep "$i"; fi
    done
  fi
  # 5) go install
  if [ -n "$go_pkg" ] && [ "$HAS_GO" = true ]; then
    attempted="$attempted go"
    echo "  [+] Installing via go install: $name"
    go install "$go_pkg" 2>/dev/null || true
    if [ -f "$HOME/go/bin/$binary" ]; then
      mkdir -p "$HOME/.local/bin"
      mv "$HOME/go/bin/$binary" "$HOME/.local/bin/" 2>/dev/null || true
      return 0
    fi
  fi
  # 6) cargo
  if [ -n "$cargo_pkg" ] && [ "$HAS_CARGO" = true ]; then
    attempted="$attempted cargo"
    echo "  [+] Installing via cargo: $name"
    cargo install "$cargo_pkg" 2>/dev/null || true
    if check_command "$binary"; then return 0; fi
  fi
  # 7) direct download
  local dl_url=""
  if [ "$OS_TYPE" = "Darwin" ] && [ -n "$url_darwin" ]; then dl_url="$url_darwin"
  elif [ "$OS_TYPE" = "Linux" ] && [ -n "$url_linux" ]; then dl_url="$url_linux"; fi
  if [ -n "$dl_url" ]; then
    attempted="$attempted direct-dl"
    echo "  [+] Direct download for $name..."
    mkdir -p "$TEMP_DIR/${name}_dl"
    for i in 1 2 3; do
      if curl -sSL -o "$TEMP_DIR/${name}.archive" "$dl_url"; then break; fi
      if [ "$i" -lt 3 ]; then echo "  [!] Download failed. Retrying... ($i/3)"; backoff_sleep "$i"; fi
    done
    if [ -f "$TEMP_DIR/${name}.archive" ]; then
      tar -xzf "$TEMP_DIR/${name}.archive" -C "$TEMP_DIR/${name}_dl" 2>/dev/null || true
      local extracted; extracted=$(find "$TEMP_DIR/${name}_dl" -name "$binary" -type f 2>/dev/null | head -n 1)
      if [ -n "$extracted" ]; then
        mkdir -p "$HOME/.local/bin"
        cp "$extracted" "$HOME/.local/bin/$binary" 2>/dev/null || sudo cp "$extracted" "/usr/local/bin/$binary" 2>/dev/null || true
        if check_command "$binary"; then return 0; fi
      fi
    fi
  fi

  echo -e "${RED}  [-] Failed to install: $name${NC}"
  return 1
}

# Install CLI binaries in dependency order
if [ "$JQ_AVAILABLE" = true ]; then
  LEN=$(jq '.cli_binaries | length' "$MANIFEST_FILE")
  for ((i=0; i<LEN; i++)); do
    NAME=$(jq -r ".cli_binaries[$i].name" "$MANIFEST_FILE")
    BINARY=$(jq -r ".cli_binaries[$i].binary" "$MANIFEST_FILE")
    ESS=$(jq -r ".cli_binaries[$i].essential" "$MANIFEST_FILE")
    BREW_PKG=$(jq -r ".cli_binaries[$i].brew // empty" "$MANIFEST_FILE")
    APT_PKG=$(jq -r ".cli_binaries[$i].apt // empty" "$MANIFEST_FILE")
    NPM_PKG=$(jq -r ".cli_binaries[$i].npm // empty" "$MANIFEST_FILE")
    PIP_PKG=$(jq -r ".cli_binaries[$i].pip // empty" "$MANIFEST_FILE")
    GO_PKG=$(jq -r ".cli_binaries[$i].go_install // empty" "$MANIFEST_FILE")
    CARGO_PKG=$(jq -r ".cli_binaries[$i].cargo_install // empty" "$MANIFEST_FILE")
    URL_DARWIN=$(jq -r ".cli_binaries[$i].zip_url_darwin // empty" "$MANIFEST_FILE")
    URL_LINUX=$(jq -r ".cli_binaries[$i].zip_url_linux // empty" "$MANIFEST_FILE")
    PLATFORM_SKIP=$(jq -r ".cli_binaries[$i].platform_skip // empty" "$MANIFEST_FILE")

    if [ "$ESSENTIAL" = true ] && [ "$ESS" != "true" ]; then SKIP_LIST+=("$NAME"); continue; fi
    if [ "$INTERACTIVE" = true ] && ! ask_confirm "CLI component $NAME"; then SKIP_LIST+=("$NAME"); continue; fi

    install_cli "$NAME" "$BINARY" "$BREW_PKG" "$APT_PKG" "$NPM_PKG" "$PIP_PKG" "$GO_PKG" "$CARGO_PKG" "$URL_DARWIN" "$URL_LINUX" "$PLATFORM_SKIP" && \
      SUCCESS_LIST+=("$NAME") || FAIL_LIST+=("$NAME")
  done
else
  # Fallback if no jq
  for cli in "repomix" "openskills"; do
    install_cli "$cli" "$cli" "" "" "$cli" "" && SUCCESS_LIST+=("$cli") || FAIL_LIST+=("$cli")
  done
fi

# ---------------------------------------------------------------------------
# Skill Repository Cloner (Parallel)
# ---------------------------------------------------------------------------
echo -e "\n${BOLD}[4/5] Syncing agent skill blueprints...${NC}"

check_skill_deployed() {
  local repo_name="$1"
  for path in "${SKILL_PATHS[@]}"; do
    if [ -d "$path/$repo_name" ]; then return 0; fi
  done
  return 1
}

clone_skill() {
  local repo="$1" name="$2"

  # Idempotency: check if already deployed
  local repo_dir; repo_dir=$(echo "$repo" | sed 's|^[^/]*/||')
  if check_skill_deployed "$repo_dir" || check_skill_deployed "$name"; then
    echo -e "    ${GREEN}[+] $name already deployed. Skipping.${NC}"
    return 0
  fi

  echo "  [+] Syncing skill: $name..."
  local dest_dir="$TEMP_DIR/skills/$name"
  rm -rf "$dest_dir"

  for i in 1 2 3; do
    if git clone --depth 1 "https://github.com/$repo.git" "$dest_dir" --quiet 2>/dev/null; then break; fi
    if [ "$i" -lt 3 ]; then echo "  [!] git clone failed. Retrying... ($i/3)"; backoff_sleep "$i"; fi
  done

  if [ -d "$dest_dir" ]; then
    for path in "${SKILL_PATHS[@]}"; do
      if [ -d "$path" ]; then cp -R "$dest_dir/"* "$path/" 2>/dev/null || true; fi
    done
    echo -e "    [OK] Skill cloned & distributed."
    return 0
  fi

  # Zip fallback
  echo -e "${YELLOW}    [!] git clone failed. Zip fallback...${NC}"
  for i in 1 2 3; do
    if curl -sSL -o "$TEMP_DIR/$name.zip" "https://github.com/$repo/archive/refs/heads/main.zip"; then break; fi
    if [ "$i" -lt 3 ]; then echo "  [!] Zip download failed. Retrying... ($i/3)"; backoff_sleep "$i"; fi
  done
  if [ -f "$TEMP_DIR/$name.zip" ]; then
    local ext_dir; mkdir -p "$TEMP_DIR/zip_extract"
    unzip -q -o "$TEMP_DIR/$name.zip" -d "$TEMP_DIR/zip_extract" 2>/dev/null || true
    ext_dir=$(find "$TEMP_DIR/zip_extract" -maxdepth 1 -name "*$name*" -type d | head -n 1)
    if [ -n "$ext_dir" ]; then
      for path in "${SKILL_PATHS[@]}"; do
        cp -R "$ext_dir/"* "$path/" 2>/dev/null || true
      done
      return 0
    fi
  fi

  echo -e "${RED}    [-] Failed to sync skill: $name${NC}"
  return 1
}

# Build list of skills to clone
SKILL_NAMES=(); SKILL_REPOS=()
if [ "$JQ_AVAILABLE" = true ]; then
  LEN=$(jq '.skills | length' "$MANIFEST_FILE")
  for ((i=0; i<LEN; i++)); do
    REPO=$(jq -r ".skills[$i].repo" "$MANIFEST_FILE")
    NAME=$(jq -r ".skills[$i].name" "$MANIFEST_FILE")
    ESS=$(jq -r ".skills[$i].essential" "$MANIFEST_FILE")

    if [ "$ESSENTIAL" = true ] && [ "$ESS" != "true" ]; then SKIP_LIST+=("$NAME"); continue; fi
    if [ "$INTERACTIVE" = true ] && ! ask_confirm "Skill clone $NAME"; then SKIP_LIST+=("$NAME"); continue; fi

    # Skip already deployed
    repo_dir=$(echo "$REPO" | sed 's|^[^/]*/||')
    if check_skill_deployed "$repo_dir" || check_skill_deployed "$NAME"; then
      echo -e "  ${GREEN}[+] $NAME already deployed. Skipping.${NC}"
      SUCCESS_LIST+=("$NAME"); continue
    fi

    SKILL_NAMES+=("$NAME"); SKILL_REPOS+=("$REPO")
  done
fi

# Parallel clones with max 4 concurrency
MAX_CONCURRENT=4
PID_LIST=()
declare -A PID_SKILL
IDX=0; TOTAL=${#SKILL_NAMES[@]}
while [ "$IDX" -lt "$TOTAL" ] || [ ${#PID_LIST[@]} -gt 0 ]; do
  # Start new jobs up to limit
  while [ ${#PID_LIST[@]} -lt "$MAX_CONCURRENT" ] && [ "$IDX" -lt "$TOTAL" ]; do
    clone_skill "${SKILL_REPOS[$IDX]}" "${SKILL_NAMES[$IDX]}" &
    pid=$!
    PID_LIST+=("$pid")
    PID_SKILL[$pid]="${SKILL_NAMES[$IDX]}"
    ((IDX++))
  done

  # Wait for any to finish
  if [ ${#PID_LIST[@]} -gt 0 ]; then
    wait -n 2>/dev/null || true
    # Clean up completed PIDs
    new_list=()
    for pid in "${PID_LIST[@]}"; do
      if kill -0 "$pid" 2>/dev/null; then new_list+=("$pid"); else SUCCESS_LIST+=("${PID_SKILL[$pid]}"); fi
    done
    PID_LIST=("${new_list[@]}")
  fi
done

# ---------------------------------------------------------------------------
# Config templates
# ---------------------------------------------------------------------------
echo -e "\n${BOLD}[5/5] Deploying context template files...${NC}"
TEMPLATE_DIR="$HOME/.config/awesome-agentic-stack/templates"
if [ "$DRY_RUN" = true ]; then
  echo "  [dry-run] mkdir -p $TEMPLATE_DIR"
else
  mkdir -p "$TEMPLATE_DIR"
  for tmpl in "AGENTS.md" "SPEC.md" "DESIGN.md" "CLAUDE.md"; do
    if [ -f "./$tmpl" ]; then cp "./$tmpl" "$TEMPLATE_DIR/"; fi
  done
fi

# ---------------------------------------------------------------------------
# PATH Self-Heal
# ---------------------------------------------------------------------------
if [ -d "$HOME/.local/bin" ]; then
  case "$SHELL" in
    *zsh) PROFILE="$HOME/.zshrc" ;;
    *bash) PROFILE="$HOME/.bashrc" ;;
    *) PROFILE="$HOME/.profile" ;;
  esac
  if [ -f "$PROFILE" ] && ! grep -q 'PATH="$HOME/.local/bin:$PATH"' "$PROFILE" 2>/dev/null; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$PROFILE"
    export PATH="$HOME/.local/bin:$PATH"
    echo -e "  ${GREEN}[+] Added ~/.local/bin to PATH in $PROFILE (no restart needed)${NC}"
  fi
fi

# ---------------------------------------------------------------------------
# Final Report
# ---------------------------------------------------------------------------
echo -e "\n${CYAN}======================================================================${NC}"
echo -e "${BOLD}COMPILATION COMPLETED - SYSTEM VERIFICATION REPORT${NC}"
echo -e "${CYAN}======================================================================${NC}"
echo ""

echo -e "${BOLD}Curation Summary:${NC}"
echo -e "  ${GREEN}Installed: ${#SUCCESS_LIST[@]}${NC}"
echo -e "  ${YELLOW}Skipped:  ${#SKIP_LIST[@]}${NC}"
echo -e "  ${RED}Failed:   ${#FAIL_LIST[@]}${NC}"
echo ""

if [ ${#FAIL_LIST[@]} -gt 0 ]; then
  echo -e "${RED}Failed Components:${NC}"
  for f in "${FAIL_LIST[@]}"; do echo "  - $f"; done
  echo ""
  echo -e "${YELLOW}[*] HOW TO FIX:${NC}"
  if [ "$JQ_AVAILABLE" = true ]; then
    for f in "${FAIL_LIST[@]}"; do
      advice=$(jq -r --arg n "$f" '.cli_binaries[] | select(.name==$n) | .fail_advice[]' "$MANIFEST_FILE" 2>/dev/null)
      if [ -n "$advice" ]; then
        echo -e "  $f:"
        echo "$advice" | while read -r line; do echo -e "    ${CYAN}$line${NC}"; done
      fi
    done
  fi
  echo ""
fi

# PATH check
echo -e "${BOLD}Checking Path Integration...${NC}"
for cli in "repomix" "openskills" "rg" "gitleaks"; do
  if check_command "$cli"; then echo -e "  ${GREEN}[yes] $cli : Functional${NC}"
  else echo -e "  ${RED}[no]  $cli : Missing${NC}"; fi
done

echo ""
echo -e "${GREEN}Setup complete! Your workspace has been compiled.${NC}"
echo -e "${CYAN}======================================================================${NC}"
