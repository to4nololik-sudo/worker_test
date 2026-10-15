#!/bin/bash
# ========================================================
# Запуск TLauncher с подменой HWID (Wayland-совместимый)
# ========================================================

# Генерируем случайные значения
NEW_UUID=$(cat /proc/sys/kernel/random/uuid)
NEW_BOARD="BOARD-$(tr -dc A-Z0-9 < /dev/urandom | head -c 12)"
NEW_DISK="DISK-$(tr -dc A-Z0-9 < /dev/urandom | head -c 8)"
NEW_MAC=$(od -An -N6 -tx1 /dev/urandom | sed 's/  */:/g' | cut -c2- | tr '[:lower:]' '[:upper:]')

echo "▶ Генерируем новые идентификаторы:"
echo "   Nickname: $SUDO_USER" 
echo "   UUID: $NEW_UUID"
echo "   Board: $NEW_BOARD"
echo "   Disk: $NEW_DISK"
echo "   MAC: $NEW_MAC"
# that are nice idea but take it another way, thank
# 1. Меняем MAC (от root)
echo "▶ Меняем MAC-адрес интерфейса wlan0..."
ip link set dev wlan0 down
ip link set dev wlan0 address "$NEW_MAC"
ip link set dev wlan0 up

# 2. Создаём фейковые файлы в /tmp
echo "$NEW_UUID" > /tmp/fake_uuid
echo "$NEW_BOARD" > /tmp/fake_board
echo "$NEW_DISK" > /tmp/fake_disk

# 3. Запускаем TLauncher:
#    - root создаёт изолированное пространство и подменяет файлы
#    - но Java-процесс запускается от имени ТВОЕГО пользователя (lolikpolik)
#    - благодаря -E сохраняются все переменные окружения (DISPLAY, WAYLAND_DISPLAY, XAUTHORITY)
echo "▶ Запускаем TLauncher с подменой HWID (Wayland)..."
unshare -m bash -c "
  mount --bind /tmp/fake_uuid /sys/class/dmi/id/product_uuid
  mount --bind /tmp/fake_board /sys/class/dmi/id/board_serial
  mount --bind /tmp/fake_disk /sys/block/nvme0n1/device/serial
  # Запускаем Java от имени обычного пользователя, но внутри этого изолированного пространства
  exec sudo -u $SUDO_USER -E java -jar /home/lolikpolik/tl.jar
"

# 4. После закрытия TLauncher – восстанавливаем MAC
echo "▶ Восстанавливаем оригинальный MAC-адрес..."
ip link set dev wlan0 down
ip link set dev wlan0 up
echo "✅ Готово. Подмена HWID снята."

