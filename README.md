#Dotfiles
Directory containing my dotfiles for ArchLinux

# System Requirements

·Arch Based
·Linux Kernel: 6.8.2-arch2-1 
·Hyprland: v0.37.1 
·Terminal: Kitty 0.33.0 
·Shell: zsh 5.9 (x86_64-pc-linux-gnu) build on .ohmyzsh

#Installation Requirements
·GNU Stow
·Git

```
pacman -S git stow
```

# Installation
Clone the dotfiles in the $HOME directory
```
git clone https://github.com/TekketsuDev/dotfiles.git

cd dotfiles

```
Use GNU Stow to create the symlinks remember to .backup your current files to avoid conflicts 
```
stow .
```


# File Structure

