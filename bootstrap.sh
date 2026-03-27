#!/usr/bin/env bash
# bootstrap.sh — set up a new dev environment from dotfiles
# Usage: ./bootstrap.sh
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

info()  { echo -e "${GREEN}[dotfiles]${NC} $*"; }
warn()  { echo -e "${YELLOW}[dotfiles]${NC} $*"; }

# ── 1. Check dependencies ─────────────────────────────────────────────────────
for cmd in git gh; do
  if ! command -v "$cmd" &>/dev/null; then
    warn "$cmd not found — please install it first."
    warn "  git:  https://git-scm.com/downloads"
    warn "  gh:   https://cli.github.com"
    exit 1
  fi
done

if ! command -v git-lfs &>/dev/null; then
  warn "git-lfs not found. Install with: sudo apt install git-lfs  (or brew install git-lfs)"
  warn "Continuing without LFS setup..."
else
  info "Installing git-lfs hooks..."
  git lfs install
fi

# ── 2. git config ─────────────────────────────────────────────────────────────
info "Linking ~/.gitconfig..."
if [[ -f ~/.gitconfig && ! -L ~/.gitconfig ]]; then
  warn "~/.gitconfig already exists (not a symlink). Backing up to ~/.gitconfig.bak"
  mv ~/.gitconfig ~/.gitconfig.bak
fi
ln -sf "$DOTFILES_DIR/git/.gitconfig" ~/.gitconfig
info "  → $(git config user.name) <$(git config user.email)>"

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
  warn "No ~/.bashrc.local found. Creating from template — edit it with machine-specific paths."
  cp "$DOTFILES_DIR/bash/.bashrc.local.template" ~/.bashrc.local
fi

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

# ── 6. gh CLI auth ────────────────────────────────────────────────────────────
# Copy the hosts template so gh knows which accounts exist (no tokens yet)
info "Setting up gh CLI config structure..."
mkdir -p ~/.config/gh
if [[ ! -f ~/.config/gh/hosts.yml ]]; then
  cp "$DOTFILES_DIR/gh/hosts.yml.template" ~/.config/gh/hosts.yml
fi

info ""
info "Now authenticating gh CLI accounts (you will be prompted for each)..."
info ""

# git.onsm.cloud (GHES)
info "── Account 1/3: git.onsm.cloud (pratyush-sahay) ──"
gh auth login --hostname git.onsm.cloud --git-protocol ssh --skip-ssh-key

# github.com org account
info "── Account 2/3: github.com (pratyush-sahay_enid — seeing-machines-emu) ──"
gh auth login --hostname github.com --git-protocol ssh --skip-ssh-key

# github.com personal account
info "── Account 3/3: github.com (aspratyush — personal) ──"
gh auth login --hostname github.com --git-protocol ssh --skip-ssh-key

# Ensure the org account is the active github.com account
info "Setting pratyush-sahay_enid as active github.com account..."
gh auth switch --hostname github.com --user pratyush-sahay_enid

# ── 7. Mirror remote + post-merge hook ───────────────────────────────────────
info "Configuring github.com mirror remote..."
if git -C "$DOTFILES_DIR" remote get-url mirror &>/dev/null; then
  warn "  'mirror' remote already exists — skipping."
else
  git -C "$DOTFILES_DIR" remote add mirror git@github-aspratyush:aspratyush/dotfiles.git
  info "  Added mirror → git@github-aspratyush:aspratyush/dotfiles.git"
fi

info "Installing post-merge hook..."
chmod +x "$DOTFILES_DIR/git/hooks/post-merge"
ln -sf "$DOTFILES_DIR/git/hooks/post-merge" "$DOTFILES_DIR/.git/hooks/post-merge"
info "  Hook installed: .git/hooks/post-merge"

info ""
info "✅ Done! Verify with: gh auth status"
info ""
info "To switch github.com accounts:"
info "  gh auth switch --hostname github.com --user pratyush-sahay_enid  # org work"
info "  gh auth switch --hostname github.com --user aspratyush            # personal"
info ""
info "Mirror: every 'git pull' on master will auto-push to github.com/aspratyush/dotfiles"
info "  Log: ~/.local/log/dotfiles-mirror.log"
