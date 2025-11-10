#!/bin/bash
#
sudo apt remove -y neovim || true
sudo apt install -y build-essential gcc g++ make cmake pkg-config unzip curl git
# (opcional pero útil)
sudo apt install -y ripgrep fd-find sqlite3 lazygit imagemagick ghostscript nodejs npm

cd /tmp
git clone https://github.com/neovim/neovim.git
cd neovim
git fetch --tags

make CMAKE_BUILD_TYPE=Release CMAKE_INSTALL_PREFIX=/usr/local -j"$(nproc)"
sudo make install

# Instala el CLI
sudo npm -g i tree-sitter-cli
sudo npm i -g @mermaid-js/mermaid-cli
