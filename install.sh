#!/usr/bin/env bash

# ==============================================================================
# awesome-agentic-stack — Robust Cross-Platform Installer (macOS/Linux)
# Curated by Akash Priyadarshi (MacBook Air M5 + Realme GT7 Developer Stack)
# ==============================================================================

set -uo pipefail

# Text Formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0;37m' # No Color
BOLD='\033[1m'

# Config
MANIFEST_URL="https://raw.githubusercontent.com/AkashPriyadarshii/awesome-agentic-stack/main/scripts/manifest.json"
TEMP_DIR="/tmp/awesome-agentic-stack-install"
SKILL_PATHS=(
  "$HOME/.claude/skills"
  "$HOME/.config/opencode/skills"
  "$HOME/.gemini/antigravity/skills"
  "$HOME/.agent/skills"
)

# Flags
ESSENTIAL=false
INTERACTIVE=false
DRY_RUN=false
LIST_ONLY=false
AUTO_CONFIRM=false
RESUME=false

# Setup state tracking
SUCCESS_LIST=()
FAIL_LIST=()
SKIP_LIST=()

# ------------------------------------------------------------------------------
# Help Menu
# ------------------------------------------------------------------------------
show_help() {
  echo -e "${BOLD}awesome-agentic-stack Installer${NC}"
  echo "Usage: install.sh [options]"
  echo ""
  echo "Options:"
  echo "  -e, --essential   Install only essential/core components (~30 items)"
  echo "  -i, --interactive Ask for confirmation before each major phase"
  echo "  -y, --yes         Auto-confirm all prompts (non-interactive)"
  echo "  -l, --list        List all items that will be installed, then exit"
  echo "  -d, --dry-run     Print commands without running them"
  echo "  -r, --resume      Resume a previously failed installation"
  echo "  -h, --help        Show this help message"
  exit 0
}

# Parse Args
while [[ $# -gt 0 ]]; do
  case "$1" in
    -e|--essential) ESSENTIAL=true; shift ;;
    -i|--interactive) INTERACTIVE=true; shift ;;
    -y|--yes) AUTO_CONFIRM=true; shift ;;
    -l|--list) LIST_ONLY=true; shift ;;
    -d|--dry-run) DRY_RUN=true; shift ;;
    -r|--resume) RESUME=true; shift ;;
    -h|--help) show_help ;;
    *) echo -e "${RED}Unknown option: $1${NC}"; show_help ;;
  esac
done

clear
echo -e "${CYAN}======================================================================${NC}"
echo -e "${BOLD}⚡ awesome-agentic-stack — Robust Installer (macOS/Linux) ⚡${NC}"
echo -e "${CYAN}======================================================================${NC}"
echo ""

# ------------------------------------------------------------------------------
# Robust Helper Utilities
# ------------------------------------------------------------------------------
check_command() {
  command -v "$1" >/dev/null 2>&1
}

retry_cmd() {
  local count=0
  local max=3
  local delay=2
  until "$@"; do
    if (( count == max )); then
      return 1
    fi
    (( count++ ))
    echo -e "${YELLOW}  [!] Command failed. Retrying in ${delay}s... ($count/$max)${NC}"
    sleep "$delay"
    delay=$(( delay * 2 ))
  done
}

ask_confirm() {
  if [ "$AUTO_CONFIRM" = true ]; then
    return 0
  fi
  read -p "  [?] Proceed with $1? (y/n): " -r choice
  case "$choice" in
    y|Y ) return 0 ;;
    * ) return 1 ;;
  esac
}

# ------------------------------------------------------------------------------
# Pre-Flight OS & Dependency Checks
# ------------------------------------------------------------------------------
echo -e "${BOLD}[1/5] Running Pre-Flight checks...${NC}"

OS_TYPE=$(uname -s)
echo -e "  [+] OS Detected: ${CYAN}$OS_TYPE${NC}"

if [ "$OS_TYPE" != "Darwin" ] && [ "$OS_TYPE" != "Linux" ]; then
  echo -e "${RED}  [-] Unsupported OS type. Exiting safely.${NC}"
  exit 1
fi

