# Development tools — C, C++, Raylib, React, ESP32, Rust, Java
{ pkgs, ... }: {
  home.packages = with pkgs; [
    # --- core build ---
    gcc
    clang
    clang-tools       # clangd LSP + clang-format
    cmake
    gnumake
    ninja
    pkg-config
    gdb
    valgrind
    bear              # generates compile_commands.json for clangd

    # --- raylib + C/C++ game dev ---
    raylib
    xorg.libX11
    xorg.libXrandr
    xorg.libXinerama
    xorg.libXcursor
    xorg.libXi
    libGL
    wayland

    # --- esp32 (cross-compile + flash tools) ---
    esptool
    python3
    python3Packages.pyserial
    python3Packages.pip
    platformio-core   # manages ESP-IDF, Arduino, etc.

    # --- react / js ---
    nodejs_22
    nodePackages.npm
    nodePackages.pnpm
    bun

    # --- rust ---
    rustup

    # --- java (used in existing setup) ---
    jdk21

    # --- scripting / glue ---
    python3
    python3Packages.virtualenv
    shellcheck
    shfmt

    # --- git extras ---
    git-lfs
    lazygit

    # --- containers ---
    docker-compose
  ];
}
