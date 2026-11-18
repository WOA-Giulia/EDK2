# EDK2 UEFI Firmware for OnePlus 13R / OnePlus Ace 5 (`giulia`)

[![Build Status](https://img.shields.io/badge/Build-Passing-brightgreen.svg)]()
[![Platform](https://img.shields.io/badge/SoC-Snapdragon%208%20Gen%203%20(SM8650)-blue.svg)]()
[![Firmware](https://img.shields.io/badge/Base-Project%20Mu%20%2F%20Mu--Silicium-orange.svg)]()
[![License](https://img.shields.io/badge/License-MIT%20%2F%20BSD--2--Clause-purple.svg)]()

This repository contains the complete EDK2 / Project Mu UEFI firmware port for the **OnePlus 13R** / **OnePlus Ace 5** (codename: `giulia`, model identifiers: `CPH2645` / `PJK110`), based on the Qualcomm Snapdragon 8 Gen 3 (`SM8650-AB`) mobile platform.

---

## Hardware Specifications

| Component | Specification |
| :--- | :--- |
| **Device** | OnePlus 13R / OnePlus Ace 5 |
| **Codename** | `giulia` |
| **SoC** | Qualcomm Snapdragon 8 Gen 3 (`SM8650-AB`, `pineapple`) |
| **CPU Architecture** | ARMv9.2-A (64-bit) |
| **CPU Cluster** | 1x Cortex-X4 @ 3.3 GHz + 5x Cortex-A720 @ 3.2/3.0 GHz + 2x Cortex-A520 @ 2.3 GHz |
| **GPU** | Qualcomm Adreno 750 |
| **Interrupt Controller** | ARM Generic Interrupt Controller v3 (GICv3 / GIC-600) |
| **Storage** | UFS 4.0 |
| **RAM** | 12 GB / 16 GB LPDDR5X |
| **UEFI Base** | Microsoft Project Mu (`Mu_Basecore`) via Project Silicium (`Mu-Silicium`) |
| **SoC Silicon Package**| `LanaiPkg` (`Silicon/Qualcomm/LanaiPkg`) |

---

## Repository Structure

```
.
├── Binaries/
│   └── giulia/                             # Extracted stock UEFI drivers & DXE modules (QcomPkg)
│       ├── ArmPkg/
│       ├── EmbeddedPkg/
│       ├── FatPkg/
│       ├── MdeModulePkg/
│       ├── QcomPkg/
│       ├── RawFiles/
│       └── README.md
├── Patches/                                # Core silicon & platform errata patches
│   ├── 0001-Silicon-Errata-Patches.patch   # KernelErrataPatcherLib, ErrataPatchesLib & LanaiPkg errata
│   └── 0002-Mu-Silicium-Giulia-Full.patch  # Complete unified diff against upstream Mu-Silicium
├── Platforms/
│   └── OnePlus/
│       └── giuliaPkg/                      # EDK2 device package description & definitions
│           ├── DeviceBuild.py              # Stuart build invocable definition
│           ├── giulia.dec                  # Package declaration
│           ├── giulia.dsc                  # Platform description
│           ├── giulia.fdf                  # Flash description
│           ├── Include/                    # APRIORI, DXE, RAW module include lists
│           └── Library/                    # Platform MemoryMapLib & ConfigurationMapLib
├── Resources/
│   ├── Configs/
│   │   └── giulia.toml                     # Target build configuration, memory layout & boot shim settings
│   └── DTBs/
│       └── giulia.dtb                      # Flattened Device Tree Blob appended to boot shim
├── Silicium-ACPI/
│   └── Platforms/
│       └── OnePlus/
│           └── giulia/                     # Device ACPI tables (DSDT, MADT/APIC, FACP, GTDT, PPTT)
├── install.sh                              # Automated synchronization script for Mu-Silicium trees
└── README.md                               # Project documentation
```

---

## Build Prerequisites

The build system requires a Linux environment (Ubuntu 22.04 LTS or 24.04 LTS recommended, WSL2 is fully supported).

### Required Packages

```bash
sudo apt update && sudo apt install -y \
    build-essential \
    clang \
    llvm \
    lld \
    iasl \
    git \
    python3 \
    python3-pip \
    python3-venv \
    device-tree-compiler \
    rsync \
    uuid-dev
```

### Python Dependencies

Install the required Python tools for Project Mu:

```bash
pip3 install --upgrade pip
pip3 install coloredlogs tomllib edk2-pytool-library edk2-pytool-extensions
```

---

## Integration with Mu-Silicium

### Option 1: Automated Integration (Recommended)

1. Clone `Mu-Silicium` with all submodules:
   ```bash
   git clone --recursive https://github.com/Project-Silicium/Mu-Silicium.git
   ```

2. Run `install.sh` from this repository pointing to your Mu-Silicium checkout:
   ```bash
   chmod +x install.sh
   ./install.sh /path/to/Mu-Silicium
   ```

### Option 2: Manual Integration

1. Copy the device package:
   ```bash
   cp -r Platforms/OnePlus/giuliaPkg /path/to/Mu-Silicium/Platforms/OnePlus/
   ```
2. Copy ACPI tables:
   ```bash
   cp -r Silicium-ACPI/Platforms/OnePlus/giulia /path/to/Mu-Silicium/Silicium-ACPI/Platforms/OnePlus/
   ```
3. Copy device binaries:
   ```bash
   cp -r Binaries/giulia /path/to/Mu-Silicium/Binaries/
   ```
4. Copy build resources:
   ```bash
   cp Resources/Configs/giulia.toml /path/to/Mu-Silicium/Resources/Configs/
   cp Resources/DTBs/giulia.dtb /path/to/Mu-Silicium/Resources/DTBs/
   ```
5. Apply the Silicon and platform errata patch:
   ```bash
   cd /path/to/Mu-Silicium
   git apply /path/to/WOA-Giulia-EDK2/Patches/0001-Silicon-Errata-Patches.patch
   ```

---

## Building Firmware

Once integrated into `Mu-Silicium`, compile the UEFI image using `build_uefi.py`:

### Debug Build
```bash
python3 build_uefi.py -d giulia -m 0 -r DEBUG
```

### Release Build
```bash
python3 build_uefi.py -d giulia -m 0 -r RELEASE
```

The build process generates an Android-compatible boot image:
```
Mu-giulia-0.img
```

---

## Booting Firmware

Reboot your device to fastboot / bootloader mode:
```bash
adb reboot bootloader
```

Boot the generated UEFI image without flashing:
```bash
fastboot boot Mu-giulia-0.img
```

---

## Architecture & ACPI Highlights

* **Redistributor Base & Strides:** GICv3 Redistributor physical base configured at `0x17180000` with standard 256 KB (`0x40000`) stride across GICR frames for all 8 cores.
* **CPU Topology & MPIDR:** Validated cluster and core affinitization matching Snapdragon 8 Gen 3 big.LITTLE / Prime architecture.
* **Firmware Memory Map:** Dynamic UEFI runtime and boot-services reservations defined in `giuliaPkg/Library/MemoryMapLib/MemoryMapLib.c`.
* **Kernel Errata Handling:** Dynamic Winload interception and section alignment slack cave injection enabled in `KernelErrataPatcherLib` to support modern ARM64 loaders.

---

## Credits & Acknowledgments

* **[Project Silicium](https://github.com/Project-Silicium)** — Unified Qualcomm UEFI firmware platform.
* **[Project Mu](https://microsoft.github.io/mu/)** — Microsoft's modular, open-source EDK2 fork.
* **[EDK2 / TianoCore](https://github.com/tianocore/edk2)** — Industry-standard EFI firmware framework.
* **[Renegade Project](https://renegade-project.tech/)** — Groundbreaking community research on Qualcomm WoA.
* **[WOA-Giulia Team](https://github.com/WOA-Giulia)** — OnePlus 13R / Ace 5 port maintainers and researchers.

---

## License

This project is licensed under the terms of the **MIT License** and **BSD-2-Clause-Patent License** where applicable. OEM binary drivers remain the property of Qualcomm Technologies, Inc. and OnePlus / Oplus.
