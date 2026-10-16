#!/bin/bash
# Trinea English: build the IPS patch from source + your own ROM.
#   usage: tools/build.sh "/path/to/Trinea (Japan).sfc" [insert_script.py options]
#     (or put the ROM at rom/Trinea (Japan).sfc, or set TRINEA_ROM)
# Pipeline: verify ROM -> font binaries from text sources -> English script blobs (inserter reads your ROM for
# script structure) -> pre-rendered system text -> asar patches on a copy of your ROM (32 Mbit HiROM) -> IPS.
# Output: build/trinea_en.ips (and build/trinea_en.sfc, the patched ROM, for testing; never distribute it).
# Options: --rumble   also build the optional RumbleShock rumble variant (asm/main_rumble.asm):
#                     build/trinea_dx_rumble.ips / .sfc. The standard build/trinea_en.ips is unaffected.
#          (always)   build/trinea_en.ips/.sfc = plain translation, and build/trinea_dx.ips/.sfc =
#                     all-in Trinea DX (asm/main_dx.asm: translation + rumble + splash/sound + perf + options).
#          --dx       accepted for compatibility (no-op).
set -euo pipefail
cd "$(dirname "$0")/.."

ROM="${TRINEA_ROM:-rom/Trinea (Japan).sfc}"
if [ $# -gt 0 ] && [ -f "$1" ]; then ROM="$1"; shift; fi
RUMBLE=0; ARGS=()
for a in "$@"; do if [ "$a" = "--rumble" ]; then RUMBLE=1; elif [ "$a" = "--dx" ]; then DX=1; else ARGS+=("$a"); fi; done
set -- ${ARGS[@]+"${ARGS[@]}"}
[ -f "$ROM" ] || { echo "ROM not found: $ROM"; echo "usage: tools/build.sh \"/path/to/Trinea (Japan).sfc\""; exit 1; }
export TRINEA_ROM="$(cd "$(dirname "$ROM")" && pwd)/$(basename "$ROM")"

# 1. verify: No-Intro "Trinea (Japan)", headerless, 2 MiB
python3 - "$TRINEA_ROM" <<'P'
import sys,hashlib,zlib
d=open(sys.argv[1],'rb').read()
md5=hashlib.md5(d).hexdigest(); crc='%08X'%(zlib.crc32(d)&0xffffffff)
if len(d)==0x200200: sys.exit('ROM has a 512-byte copier header; remove it first (headerless ROM required).')
if md5!='8622b25466d1cf31e8a8771838b02ca7' or crc!='C20419EC':
    sys.exit('Wrong ROM: md5 %s crc32 %s (expected md5 8622b25466d1cf31e8a8771838b02ca7, CRC32 C20419EC)'%(md5,crc))
print('ROM ok: Trinea (Japan), md5 %s, CRC32 %s'%(md5,crc))
P

# 2. tools: asar + flips (fetched and built from source on first run unless ASAR/FLIPS are set)
ASAR="${ASAR:-tools/bin/asar}"; FLIPS="${FLIPS:-tools/bin/flips}"
if [ ! -x "$ASAR" ] || [ ! -x "$FLIPS" ]; then tools/get_tools.sh; fi
python3 -c 'import numpy, PIL' 2>/dev/null || { echo "Python 3 with numpy and Pillow is required (pip install numpy pillow)"; exit 1; }

# 3. generated inputs (all under build/, git-ignored)
rm -rf build/gen build/font
mkdir -p build/gen build/font
python3 tools/py/build_font.py
python3 tools/py/build_small.py
python3 tools/py/insert_script.py "$@"
python3 tools/py/sysgfx.py

# 4. assemble onto a copy of the original
cp "$TRINEA_ROM" build/trinea_en.sfc
"$ASAR" --fix-checksum=on asm/main.asm build/trinea_en.sfc
python3 - <<'P'
R=open('build/trinea_en.sfc','rb').read()
assert len(R)==0x400000 and R[0xFFD7]==0x0C
c=sum(R)&0xFFFF; hc=R[0xFFDE]|R[0xFFDF]<<8; ic=R[0xFFDC]|R[0xFFDD]<<8
assert c==hc and (c^0xFFFF)==ic, (hex(c),hex(hc),hex(ic))
print('patched ROM ok: 32 Mbit, checksum %04X'%c)
P

# 5. IPS
rm -f build/trinea_en.ips
"$FLIPS" --create --ips "$TRINEA_ROM" build/trinea_en.sfc build/trinea_en.ips >/dev/null
md5sum build/trinea_en.ips build/trinea_en.sfc

# 6. optional variants (same translation + extras); standard IPS above is unaffected
variant() { # $1 = asm entry, $2 = output base name
  cp "$TRINEA_ROM" build/$2.sfc
  "$ASAR" --fix-checksum=on asm/$1 build/$2.sfc
  python3 -c "
R=open('build/$2.sfc','rb').read()
assert len(R)==0x400000
c=sum(R)&0xFFFF; hc=R[0xFFDE]|R[0xFFDF]<<8; ic=R[0xFFDC]|R[0xFFDD]<<8
assert c==hc and (c^0xFFFF)==ic
print('$2 ROM ok: checksum %04X'%c)"
  rm -f build/$2.ips
  "$FLIPS" --create --ips "$TRINEA_ROM" build/$2.sfc build/$2.ips >/dev/null
  md5sum build/$2.ips build/$2.sfc
}
if [ "$RUMBLE" = 1 ]; then variant main_rumble.asm trinea_dx_rumble; fi
variant main_dx.asm trinea_dx   # always: the all-in Trinea DX ROM