# Try to resolve manifest.json locally or download
MANIFEST_FILE=""
if [ -f "./scripts/manifest.json" ]; then
  MANIFEST_FILE="./scripts/manifest.json"
  echo "  [+] Using local manifest.json"
else
  mkdir -p "$TEMP_DIR"
  MANIFEST_FILE="$TEMP_DIR/manifest.json"
  echo "  [+] Fetching repository manifest.json..."
  if ! retry_cmd curl -sSL -o "$MANIFEST_FILE" "$MANIFEST_URL"; then
    echo -e "${RED}  [-] Network error: Failed to fetch manifest.json. Check connection.${NC}"
    exit 1
  fi
fi

# Ensure jq is installed or we use a fallback JSON parser
JQ_AVAILABLE=false
if check_command jq; then
  JQ_AVAILABLE=true
fi

# Core Package managers
PKG_MGR=""
if [ "$OS_TYPE" = "Darwin" ]; then
  if check_command brew; then
    PKG_MGR="brew"
  else
    echo -e "${YELLOW}  [!] Homebrew is missing. Attempting Homebrew setup...${NC}"
    if ask_confirm "Homebrew installation"; then
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || true
      if check_command brew; then PKG_MGR="brew"; fi
    fi
  fi
elif [ "$OS_TYPE" = "Linux" ]; then
  if check_command apt-get; then
    PKG_MGR="apt"
  elif check_command brew; then
    PKG_MGR="brew"
  fi
fi
echo -e "  [+] Selected Package Manager: ${CYAN}${PKG_MGR:-None}${NC}"

# Check essential core deps
DEPS=("git" "node" "npm")
MISSING_DEPS=()
for dep in "${DEPS[@]}"; do
  if check_command "$dep"; then
    echo -e "  [+] Dependency $dep: ${GREEN}Installed${NC}"
  else
    echo -e "  [-] Dependency $dep: ${RED}Missing${NC}"
    MISSING_DEPS+=("$dep")
    if [ "$PKG_MGR" = "brew" ]; then
      echo "  [+] Attempting to auto-install $dep via Homebrew..."
      retry_cmd brew install "$dep" || true
    elif [ "$PKG_MGR" = "apt" ]; then
      echo "  [+] Attempting to auto-install $dep via APT..."
      sudo apt-get update && sudo apt-get install -y "$dep" || true
    fi
  fi
done

# Check additional tooling
HAS_PIP=$(check_command pip3 && echo true || echo false)
HAS_GO=$(check_command go && echo true || echo false)
HAS_CARGO=$(check_command cargo && echo true || echo false)
HAS_CURL=$(check_command curl && echo true || echo false)

# Bootstrap: show advice for missing core deps
if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
  echo ""
  echo -e "${YELLOW}[!] SYSTEM READINESS REPORT:${NC}"
  echo -e "${YELLOW}  The following core dependencies are missing:${NC}"
  for m in "${MISSING_DEPS[@]}"; do
    case "$m" in
      git)  echo -e "    git  → ${CYAN}https://git-scm.com/downloads${NC}" ;;
      node) echo -e "    node → ${CYAN}https://nodejs.org${NC} (includes npm)" ;;
      npm)  echo -e "    npm  → bundled with Node.js (see above)" ;;
    esac
  done
  echo -e "${YELLOW}  Install missing deps, then re-run.${NC}"
  echo ""
fi

echo -e "  [+] Available methods: brew/apt + npm + pip3 + $( $HAS_GO && echo 'go +' )$( $HAS_CARGO && echo 'cargo +' )direct-dl"

# Setup directories
echo -e "\n${BOLD}[2/5] Structuring global agent skill environments...${NC}"
for path in "${SKILL_PATHS[@]}"; do
  if [ "$DRY_RUN" = true ]; then
    echo "  [dry-run] mkdir -p $path"
  else
    if mkdir -p "$path"; then
      echo -e "  [+] Path setup: ${GREEN}$path${NC}"
    else
      echo -e "  [!] Permission warning: Failed to create $path. Try with sudo."
    fi
  fi
done

