Package Managment across multiple systems

    Pacman Hooks for:
    systemd-sysusers # Automatically create automatic roles based on app installations 
    systemd-tmpfiles # Tmp files for installation

- [ ] partitioning.sh
- [ ] package_core.sh
- [ ] utils.sh
- [ ] backup_efi.sh
- [ ] create_partitions.sh
- [ ] format_and_mount.sh
- [ ] luks_encrypt.sh
- [ ] setup_dualboot.sh
- [ ] wipe_disk.sh
- [ ] install.sh
- [ ] post_install.sh
- [ ] harden_ssh.sh
- [ ] setup_ssh_lan.sh
- [ ] ly_install.sh
- [ ] setup_protonvpn.sh
- [ ] stow.sh
- [ ] pre_install.sh
- [ ] enable_network.sh

# install.sh

- **Ask:** Dualboot? ➜ `[DUALBOOT=true|false]`
- **Ask:** Target disk ➜ `DISK=/dev/sdX`

## If DUALBOOT=false:
- `backup_efi.sh` 📁 Save EFI partition to USB or Proxmox

## Ask: Disk setup?
- Show Purpose Layout diagram
- Offline backup safe | Nuke Vulnerability | New Hardware | Single Service Project
  - `wipe_disk.sh` 💣 Secure disk wipe with dd
  - `create_partitions.sh`
    - **Ask:** FS layout (ext4, LVM, BTRFS, ZFS)
    - **Ask:** Use backup disk?
    - Create partitions based on dualboot, UEFI, and layout
      - ➜ export `EFI_PART`, `ROOT_PART`, `BACKUP_PART`, `FS_LAYOUT`
  - `luks_encrypt.sh` 🔐 Optionally encrypt `ROOT_PART` ➜ `ROOT_MAPPED`
  - `format_and_mount.sh` 💾 Format & mount all partitions
    - ➜ Generate `/mnt/etc/fstab`

## If DUALBOOT=true:
- `setup_dualboot.sh` ⚙️  Install GRUB + os-prober (Windows)

## `base.sh` 📦 Arch base system install
- Set keyboard, NTP, mirrors
- `pacstrap` + `genfstab`
- Copy dotfiles to `/mnt/home/work`
- Copy `post_install.sh` to `/mnt/root`
- Create `auto_install_modules.sh` to run later

## `arch-chroot /mnt`
- `post_install.sh`
  - Set timezone, locale
  - Set hostname and `/etc/hosts`
  - Create user + password
  - Enable sudo (wheel group)
  - Enable services (NetworkManager, sshd)
  - Reinstall GRUB (if needed)
  - Run `auto_install_modules.sh` (modular configs)
    - Detect OS
    - Run `packages/$OS/{base,terminal,cybersecurity}.sh`
    - Run `hyprland.sh` if `OS=arch`

