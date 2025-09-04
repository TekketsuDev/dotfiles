#!/usr/bin/env bash

# Ruta relativa desde tu repo de dotfiles
FONT_SRC_DIR="$HOME/dotfiles/resources/fonts/Terminus"

# Verificar que existe
if [ ! -d "$FONT_SRC_DIR" ]; then
  echo "❌ No se encontró la carpeta de fuentes: $FONT_SRC_DIR"
  exit 1
fi

# Detectar si tiene fuentes ttf/otf válidas
FONT_FILES=$(find "$FONT_SRC_DIR" -type f \( -iname "*.ttf" -o -iname "*.otf" \))
if [ -z "$FONT_FILES" ]; then
  echo "❌ No se encontraron archivos .ttf o .otf en $FONT_SRC_DIR"
  exit 1
fi

# Destino: usuario o sistema según permisos
if [ "$EUID" -eq 0 ]; then
  DEST_DIR="/usr/share/fonts/terminus"
else
  DEST_DIR="$HOME/.local/share/fonts/terminus"
fi

mkdir -p "$DEST_DIR"
cp $FONT_FILES "$DEST_DIR"

# Actualizar caché de fuentes
echo "🌀 Actualizando caché de fuentes..."
fc-cache -fv > /dev/null

# Verificar instalación
echo "✅ Fuentes instaladas en: $DEST_DIR"
fc-list | grep -i terminus || echo "⚠️ No se detectó Terminus. Revisa si es formato compatible."

exit 0
