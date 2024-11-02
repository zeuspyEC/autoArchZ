#!/bin/bash

# Función para centrar texto
format_center_literals() {
  local text="$1"
  local width=$(tput cols)
  local padding=$((($width - ${#text}) / 2))
  printf "%*s%s%*s\n" $padding "" "$text" $padding ""
}

# Banner "ZeusPy"
display_banner() {
  local banner=(
    " ▒███████▒▓█████  █    ██   ██████  ██▓███  ▓██   ██▓"
    "▒ ▒ ▒ ▄▀░▓█   ▀  ██  ▓██▒▒██    ▒ ▓██░  ██▒ ▒██  ██▒"
    "░ ▒ ▄▀▒░ ▒███   ▓██  ▒██░░ ▓██▄   ▓██░ ██▓▒  ▒██ ██░"
    "  ▄▀▒   ░▒▓█  ▄ ▓▓█  ░██░  ▒   ██▒▒██▄█▓▒ ▒  ░ ▐██▓░"
    "▒███████▒░▒████▒▒▒█████▓ ▒██████▒▒▒██▒ ░  ░  ░ ██▒▓░"
    "░▒▒ ▓░▒░▒░░ ▒░ ░░▒▓▒ ▒ ▒ ▒ ▒▓▒ ▒ ░▒▓▒░ ░  ░   ██▒▒▒ "
    "░░▒ ▒ ░ ▒ ░ ░  ░░░▒░ ░ ░ ░ ░▒  ░ ░░▒ ░     ▓██ ░▒░ "
    "░ ░ ░ ░ ░   ░    ░░░ ░ ░ ░  ░  ░  ░░       ▒ ▒ ░░  "
    "  ░ ░       ░  ░   ░           ░           ░ ░     "
    "░                                         ░ ░     "
  )

  clear
  echo -e "\033[34m"
  for line in "${banner[@]}"; do
    format_center_literals "$line"
    sleep 0.05
  done
  echo
}

# Función para descargar y ejecutar el script desde GitHub
download_and_run_script() {
  echo "Descargando y ejecutando el script desde GitHub..."

  # Descargar el script usando curl
  curl -s -L https://raw.githubusercontent.com/zeuspyEC/autoArchZ/main/mi-script.sh -o mi-script.sh

  # Ejecutar el script
  bash mi-script.sh
}

# Detectar UEFI o BIOS
detect_boot_mode() {
  if [ -d "/sys/firmware/efi/efivars" ]; then
    echo "Modo de arranque: UEFI"
    boot_mode="uefi"
  else
    echo "Modo de arranque: BIOS"
    boot_mode="bios"
  fi
}

# Detectar si existe una instalación de Windows
detect_windows_installation() {
  if [ -d "/mnt/windows" ]; then
    windows_installed=true
    echo "Se detectó una instalación de Windows."
  else
    windows_installed=false
    echo "No se encontró una instalación de Windows."
  fi
}

# Mostrar particiones y solicitar al usuario seleccionar una para la instalación
select_installation_partition() {
  partitions=$(lsblk -n -o NAME,SIZE,TYPE -p | awk '/part|lvm/ {print $1, $2, $3}')

  partition_list=()
  while IFS= read -r line; do
    partition_list+=("$line")
  done <<< "$partitions"

  partition_options=()
  for partition in "${partition_list[@]}"; do
    partition_options+=("$partition" "")
  done

  selected_partition=$(whiptail --title "Selección de Partición" --menu "Seleccione la partición donde desea instalar Arch Linux:" 20 78 10 "${partition_options[@]}" 3>&1 1>&2 2>&3)

  if [ $? -eq 0 ]; then
    echo "Partición seleccionada: $selected_partition"
  else
    echo "No se seleccionó ninguna partición. Saliendo del instalador."
    exit 1
  fi
}

# Particionar el disco (UEFI)
partition_disk_uefi() {
  parted -s "$selected_partition" mklabel gpt
  parted -s "$selected_partition" mkpart primary fat32 1 512M
  parted -s "$selected_partition" set 1 esp on
  parted -s "$selected_partition" mkpart primary ext4 512M 100%
  mkfs.fat -F32 "${selected_partition}1"
  mkfs.ext4 "${selected_partition}2"
}

# Particionar el disco (BIOS)
partition_disk_bios() {
  parted -s "$selected_partition" mklabel msdos
  parted -s "$selected_partition" mkpart primary ext4 1 512M
  parted -s "$selected_partition" set 1 boot on
  parted -s "$selected_partition" mkpart primary ext4 512M 100%
  mkfs.ext4 "${selected_partition}1"
  mkfs.ext4 "${selected_partition}2"
}

# Montar particiones (UEFI)
mount_partitions_uefi() {
  mount "${selected_partition}2" /mnt
  mkdir -p /mnt/boot/efi
  mount "${selected_partition}1" /mnt/boot/efi
}

# Montar particiones (BIOS)
mount_partitions_bios() {
  mount "${selected_partition}2" /mnt
  mkdir -p /mnt/boot
  mount "${selected_partition}1" /mnt/boot
}

# Instalar sistema base
install_base_system() {
  pacstrap /mnt base base-devel linux linux-firmware
}

# Generar fstab
generate_fstab() {
  genfstab -U /mnt >> /mnt/etc/fstab
}

# Configurar sistema
configure_system() {
  arch-chroot /mnt /bin/bash <<EOF
  ln -sf /usr/share/zoneinfo/America/Guayaquil /etc/localtime
  hwclock --systohc
  echo "es_EC.UTF-8 UTF-8" >> /etc/locale.gen
  locale-gen
  echo "LANG=es_EC.UTF-8" > /etc/locale.conf
  echo "arch" > /etc/hostname
  echo "127.0.0.1 localhost" >> /etc/hosts
  echo "::1 localhost" >> /etc/hosts
  echo "127.0.1.1 arch.localdomain arch" >> /etc/hosts
  mkinitcpio -P
  passwd
EOF
}

# Instalar y configurar GRUB (UEFI)
install_grub_uefi() {
  arch-chroot /mnt /bin/bash <<EOF
  pacman -S --noconfirm grub efibootmgr
  grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
  grub-mkconfig -o /boot/grub/grub.cfg
EOF
}

# Instalar y configurar GRUB (BIOS)
install_grub_bios() {
  arch-chroot /mnt /bin/bash <<EOF
  pacman -S --noconfirm grub
  grub-install "$selected_partition"
  grub-mkconfig -o /boot/grub/grub.cfg
EOF
}

# Configurar dual boot con Windows (UEFI)
configure_dual_boot_uefi() {
  if [ "$windows_installed" = true ]; then
    arch-chroot /mnt /bin/bash <<EOF
    pacman -S --noconfirm os-prober ntfs-3g
    os-prober
    grub-mkconfig -o /boot/grub/grub.cfg
EOF
  fi
}

# Configurar dual boot con Windows (BIOS)
configure_dual_boot_bios() {
  if [ "$windows_installed" = true ]; then
    arch-chroot /mnt /bin/bash <<EOF
    pacman -S --noconfirm os-prober ntfs-3g
    os-prober
    grub-mkconfig -o /boot/grub/grub.cfg
EOF
  fi
}

# Instalar y configurar window manager
install_window_manager() {
  arch-chroot /mnt /bin/bash <<EOF
  pacman -S --noconfirm xorg-server xorg-xinit bspwm sxhkd
  echo "exec bspwm" > ~/.xinitrc
EOF
}

# Función principal
main() {
  display_banner
  detect_boot_mode
  detect_windows_installation

  select_installation_partition

  if [ "$boot_mode" == "uefi" ]; then
    partition_disk_uefi
    mount_partitions_uefi
  else
    partition_disk_bios
    mount_partitions_bios
  fi

  install_base_system
  generate_fstab
  configure_system

  if [ "$boot_mode" == "uefi" ]; then
    install_grub_uefi
    configure_dual_boot_uefi
  else
    install_grub_bios
    configure_dual_boot_bios
  fi

  install_window_manager

  echo "Instalación completada. Reinicie el sistema."
}

# Ejecutar script
main