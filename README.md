# Dotfiles

Install all required software if not its not prepared yet for a multisetup package installation 

## USAGE
```bash
    git clone https://github.com/TekketsuDev/dotfiles.git
    cd dotfiles
    ./dev.sh install

    # Use dev
    dev
```
## 🧠 CORE PHILOSOPHY

- [ ] Modular install system per OS (Arch, Debian, WSL)
    
- [x] Dotfiles managed with `stow`
    
- [x] Auto-detect OS + package manager
    
- [ ] Central YAML-based package declaration system
    
- [ ] Auto-update YAML files after `pacman`/`apt`/`yay` usage
    
- [ ] Role-based system (`dev`, `hyprland`, `networking`, etc.)
    
- [ ] Reproducible installs on new machines
    
- [ ] Visual map (Excalidraw or Mermaid) of system architecture
    
- [ ] Auto-linking of config folders to visual maps
    

---



## 🐧 ARCH LINUX SYSTEM

- [ ] Full Arch install script (`pre`, `base`, `post`)
    
- [ ] Support for LUKS + LVM + dual boot
    
- [ ] Encrypted root with GRUB integration
    
- [x] Reuse existing EFI partition
    
- [ ] Format and mount logic per FS (`ext4`, `btrfs`, `lvm`)
    
- [ ] Partition layout detection
    
- [ ] Persist wake-on-LAN config
    
- [ ] Persist `/etc/pacman.d/workstation.yml` after each install
    
- [ ] Track packages installed from source (`make install`, not pacman)
    
- [ ] Auto-generate `.install_state` for context-aware post-install
    

---

## 🌐 NETWORKING / SECURITY

- [x] SSH LAN hardening (`setup_ssh_lan.sh`)
    
- [ ] Tailscale setup for remote access
    
- [x] ProtonVPN auto-connect when off-LAN
    
- [ ] SSH menu with `rofi -show ssh`
    
- [ ] Visualize network map per host (office, router, NAS, etc.)
    
- [ ] Track all device IPs dynamically by category (IoT, admin, etc.)
    
- [ ] Integrate VPN + tunnel fallback logic
    
- [ ] Flow control via Wireshark / traffic inspection
    
- [ ] Option to use pfSense (discarded in favor of WireGuard)how 
    

---

## 🔧 SERVER + DEVOPS

- [ ] Proxmox as infrastructure core
    
- [ ] Plan to deploy VMs via QEMU + Proxmox API
    
- [ ] Dockerized services managed via Git (e.g., Vaultwarden)
    
- [ ] Gitea + CI/CD auto-pull dotfiles + Docker updates
    
- [ ] Prometheus or Zabbix for service monitoring
    
- [ ] Define backup partitions that sync to Proxmox
    
- [ ] Test `nfs` and `samba` mounting automatically per network
    

---

## 🖥️ DESKTOP + UX

- [x] Hyprland + Waybar full setup
    
- [ ] Dynamic workspaces + rules per monitor
    
- [ ] LY login manager ASCII art themes
    
- [ ] ASCII banner theme per host role (e.g., `server`, `main`, `nas`)
    
- [ ] Default apps: Obsidian, Neovim, Brave, Zathura, Kitty
    
- [ ] Track `.desktop` apps + file associations (e.g., markdown)
    
- [x] Added showmethekey functionality

- [x] Repainting everforest
   - [x] Waybar
   - [x] Wofi
   - [x] Obsidian
   - [x] kitty
   - [x] hypr
   - [x] day_night_cycle


---

## 📁 DOTFILES + STOW

- [ ] Modular folders: `hyprland/`, `nvim/`, `zsh/`, `packages/`, etc.
    
- [ ] Host-based switch system
    
- [ ] Sync Obsidian configs (WSL/Windows/Linux)
    
- [x] Manage JetBrains settings
    
- [ ] Track dotfile versioning via Git hook (per group/role)
    
- [ ] Auto-deploy changes via hook or cron job
    
- [ ] YAML → tree → visual diff via Excalidraw
    

---

## 🛡️ SECURITY / PERMISSIONS

- [ ] Create isolated group for security-related processes
    
- [ ] Git pre-commit hook that validates role/group
    
- [ ] Only allow certain roles to modify specific scripts

---

## 🧪 TESTS + RESEARCH

