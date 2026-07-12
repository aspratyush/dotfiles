#!/usr/bin/env bash
# bootstrap.sh — set up a new dev environment from dotfiles
# Usage: ./bootstrap.sh
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

info()  { echo -e "${GREEN}[dotfiles]${NC} $*"; }
warn()  { echo -e "${YELLOW}[dotfiles]${NC} $*"; }

# ── 0. Install gh locally if not available ───────────────────────────────────
install_gh_local() {
  local install_dir="$HOME/.local/bin"
  local os arch tmp_dir version tarball_url

  info "gh not found in PATH — installing locally to $install_dir (no sudo)..."

  case "$(uname -s)" in
    Linux)  os="linux"  ;;
    Darwin) os="macOS"  ;;
    *)      warn "Unsupported OS: $(uname -s). Install gh manually: https://cli.github.com"; return 1 ;;
  esac

  case "$(uname -m)" in
    x86_64)        arch="amd64" ;;
    aarch64|arm64) arch="arm64" ;;
    *)             warn "Unsupported arch: $(uname -m). Install gh manually: https://cli.github.com"; return 1 ;;
  esac

  version=$(curl -fsSL "https://api.github.com/repos/cli/cli/releases/latest" \
    | grep '"tag_name"' | sed 's/.*"v\([^"]*\)".*/\1/')
  if [[ -z "$version" ]]; then
    warn "Could not determine latest gh version. Install gh manually: https://cli.github.com"
    return 1
  fi

  tarball_url="https://github.com/cli/cli/releases/download/v${version}/gh_${version}_${os}_${arch}.tar.gz"
  tmp_dir=$(mktemp -d)

  info "  Downloading gh v${version} (${os}/${arch})..."
  if ! curl -fsSL "$tarball_url" | tar -xz -C "$tmp_dir"; then
    warn "Download or extraction failed. Install gh manually: https://cli.github.com"
    rm -rf "$tmp_dir"
    return 1
  fi

  mkdir -p "$install_dir"
  cp "$tmp_dir/gh_${version}_${os}_${arch}/bin/gh" "$install_dir/gh"
  chmod +x "$install_dir/gh"
  rm -rf "$tmp_dir"

  info "  gh v${version} installed to $install_dir/gh"
  info "  Add $install_dir to your PATH to use it in future sessions."
  export PATH="$install_dir:$PATH"
}

# ── 1. Check dependencies ─────────────────────────────────────────────────────
if ! command -v git &>/dev/null; then
  warn "git not found — please install it first: https://git-scm.com/downloads"
  exit 1
fi

if ! command -v gh &>/dev/null; then
  install_gh_local || exit 1
fi

if ! command -v git-lfs &>/dev/null; then
  warn "git-lfs not found. Install with: sudo apt install git-lfs  (or brew install git-lfs)"
  warn "Continuing without LFS setup..."
else
  info "Installing git-lfs hooks..."
  git lfs install
fi

# ── 2. git identity (~/.gitconfig.local, never committed) ────────────────────
if [[ ! -f ~/.gitconfig.local ]]; then
  info "Setting up git identity in ~/.gitconfig.local (not committed)..."
  read -rp "  Git name  [Pratyush Sahay]: " GIT_NAME
  GIT_NAME="${GIT_NAME:-Pratyush Sahay}"

  read -rp "  Personal email (github.com / gmail): " GIT_EMAIL_PERSONAL
  read -rp "  Work email (git.onsm.cloud + github.com/seeing-machines-emu) [leave blank to skip]: " GIT_EMAIL_WORK

  printf '[user]\n\tname = %s\n\temail = %s\n' "${GIT_NAME}" "${GIT_EMAIL_PERSONAL}" > ~/.gitconfig.local
  info "  Written to ~/.gitconfig.local (personal identity)"

  if [[ -n "$GIT_EMAIL_WORK" ]]; then
    printf '[user]\n\tname = %s\n\temail = %s\n' "${GIT_NAME}" "${GIT_EMAIL_WORK}" > ~/.gitconfig.work
    info "  Written to ~/.gitconfig.work (work identity)"
    info "  Tip: add an [includeIf \"gitdir:~/path/to/work/\"] block in ~/.gitconfig.local to auto-apply it."
  fi