# ------------------------------------------------------------------------------
# Installation Phase
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}[3/5] Starting curation compilation...${NC}"

# Define installer functions
install_cli() {
  local name="$1"
  local binary="$2"
  local brew_pkg="$3"
  local apt_pkg="$4"
  local npm_pkg="$5"
  local pip_pkg="$6"
  local go_pkg="${7:-}"
  local cargo_pkg="${8:-}"
  local url_darwin="${9:-}"
  local url_linux="${10:-}"
  local platform_skip="${11:-}"
  local attempted=""

  if [ "$DRY_RUN" = true ]; then
    echo "  [dry-run] Installing CLI: $name"
    return 0
  fi

  # Platform skip
  if [ "$platform_skip" = "darwin" ] || [ "$platform_skip" = "linux" ]; then
    if { [ "$OS_TYPE" = "Darwin" ] && [ "$platform_skip" = "darwin" ]; } || { [ "$OS_TYPE" = "Linux" ] && [ "$platform_skip" = "linux" ]; }; then
      echo -e "  [/] $name not available on $OS_TYPE. Skipping."
      SKIP_LIST+=("$name")
      return 0
    fi
  fi

  # Skip if already in PATH
  if check_command "$binary"; then
    echo -e "  [+] $name is already installed and in PATH."
    SUCCESS_LIST+=("$name")
    return 0
  fi

  # 1) Brew Install
  if [ "$PKG_MGR" = "brew" ] && [ -n "$brew_pkg" ]; then
    attempted="$attempted brew"
    echo "  [+] Installing via Homebrew: $name"
    if retry_cmd brew install "$brew_pkg"; then
      if check_command "$binary"; then SUCCESS_LIST+=("$name"); return 0; fi
    fi
  fi

  # 2) APT Install
  if [ "$PKG_MGR" = "apt" ] && [ -n "$apt_pkg" ]; then
    attempted="$attempted apt"
    echo "  [+] Installing via APT: $name"
    if retry_cmd sudo apt-get install -y "$apt_pkg"; then
      if check_command "$binary"; then SUCCESS_LIST+=("$name"); return 0; fi
    fi
  fi

  # 3) NPM Install
  if [ -n "$npm_pkg" ] && [ "$npm_pkg" != "null" ]; then
    attempted="$attempted npm"
    echo "  [+] Installing global NPM package: $name"
    if retry_cmd npm install -g "$npm_pkg" --silent; then
      SUCCESS_LIST+=("$name"); return 0
    else
      echo -e "${YELLOW}  [!] NPM global failed. Attempting with --unsafe-perm...${NC}"
      if retry_cmd npm install -g "$npm_pkg" --unsafe-perm --silent; then
        SUCCESS_LIST+=("$name"); return 0
      fi
    fi
  fi

  # 4) Pip Install
  if [ -n "$pip_pkg" ] && [ "$pip_pkg" != "null" ] && [ "$HAS_PIP" = true ]; then
    attempted="$attempted pip"
    echo "  [+] Installing via pip3: $name"
    if retry_cmd pip3 install --user "$pip_pkg"; then
      if check_command "$binary"; then SUCCESS_LIST+=("$name"); return 0; fi
    fi
  fi

  # 5) go install
  if [ -n "$go_pkg" ] && [ "$HAS_GO" = true ]; then
    attempted="$attempted go"
    echo "  [+] Installing via go install: $name"
    go install "$go_pkg" 2>/dev/null || true
    if [ -f "$HOME/go/bin/$binary" ]; then
      mkdir -p "$HOME/.local/bin"
      mv "$HOME/go/bin/$binary" "$HOME/.local/bin/" 2>/dev/null || true
      if check_command "$binary"; then SUCCESS_LIST+=("$name"); return 0; fi
    fi
  fi

  # 6) cargo install
  if [ -n "$cargo_pkg" ] && [ "$HAS_CARGO" = true ]; then
    attempted="$attempted cargo"
    echo "  [+] Installing via cargo: $name"
    cargo install "$cargo_pkg" 2>/dev/null || true
    if check_command "$binary"; then SUCCESS_LIST+=("$name"); return 0; fi
  fi

  # 7) Direct download fallback (zip/tar.gz)
  local dl_url=""
  if [ "$OS_TYPE" = "Darwin" ] && [ -n "$url_darwin" ]; then
    dl_url="$url_darwin"
  elif [ "$OS_TYPE" = "Linux" ] && [ -n "$url_linux" ]; then
    dl_url="$url_linux"
  fi
  if [ -n "$dl_url" ] && [ "$HAS_CURL" = true ]; then
    attempted="$attempted direct-dl"
    echo "  [+] Attempting direct download for $name..."
    mkdir -p "$TEMP_DIR/${name}_dl"
    if curl -sSL -o "$TEMP_DIR/${name}.archive" "$dl_url"; then
      local extracted_bin
      extracted_bin=$(find "$TEMP_DIR/${name}_dl" -name "$binary" -type f 2>/dev/null | head -n 1)
      if [ -z "$extracted_bin" ]; then
        tar -xzf "$TEMP_DIR/${name}.archive" -C "$TEMP_DIR/${name}_dl" 2>/dev/null || true
        extracted_bin=$(find "$TEMP_DIR/${name}_dl" -name "$binary" -type f 2>/dev/null | head -n 1)
      fi
      if [ -n "$extracted_bin" ]; then
        mkdir -p "$HOME/.local/bin"
        cp "$extracted_bin" "$HOME/.local/bin/$binary" 2>/dev/null || sudo cp "$extracted_bin" "/usr/local/bin/$binary" 2>/dev/null || true
        if check_command "$binary"; then SUCCESS_LIST+=("$name"); return 0; fi
      fi
    fi
  fi

  echo -e "${RED}  [-] Failed to install: $name${NC}"
  FAIL_LIST+=("$name|$attempted")
  return 1
}

