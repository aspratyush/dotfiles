# dotfiles

Personal dev environment configuration and bootstrap for new machines.

## What's included

| Path | Installs to | Notes |
|---|---|---|
| `git/.gitconfig` | `~/.gitconfig` (symlink) | Git identity + LFS |
| `ssh/config` | `~/.ssh/config` (symlink) | GPU cluster + EC2 + GitHub hosts |
| `bash/.bashrc_custom` | `~/.bashrc_custom` (symlink) | Aliases, functions, PS1 |
| `bash/.bashrc.local.template` | `~/.bashrc.local` (copied) | Machine-specific paths — **not committed** |
| `gh/hosts.yml.template` | `~/.config/gh/hosts.yml` | 3-account gh CLI structure — no tokens |
| `copilot/config.json.template` | `~/.copilot/config.json` (copied) | Preferences — no tokens |
| `bootstrap.sh` | run once on a new device | |

## Bootstrap a new device

```bash
# 1. Clone (no auth needed — public repo, use HTTPS on a fresh machine)
git clone https://git.onsm.cloud/pratyush-sahay/dotfiles.git ~/dotfiles

# 2. Run bootstrap
cd ~/dotfiles && chmod +x bootstrap.sh && ./bootstrap.sh
```

The script will:
1. Symlink `~/.gitconfig`, `~/.ssh/config`, `~/.bashrc_custom`
2. Append `source ~/.bashrc_custom` to `~/.bashrc` (once)
3. Copy `~/.bashrc.local` from template — **edit this with machine-specific paths**
4. Install git-lfs hooks
5. Copy Copilot CLI preferences (no tokens)
6. Walk through `gh auth login` for all three accounts

## After bootstrap — manual steps

1. **SSH keys**: generate a keypair (`ssh-keygen`) and register the public key with each host
2. **`~/.bashrc.local`**: fill in CUDA paths, venv paths, SM tool paths for this machine
3. **EC2 SSH entries**: add any active EC2 hosts to `~/.ssh/config` locally (ephemeral IPs not committed)

## Accounts

| Host | Account | Purpose |
|---|---|---|
| `git.onsm.cloud` | `pratyush-sahay` | Internal GHES |
| `github.com` | `pratyush-sahay_enid` | `seeing-machines-emu` org work (default active) |
| `github.com` | `aspratyush` | Personal |

Switch github.com accounts:
```bash
gh auth switch --hostname github.com --user pratyush-sahay_enid  # org work
gh auth switch --hostname github.com --user aspratyush            # personal
```

## Updating from any machine

```bash
cd ~/dotfiles && git pull
```
Symlinked files (`~/.gitconfig`, `~/.ssh/config`, `~/.bashrc_custom`) update instantly.
Templates (`~/.bashrc.local`, `~/.copilot/config.json`) are not auto-updated — review manually.

## What's NOT stored here

| File | Why |
|---|---|
| SSH private keys | Generate per-device |
| gh OAuth tokens | Obtained via `gh auth login` |
| `~/.copilot/config.json` actual file | Contains live Copilot tokens |
| `~/.bashrc.local` actual file | Machine-specific paths |
| EC2 PEM key files | Stored locally, paths referenced in ssh/config |