else
  info "~/.gitconfig.local already exists — skipping identity prompt."
  _pname=$(git config --file ~/.gitconfig.local user.name  2>/dev/null || echo "(not set)")
  _pemail=$(git config --file ~/.gitconfig.local user.email 2>/dev/null || echo "(not set)")
  info "  Personal identity: ${_pname} <${_pemail}>"
  if [[ -f ~/.gitconfig.work ]]; then
    _wname=$(git config --file ~/.gitconfig.work user.name  2>/dev/null || echo "(not set)")
    _wemail=$(git config --file ~/.gitconfig.work user.email 2>/dev/null || echo "(not set)")
    info "  Work identity:     ${_wname} <${_wemail}>"
  fi
fi

# ── 3. git config ─────────────────────────────────────────────────────────────
info "Linking ~/.gitconfig..."
if [[ -f ~/.gitconfig && ! -L ~/.gitconfig ]]; then
  warn "~/.gitconfig already exists (not a symlink). Backing up to ~/.gitconfig.bak"
  mv ~/.gitconfig ~/.gitconfig.bak
fi
ln -sf "$DOTFILES_DIR/git/.gitconfig" ~/.gitconfig
_cname=$(git config user.name  2>/dev/null || echo "(not set)")
_cemail=$(git config user.email 2>/dev/null || echo "(not set)")
info "  → ${_cname} <${_cemail}>"

# ── 3. SSH config ─────────────────────────────────────────────────────────────
info "Linking ~/.ssh/config..."
mkdir -p ~/.ssh && chmod 700 ~/.ssh
if [[ -f ~/.ssh/config && ! -L ~/.ssh/config ]]; then
  warn "~/.ssh/config already exists (not a symlink). Backing up to ~/.ssh/config.bak"
  mv ~/.ssh/config ~/.ssh/config.bak
fi
ln -sf "$DOTFILES_DIR/ssh/config" ~/.ssh/config
chmod 600 ~/.ssh/config

# ── 4. bash custom config ────────────────────────────────────────────────────
info "Linking ~/.bashrc_custom..."
ln -sf "$DOTFILES_DIR/bash/.bashrc_custom" ~/.bashrc_custom

if ! grep -q 'bashrc_custom' ~/.bashrc 2>/dev/null; then
  info "Appending source line to ~/.bashrc..."
  echo '' >> ~/.bashrc
  echo '# dotfiles: personal additions' >> ~/.bashrc
  echo '[ -f ~/.bashrc_custom ] && source ~/.bashrc_custom' >> ~/.bashrc
fi

if [[ ! -f ~/.bashrc.local ]]; then
  if [[ -f "$DOTFILES_DIR/bash/.bashrc.local.template" ]]; then
    warn "No ~/.bashrc.local found. Creating from template — edit it with machine-specific paths."
    cp "$DOTFILES_DIR/bash/.bashrc.local.template" ~/.bashrc.local
  else
    warn "No ~/.bashrc.local found and template missing — skipping."
  fi
fi

# ── 4b. Local bin scripts ─────────────────────────────────────────────────────
info "Linking bin/post-pr-review..."
mkdir -p "$HOME/.local/bin"
ln -sf "$DOTFILES_DIR/bin/post-pr-review" "$HOME/.local/bin/post-pr-review"
chmod +x "$DOTFILES_DIR/bin/post-pr-review"

# ── 5. Copilot CLI config ─────────────────────────────────────────────────────
info "Setting up ~/.copilot/config.json..."
mkdir -p ~/.copilot
if [[ ! -f ~/.copilot/config.json ]]; then
  cp "$DOTFILES_DIR/copilot/config.json.template" ~/.copilot/config.json
  info "  Copilot config written. Run 'gh copilot' once to authenticate."