# Parse and loop CLIs using manifest
if [ "$JQ_AVAILABLE" = true ]; then
  # Read manifest.json using jq
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

    if [ "$ESSENTIAL" = true ] && [ "$ESS" != "true" ]; then
      SKIP_LIST+=("$NAME")
      continue
    fi

    if [ "$INTERACTIVE" = true ]; then
      if ! ask_confirm "CLI component $NAME"; then
        SKIP_LIST+=("$NAME")
        continue
      fi
    fi

    install_cli "$NAME" "$BINARY" "$BREW_PKG" "$APT_PKG" "$NPM_PKG" "$PIP_PKG" "$GO_PKG" "$CARGO_PKG" "$URL_DARWIN" "$URL_LINUX" "$PLATFORM_SKIP"
  done
else
  # Minimal fallback parsing if jq is absent
  echo "  [!] jq not installed. Executing core CLI fallback script installations..."
  CORE_CLIS=("repomix" "openskills" "jscpd")
  for cli in "${CORE_CLIS[@]}"; do
    install_cli "$cli" "$cli" "null" "null" "$cli" "null"
  done
fi

# ------------------------------------------------------------------------------
# Skill Repository Cloner
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}[4/5] Syncing agent skill blueprints...${NC}"

clone_skill() {
  local repo="$1"
  local name="$2"

  if [ "$DRY_RUN" = true ]; then
    echo "  [dry-run] git clone https://github.com/$repo to skill directories"
    return 0
  fi

  echo "  [+] Syncing skill: $name..."
  local dest_dir="$TEMP_DIR/skills/$name"
  rm -rf "$dest_dir"

  # Clone with shallow depth
  if retry_cmd git clone --depth 1 "https://github.com/$repo.git" "$dest_dir" --quiet; then
    # Distribute files to directories
    for path in "${SKILL_PATHS[@]}"; do
      if [ -d "$path" ]; then
        cp -R "$dest_dir/"* "$path/" 2>/dev/null || true
      fi
    done
    echo -e "    ✓ Skill cloned & distributed successfully."
    SUCCESS_LIST+=("$name")
    return 0
  else
    # Fallback to direct file copy if zip download available
    echo -e "${YELLOW}    [!] git clone failed. Fetching via zip fallback...${NC}"
    if retry_cmd curl -sSL -o "$TEMP_DIR/$name.zip" "https://github.com/$repo/archive/refs/heads/main.zip"; then
      unzip -q -o "$TEMP_DIR/$name.zip" -d "$TEMP_DIR/zip_extract" || true
      # Find directory and distribute
      local extracted_dir; extracted_dir=$(find "$TEMP_DIR/zip_extract" -maxdepth 1 -name "*$name*" -type d | head -n 1)
      if [ -n "$extracted_dir" ]; then
        for path in "${SKILL_PATHS[@]}"; do
          cp -R "$extracted_dir/"* "$path/" 2>/dev/null || true
        done
        SUCCESS_LIST+=("$name")
        return 0
      fi
    fi
  fi

  echo -e "${RED}    [-] Failed to sync skill: $name${NC}"
  FAIL_LIST+=("$name")
  return 1
}

