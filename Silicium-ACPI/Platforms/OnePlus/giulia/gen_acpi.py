#!/usr/bin/env python3
"""Generate giulia ACPI tables from SM8650 DTS-verified constants."""
import struct
from pathlib import Path

OUT = Path(__file__).parent
GICD = 0x17100000
GICR = 0x17180000
MPIDRS = tuple(i << 8 for i in range(8))

def header(sig, length, revision, oem_rev=1):
    return struct.pack('<4sIBB6s8sI4sI', sig, length, revision, 0, b'OPLUS ', b'GIULIA  ', oem_rev, b'PYGI', 1)

def finish(data):
    data = bytearray(data)
    data[9] = (-sum(data)) & 0xff
    assert len(data) == struct.unpack_from('<I', data, 4)[0]
    assert sum(data) & 0xff == 0
    return bytes(data)

def madt(enabled_cores=6):
    body = struct.pack('<II', 0, 0)
    for uid, mpidr in enumerate(MPIDRS):
        entry = bytearray(80)
        struct.pack_into('<BBH', entry, 0, 0x0b, 80, 0)
        enabled = 1 if uid < enabled_cores else 0
        struct.pack_into('<III', entry, 4, uid, uid, enabled)
        struct.pack_into('<I', entry, 16, 0)     # PSCI parking protocol
        struct.pack_into('<I', entry, 20, 0x17)  # PMU GSIV
        struct.pack_into('<I', entry, 56, 0x19)  # VGIC maintenance GSIV
        # Per-core GICR: 256KB (0x40000) stride
        struct.pack_into('<Q', entry, 60, GICR + uid * 0x40000)
        struct.pack_into('<Q', entry, 68, mpidr)
        # GICC efficiency class:
        # CPU 0..1: Cortex-A520 (Little) -> 0
        # CPU 2..6: Cortex-A720 (Big)    -> 1
        # CPU 7:    Cortex-X4   (Prime)  -> 2
        eff = 0 if uid < 2 else (1 if uid < 7 else 2)
        entry[76] = eff
        assert struct.unpack_from('<Q', entry, 68)[0] == mpidr
        body += entry
    # GICD (Type 0x0C)
    body += struct.pack('<BBH I Q I B 3s', 0x0c, 24, 0, 0, GICD, 0, 3, b'\0\0\0')
    return finish(header(b'APIC', 36 + len(body), 5) + body)

(OUT / 'APIC.aml').write_bytes(madt(enabled_cores=6))
assert sum((OUT / 'APIC.aml').read_bytes()) & 0xff == 0
print("generated APIC.aml (256KB stride, CPU0-CPU5 enabled, 6 cores, correct efficiency classes); checksum=ok")
