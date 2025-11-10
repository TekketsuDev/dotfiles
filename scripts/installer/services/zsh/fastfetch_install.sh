#!/bin/bash
sudo apt update
sudo apt install -y git cmake pkg-config build-essential \
  zlib1g-dev

git clone --depth 1 https://github.com/fastfetch-cli/fastfetch
cd fastfetch
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
cmake --build . -j"$(nproc)"
sudo cmake --install .
fastfetch --version