# Loop and clone skills
if [ "$JQ_AVAILABLE" = true ]; then
  LEN=$(jq '.skills | length' "$MANIFEST_FILE")
  for ((i=0; i<LEN; i++)); do
    REPO=$(jq -r ".skills[$i].repo" "$MANIFEST_FILE")
    NAME=$(jq -r ".skills[$i].name" "$MANIFEST_FILE")
    ESS=$(jq -r ".skills[$i].essential" "$MANIFEST_FILE")

    if [ "$ESSENTIAL" = true ] && [ "$ESS" != "true" ]; then
      SKIP_LIST+=("$NAME")
      continue
    fi

    if [ "$INTERACTIVE" = true ]; then
      if ! ask_confirm "Skill clone $NAME"; then
        SKIP_LIST+=("$NAME")
        continue
      fi
    fi

    clone_skill "$REPO" "$NAME"
  done
else
  # Core skill fallbacks
  clone_skill "obra/superpowers" "superpowers"
  clone_skill "affaan-m/ECC" "ecc"
  clone_skill "Leonxlnx/taste-skill" "taste-skill"
  clone_skill "blader/humanizer" "humanizer"
fi

# ------------------------------------------------------------------------------
# Config templates copy
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}[5/5] Deploying context template files...${NC}"
TEMPLATE_DIR="$HOME/.config/awesome-agentic-stack/templates"
if [ "$DRY_RUN" = true ]; then
  echo "  [dry-run] mkdir -p $TEMPLATE_DIR"
  echo "  [dry-run] Copying template context files"
else
  mkdir -p "$TEMPLATE_DIR"
  # Copy local context files to templates if they exist in repo root
  TEMPLATES=("AGENTS.md" "SPEC.md" "DESIGN.md" "CLAUDE.md")
  for tmpl in "${TEMPLATES[@]}"; do
    if [ -f "./$tmpl" ]; then
      cp "./$tmpl" "$TEMPLATE_DIR/"
      echo -e "  [+] Template deployed: ${GREEN}$tmpl${NC}"
    fi
  done
fi

# ------------------------------------------------------------------------------
# Final Verification Report
# ------------------------------------------------------------------------------
echo -e "\n${CYAN}======================================================================${NC}"
echo -e "${BOLD}📋 COMPILATION COMPLETED — SYSTEM VERIFICATION REPORT${NC}"
echo -e "${CYAN}======================================================================${NC}"
echo ""

echo -e "${BOLD}Curation Summary:${NC}"
echo -e "  Installed successfully: ${GREEN}${#SUCCESS_LIST[@]}${NC}"
echo -e "  Skipped/Declined:       ${YELLOW}${#SKIP_LIST[@]}${NC}"
echo -e "  Failed installations:   ${RED}${#FAIL_LIST[@]}${NC}"
echo ""

