#!/bin/bash
# Bisect ROMs: the all-in Trinea DX with ONE feature removed (run tools/build.sh first; same env/ROM arg).
# Output: build/tests/Trinea DX test <X> <desc>.sfc
set -e
cd "$(dirname "$0")/.."
TRINEA_ROM="$1"; ASAR="${ASAR:-tools/bin/asar}"
mkdir -p build/tests
for f in asm/test_*.asm; do
  n=$(basename "$f" .asm); n=${n#test_}; out="build/tests/Trinea DX test ${n%%_*} ${n#*_}.sfc"
  cp "$TRINEA_ROM" "$out"; "$ASAR" --fix-checksum=on "$f" "$out" >/dev/null; md5sum "$out"
done
