#!/usr/bin/env bash
#
# EDK2 / Mu-Silicium Giulia (OnePlus 13R / Ace 5) Port Installer
# Copyright (c) 2026 WOA-Giulia Project
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${1:-../Mu-Silicium}"

echo "=================================================="
echo " Installing Giulia EDK2 Port into Mu-Silicium..."
echo " Target: ${TARGET_DIR}"
echo "=================================================="

if [ ! -d "${TARGET_DIR}" ]; then
    echo "[-] Error: Target directory '${TARGET_DIR}' does not exist!"
    echo "    Usage: $0 [path/to/Mu-Silicium]"
    exit 1
fi

TARGET_DIR="$(cd "${TARGET_DIR}" && pwd)"

# 1. Copy Device Tree
echo "[+] Copying Platforms/OnePlus/giuliaPkg..."
mkdir -p "${TARGET_DIR}/Platforms/OnePlus"
rsync -av --delete "${SCRIPT_DIR}/Platforms/OnePlus/giuliaPkg" "${TARGET_DIR}/Platforms/OnePlus/"

# 2. Copy ACPI Tables
echo "[+] Copying Silicium-ACPI tables..."
mkdir -p "${TARGET_DIR}/Silicium-ACPI/Platforms/OnePlus"
rsync -av --delete "${SCRIPT_DIR}/Silicium-ACPI/Platforms/OnePlus/giulia" "${TARGET_DIR}/Silicium-ACPI/Platforms/OnePlus/"

# 3. Copy Binaries
echo "[+] Copying device binaries..."
mkdir -p "${TARGET_DIR}/Binaries"
rsync -av --delete "${SCRIPT_DIR}/Binaries/giulia" "${TARGET_DIR}/Binaries/"

# 4. Copy Resources
echo "[+] Copying build resources (config and DTB)..."
mkdir -p "${TARGET_DIR}/Resources/Configs" "${TARGET_DIR}/Resources/DTBs"
cp -v "${SCRIPT_DIR}/Resources/Configs/giulia.toml" "${TARGET_DIR}/Resources/Configs/"
cp -v "${SCRIPT_DIR}/Resources/DTBs/giulia.dtb" "${TARGET_DIR}/Resources/DTBs/"

# 5. Apply Core Errata Patches
echo "[+] Applying core Silicon/Lanai patches..."
if [ -f "${SCRIPT_DIR}/Patches/0001-Silicon-Errata-Patches.patch" ]; then
    (cd "${TARGET_DIR}" && git apply --ignore-whitespace --check "${SCRIPT_DIR}/Patches/0001-Silicon-Errata-Patches.patch" 2>/dev/null && git apply --ignore-whitespace "${SCRIPT_DIR}/Patches/0001-Silicon-Errata-Patches.patch") || {
        echo "[!] Patch already applied or partially applied, continuing..."
    }
fi

echo ""
echo "[*] Successfully installed Giulia port!"
echo "    You can now build with:"
echo "    cd ${TARGET_DIR} && python3 build_uefi.py -d giulia -m 0 -r DEBUG"
echo ""