if [ ${#FAIL_LIST[@]} -gt 0 ]; then
  echo -e "${RED}${BOLD}Failed Components (Requires Manual Review):${NC}"
  for fail_entry in "${FAIL_LIST[@]}"; do
    fail_name="${fail_entry%%|*}"
    echo -e "  - $fail_name"
  done
  echo ""

  echo -e "${YELLOW}${BOLD}[*] HOW TO FIX FAILED COMPONENTS:${NC}"
  for fail_entry in "${FAIL_LIST[@]}"; do
    fail_name="${fail_entry%%|*}"
    case "$fail_name" in
      "ripgrep")
        echo -e "  rg (ripgrep):"
        echo -e "    ${CYAN}brew install ripgrep${NC} (macOS) / ${CYAN}sudo apt install ripgrep${NC} (Linux)"
        echo -e "    ${CYAN}Download: https://github.com/BurntSushi/ripgrep/releases${NC}"
        ;;
      "gitleaks")
        echo -e "  gitleaks:"
        echo -e "    ${CYAN}brew install gitleaks${NC} (macOS) / ${CYAN}go install github.com/gitleaks/gitleaks/v8@latest${NC} (any)"
        echo -e "    ${CYAN}Download: https://github.com/gitleaks/gitleaks/releases${NC}"
        ;;
      "trufflehog")
        echo -e "  trufflehog:"
        echo -e "    ${CYAN}brew install trufflehog${NC} (macOS) / ${CYAN}pip3 install trufflehog${NC} (any)"
        echo -e "    ${CYAN}go install github.com/trufflesecurity/trufflehog/v3@latest${NC}"
        ;;
      "tmux")
        echo -e "  tmux:"
        echo -e "    ${CYAN}brew install tmux${NC} (macOS) / ${CYAN}sudo apt install tmux${NC} (Linux)"
        ;;
      "localsend")
        echo -e "  localsend:"
        echo -e "    ${CYAN}brew install localsend${NC} (macOS) / snap or direct download"
        echo -e "    ${CYAN}Download: https://github.com/localsend/localsend/releases${NC}"
        ;;
      "sniffnet")
        echo -e "  sniffnet:"
        echo -e "    ${CYAN}brew install sniffnet${NC} (macOS) / ${CYAN}cargo install sniffnet${NC} (any)"
        echo -e "    ${CYAN}Download: https://github.com/GyulyVGC/sniffnet/releases${NC}"
        ;;
      *)
        echo -e "  $fail_name: Check https://github.com/AkashPriyadarshii/awesome-agentic-stack for manual instructions"
        ;;
    esac
  done
  echo ""
fi

# PATH Check
echo -e "${BOLD}Checking Path Integration...${NC}"
PATH_SUCCESS=true
CHECK_CLIS=("repomix" "openskills" "rg" "gitleaks")
for cli in "${CHECK_CLIS[@]}"; do
  if check_command "$cli"; then
    echo -e "  [yes] $cli : ${GREEN}Functional${NC}"
  else
    echo -e "  [no]  $cli : ${RED}Missing or requires shell restart${NC}"
    PATH_SUCCESS=false
  fi
done

if [ "$PATH_SUCCESS" = false ]; then
  echo ""
  echo -e "${YELLOW}${BOLD}⚠️ Action Required to Complete Setup:${NC}"
  echo "Some binaries were installed but are not yet loaded in your shell path."
  echo "Run this command to refresh your current environment:"
  echo -e "  ${BOLD}source ~/.bashrc || source ~/.zshrc${NC}"
fi

# References to open
echo ""
echo -e "${BOLD}🌐 26 SURVIVAL REFERENCE BLUEPRINTS (Bookmark These!):${NC}"
if [ "$JQ_AVAILABLE" = true ]; then
  LEN=$(jq '.references | length' "$MANIFEST_FILE")
  for ((i=0; i<LEN; i++)); do
    NAME=$(jq -r ".references[$i].name" "$MANIFEST_FILE")
    URL=$(jq -r ".references[$i].url" "$MANIFEST_FILE")
    echo -e "  - ${BOLD}$NAME${NC}: $URL"
  done
else
  echo "  - dair-ai/Prompt-Engineering-Guide: https://github.com/dair-ai/Prompt-Engineering-Guide"
  echo "  - f/prompts.chat: https://github.com/f/prompts.chat"
  echo "  - public-apis: https://github.com/public-apis/public-apis"
fi

echo ""
echo -e "${GREEN}${BOLD}✓ Setup complete! Your workspace has been compiled.${NC}"
echo -e "${CYAN}======================================================================${NC}"
