#!/usr/bin/env bash
set -euo pipefail

# Argumentos esperados del script principal:
EFI_PART_DEVICE="$1"
ROOT_PART_DEVICE="$2"
BACKUP_PART_DEVICE="$3"
DUALBOOT="$4"
SELECTED_FS_LAYOUT="$5"
BTRFS_SUBVOLUME_NAMES_STRING="$6"
BTRFS_SUBVOLUME_PURPOSES_STRING="$7"
BTRFS_SUBVOLUME_MOUNTS_STRING="$8"


echo "--- Iniciando Formateo y Montaje ---"
echo "EFI Device: $EFI_PART_DEVICE"
echo "Root Device: $ROOT_PART_DEVICE"
echo "FS Layout: $SELECTED_FS_LAYOUT"


if [[ -n "$EFI_PART_DEVICE" ]]; then
    echo "Formateando partición EFI ($EFI_PART_DEVICE) como FAT32..."
    mkfs.fat -F32 "$EFI_PART_DEVICE"
else
    echo "Error: No se especificó partición EFI." >&2
    exit 1
fi

if [[ -z "$ROOT_PART_DEVICE" ]]; then
    echo "Error: No se especificó partición raíz/principal." >&2
    exit 1
fi

TEMP_BTRFS_MOUNT="/mnt/btrfs_temp_root_for_subvols" # Punto de montaje temporal para crear subvolúmenes

