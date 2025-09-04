#!/bin/bash

AUTO_APPLY=false
if [[ "$1" == "--yes" ]]; then
    AUTO_APPLY=true
    shift
fi

FILE="$1"
if [[ ! -f "$FILE" ]]; then
    echo "❌ Archivo no encontrado: $FILE"
    exit 1
fi

ATTACHMENTS="${ATTACHMENTS:-$HOME/Notes/Brain/Data/Attachments}"
TMP_FILE="$(mktemp)"

echo "📄 Procesando archivo: $FILE"
echo "🖼  Carpeta de imágenes: $ATTACHMENTS"
echo "🧪 Archivo temporal: $TMP_FILE"

cp "$FILE" "$TMP_FILE"

grep -oP '!\[\[\K[^\]]+(?=\]\])' "$TMP_FILE" | sort -u | while read -r raw_path; do
    img_file="$ATTACHMENTS/$(basename "$raw_path")"

    if [ -f "$img_file" ]; then
        rel_img=$(realpath --relative-to="$(dirname "$FILE")" "$img_file")
        echo "🔄 Reemplazando ![[$raw_path]] → ![]($rel_img)"
        sed -i "s|!\[\[$raw_path\]\]|![]($rel_img)|g" "$TMP_FILE"
    else
        echo "❌ Imagen no encontrada: $img_file"
    fi
done

# Comparar con el original
if ! diff -q "$FILE" "$TMP_FILE" >/dev/null; then
    if [ "$AUTO_APPLY" = true ]; then
        mv "$TMP_FILE" "$FILE"
        echo "✅ Cambios aplicados automáticamente"
    else
        echo -n "¿Aplicar cambios a $FILE? [y/N]: "
        read -r confirm
        if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
            mv "$TMP_FILE" "$FILE"
            echo "✅ Cambios aplicados"
        else
            rm "$TMP_FILE"
            echo "⏪ Cambios descartados"
        fi
    fi
else
    rm "$TMP_FILE"
    echo "⚠️ No se realizaron cambios: el archivo ya estaba actualizado"
fi