else
  warn "~/.copilot/config.json already exists — skipping (won't overwrite live tokens)."
  warn "  Review $DOTFILES_DIR/copilot/config.json.template for any new preferences."
fi

# Returns 0 if the given user is already authenticated on the given hostname.
# Captures gh output first (with || true) so pipefail can't fire on gh's exit code.
gh_logged_in() {
  local hostname="$1" user="$2"
  local status_out
  status_out=$(gh auth status --hostname "$hostname" 2>&1) || true
  echo "$status_out" | grep -q "account $user"
}

# ── 6. gh CLI auth ────────────────────────────────────────────────────────────
# Copy the hosts template so gh knows which accounts exist (no tokens yet)
info "Setting up gh CLI config structure..."
mkdir -p ~/.config/gh
if [[ ! -f ~/.config/gh/hosts.yml ]]; then
  if [[ -f "$DOTFILES_DIR/gh/hosts.yml.template" ]]; then
    cp "$DOTFILES_DIR/gh/hosts.yml.template" ~/.config/gh/hosts.yml
  else
    warn "  $DOTFILES_DIR/gh/hosts.yml.template not found — skipping hosts.yml setup."
    warn "  Run 'gh auth login' manually for each account."
  fi
fi

info ""
info "Now authenticating gh CLI accounts (you will be prompted for each)..."
info ""

# git.onsm.cloud (GHES)
info "── Account 1/3: git.onsm.cloud (pratyush-sahay) ──"
if gh_logged_in "git.onsm.cloud" "pratyush-sahay"; then
  info "  Already authenticated — skipping."
else
  gh auth login --hostname git.onsm.cloud --git-protocol ssh --skip-ssh-key
fi

# github.com org account
info "── Account 2/3: github.com (pratyush-sahay_enid — seeing-machines-emu) ──"
if gh_logged_in "github.com" "pratyush-sahay_enid"; then
  info "  Already authenticated — skipping."
else
  gh auth login --hostname github.com --git-protocol ssh --skip-ssh-key
fi

# github.com personal account
info "── Account 3/3: github.com (aspratyush — personal) ──"
if gh_logged_in "github.com" "aspratyush"; then
  info "  Already authenticated — skipping."
else
  gh auth login --hostname github.com --git-protocol ssh --skip-ssh-key
fi

# Ensure the org account is the active github.com account
if gh_logged_in "github.com" "pratyush-sahay_enid"; then
  info "Setting pratyush-sahay_enid as active github.com account..."
  gh auth switch --hostname github.com --user pratyush-sahay_enid
else
  warn "pratyush-sahay_enid not authenticated — skipping account switch."
fi

# ── 7. Mirror remote + post-merge hook ───────────────────────────────────────
info "Configuring github.com mirror remote..."
if git -C "$DOTFILES_DIR" remote get-url mirror &>/dev/null; then
  warn "  'mirror' remote already exists — skipping."
else
  git -C "$DOTFILES_DIR" remote add mirror git@github-aspratyush:aspratyush/dotfiles.git
  info "  Added mirror → git@github-aspratyush:aspratyush/dotfiles.git"
fi

info "Installing post-merge hook..."
if [[ -f "$DOTFILES_DIR/git/hooks/post-merge" ]]; then
  chmod +x "$DOTFILES_DIR/git/hooks/post-merge"
  ln -sf "$DOTFILES_DIR/git/hooks/post-merge" "$DOTFILES_DIR/.git/hooks/post-merge"
  info "  Hook installed: .git/hooks/post-merge"
else
  warn "  $DOTFILES_DIR/git/hooks/post-merge not found — skipping hook install."
fi

info ""
info "✅ Done! Verify with: gh auth status"
info ""
info "To switch github.com accounts:"
info "  gh auth switch --hostname github.com --user pratyush-sahay_enid  # org work"
info "  gh auth switch --hostname github.com --user aspratyush            # personal"
info ""
info "Mirror: every 'git pull' on master will auto-push to github.com/aspratyush/dotfiles"
info "  Log: ~/.local/log/dotfiles-mirror.log"