if [[ "$SELECTED_FS_LAYOUT" == "btrfs" ]]; then
    echo "Formateando $ROOT_PART_DEVICE como BTRFS..."
    mkfs.btrfs -f "$ROOT_PART_DEVICE" # -f para forzar si ya existe algo

    echo "Montando temporalmente el pool BTRFS en $TEMP_BTRFS_MOUNT para crear subvolúmenes..."
    mkdir -p "$TEMP_BTRFS_MOUNT"
    mount -t btrfs "$ROOT_PART_DEVICE" "$TEMP_BTRFS_MOUNT"

    mapfile -t subvol_names < <(echo -e "${BTRFS_SUBVOLUME_NAMES_STRING:-}")
    mapfile -t subvol_mounts < <(echo -e "${BTRFS_SUBVOLUME_MOUNTS_STRING:-}")
    # mapfile -t subvol_purposes < <(echo -e "${BTRFS_SUBVOLUME_PURPOSES_STRING:-}") # Si necesitas los propósitos aquí

    if [[ ${#subvol_names[@]} -gt 0 ]]; then
        echo "Creando subvolúmenes BTRFS..."
        for i in "${!subvol_names[@]}"; do
            name="${subvol_names[i]}"
            # local purpose="${subvol_purposes[i]}" # Descomentar si se usa
            intended_mount="${subvol_mounts[i]}"

            if [[ -n "$name" ]]; then
                echo "  Creando subvolumen: ${TEMP_BTRFS_MOUNT}/${name}"
                btrfs subvolume create "${TEMP_BTRFS_MOUNT}/${name}"
            fi
        done
    else
        echo "No se definieron subvolúmenes BTRFS específicos, se usará el volumen raíz."
        # Podrías querer crear un subvolumen raíz por defecto si no hay ninguno, ej: @
        # btrfs subvolume create "${TEMP_BTRFS_MOUNT}/@"
    fi

    echo "Desmontando el pool BTRFS temporal..."
    umount "$TEMP_BTRFS_MOUNT"
    rmdir "$TEMP_BTRFS_MOUNT"

    # Montar el sistema de archivos raíz de Arch (usualmente el subvolumen @)
    echo "Montando subvolumen raíz BTRFS en /mnt..."
    # Asume que el subvolumen para / es "@" si existe, o el raíz del BTRFS si no hay subvolúmenes específicos
     root_subvol_name="@"
     found_root_subvol=false
    for name_check in "${subvol_names[@]}"; do
        if [[ "$name_check" == "@" ]]; then
            found_root_subvol=true
            break
        fi
    done

    if $found_root_subvol; then
        mount -t btrfs -o subvol=@,defaults,compress=zstd,noatime,space_cache=v2 "$ROOT_PART_DEVICE" /mnt
    else
        # Si no hay subvolumen "@", montar el raíz del BTRFS. Considera crear un "@" por defecto.
        mount -t btrfs -o defaults,compress=zstd,noatime,space_cache=v2 "$ROOT_PART_DEVICE" /mnt
        echo "Advertencia: No se encontró subvolumen '@'. Montando el raíz del BTRFS en /mnt."
        echo "Se recomienda usar un subvolumen (ej. '@') para el sistema raíz con BTRFS."
    fi

    # Montar otros subvolúmenes BTRFS
    if [[ ${#subvol_names[@]} -gt 0 ]]; then
        echo "Montando otros subvolúmenes BTRFS..."
        for i in "${!subvol_names[@]}"; do
             name="${subvol_names[i]}"
             mount_point="${subvol_mounts[i]}"

            if [[ -n "$name" && -n "$mount_point" && "$name" != "@" ]]; then # No volver a montar @
                target_mount_dir="/mnt${mount_point}" # Asume que mount_point es relativo a / (ej. /home, /.snapshots)
                echo "  Creando directorio de montaje: $target_mount_dir"
                mkdir -p "$target_mount_dir"
                echo "  Montando subvolumen $name en $target_mount_dir"
                mount -t btrfs -o subvol="${name}",defaults,compress=zstd,noatime,space_cache=v2 "$ROOT_PART_DEVICE" "$target_mount_dir"
            fi
        done
    fi

elif [[ "$SELECTED_FS_LAYOUT" == "ext4" ]]; then
    echo "Formateando $ROOT_PART_DEVICE como ext4..."
    mkfs.ext4 -F "$ROOT_PART_DEVICE"
    echo "Montando $ROOT_PART_DEVICE en /mnt..."
    mount "$ROOT_PART_DEVICE" /mnt
# elif [[ "$SELECTED_FS_LAYOUT" == "lvm" ]]; then
    # Aquí iría la lógica para LVM: pvcreate, vgcreate, lvcreate, mkfs en LVs, mount.
    # echo "LVM no implementado aún en este script."
else
    echo "Error: Tipo de sistema de archivos '$SELECTED_FS_LAYOUT' no soportado o no especificado." >&2
    exit 1
fi

# 3. Montar Partición EFI
if [[ -n "$EFI_PART_DEVICE" ]]; then
    # El punto de montaje común para EFI es /boot/efi o /efi.
    # Para la instalación de Arch, se monta en /mnt/boot/efi o /mnt/efi
    # Si tienes una partición /boot separada, sería /mnt/boot y luego EFI en /mnt/boot/efi
    # Asumamos /mnt/boot/efi por ahora, que es común.
    EFI_MOUNT_POINT="/mnt/boot/efi"
    echo "Creando directorio de montaje para EFI: $EFI_MOUNT_POINT"
    mkdir -p "$EFI_MOUNT_POINT"
    echo "Montando $EFI_PART_DEVICE en $EFI_MOUNT_POINT..."
    mount "$EFI_PART_DEVICE" "$EFI_MOUNT_POINT"
fi

# 4. Formatear y montar Partición de Backup (si existe)
if [[ -n "$BACKUP_PART_DEVICE" ]]; then
    echo "Formateando partición de backup ($BACKUP_PART_DEVICE)..."
    # Decide el sistema de archivos para el backup, ej. ext4
    mkfs.ext4 -F "$BACKUP_PART_DEVICE"
    BACKUP_MOUNT_POINT="/mnt/backup" # O donde quieras montarlo temporalmente o permanentemente
    mkdir -p "$BACKUP_MOUNT_POINT"
    echo "Montando $BACKUP_PART_DEVICE en $BACKUP_MOUNT_POINT..."
    mount "$BACKUP_PART_DEVICE" "$BACKUP_MOUNT_POINT"
fi

echo "--- Formateo y Montaje Completados ---"
lsblk -f /mnt # Muestra los montajes bajo /mnt para verificar
