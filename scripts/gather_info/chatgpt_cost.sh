#!/bin/bash

PROMPT_FILE="$1"
LOG_FILE="$OBSIDIAN/Brain/Data/Logs/prompt_log.csv"

if [[ ! -f "$PROMPT_FILE" ]]; then
    echo "❌ Archivo no encontrado: $PROMPT_FILE"
    exit 1
fi

# Extraer campos del .md
proyecto=$(grep -m1 '\*\*Nombre:\*\*' "$PROMPT_FILE" | sed 's/.*\*\*Nombre:\*\* //')
rol=$(grep -m1 '\*\*Rol del sistema:\*\*' "$PROMPT_FILE" | sed 's/.*\*\*Rol del sistema:\*\* //')
fecha=$(basename "$PROMPT_FILE" | cut -d_ -f3 | sed 's/.md//')
tokens_entrada=$(wc -w < "$PROMPT_FILE")

# Estimar tokens de respuesta: asumimos respuesta ≈ 1.5x input (ajustable)
tokens_respuesta=$((tokens_entrada * 3 / 2))
tokens_totales=$((tokens_entrada + tokens_respuesta))

# Crear archivo CSV si no existe
if [[ ! -f "$LOG_FILE" ]]; then
    echo "fecha,proyecto,rol,tokens_entrada,tokens_respuesta,tokens_totales" > "$LOG_FILE"
fi

# Guardar línea
echo "$fecha,$proyecto,$rol,$tokens_entrada,$tokens_respuesta,$tokens_totales" >> "$LOG_FILE"

echo "✅ Log guardado en $LOG_FILE"

