# dotfiles

Personal dev environment configuration and bootstrap for new machines.

## What's included

| Path | Installs to |
|---|---|
| `git/.gitconfig` | `~/.gitconfig` |
| `ssh/config` | `~/.ssh/config` |
| `gh/hosts.yml.template` | `~/.config/gh/hosts.yml` (structure only, no tokens) |
| `bootstrap.sh` | run once on a new device |

## Bootstrap a new device

```bash
# 1. Clone (no auth needed — public repo)
git clone https://git.onsm.cloud/pratyush-sahay/dotfiles.git ~/dotfiles
# or with SSH once your key is set up:
# git clone git@git.onsm.cloud:pratyush-sahay/dotfiles.git ~/dotfiles

# 2. Run bootstrap
cd ~/dotfiles
chmod +x bootstrap.sh
./bootstrap.sh
```

The script will:
1. Symlink `~/.gitconfig` and `~/.ssh/config` from this repo
2. Install git-lfs hooks
3. Walk you through `gh auth login` for all three accounts:
   - `git.onsm.cloud` → `pratyush-sahay` (internal GHES)
   - `github.com` → `pratyush-sahay_enid` (seeing-machines-emu org)
   - `github.com` → `aspratyush` (personal)

## Accounts

| Host | Account | Purpose |
|---|---|---|
| `git.onsm.cloud` | `pratyush-sahay` | Internal GHES |
| `github.com` | `pratyush-sahay_enid` | `seeing-machines-emu` org work |
| `github.com` | `aspratyush` | Personal |

`pratyush-sahay_enid` is set as the default active `github.com` account.

## Switching github.com accounts

```bash
gh auth switch --hostname github.com --user pratyush-sahay_enid  # org work
gh auth switch --hostname github.com --user aspratyush            # personal
```

## Updating dotfiles from any machine

Edit files in this repo and commit. On other machines:
```bash
cd ~/dotfiles && git pull
```
Symlinks mean the pull immediately takes effect — no re-running bootstrap needed.

## What's NOT stored here

- SSH private keys (generate per-device, add public key to each git host)
- gh auth tokens (obtained via `gh auth login` during bootstrap)
- EC2 PEM key files (stored locally at paths referenced in `ssh/config`)
