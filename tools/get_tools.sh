#!/bin/bash
# Fetch and build the third-party command-line tools the build needs. Nothing is vendored in this repo.
#   asar  1.91  (SNES assembler, LGPL-3.0)   https://github.com/RPGHacker/asar       tag v1.91
#   Flips       (IPS/BPS patcher, GPL-3.0)   https://github.com/Alcaro/Flips         commit ff216a7 (final master)
# Requirements: git, cmake, make, a C/C++ compiler (g++ / clang++).
# Result: tools/bin/asar and tools/bin/flips (git-ignored). You can also point ASAR=/path and FLIPS=/path at
# existing binaries when running tools/build.sh.
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p bin src
ASAR_TAG=v1.91
FLIPS_REV=ff216a75df0987047a67d7923567dc4482ce07ac
JOBS=$(nproc 2>/dev/null || echo 2)

if [ ! -x bin/asar ]; then
  [ -d src/asar ] || git clone --depth 1 --branch "$ASAR_TAG" https://github.com/RPGHacker/asar.git src/asar
  cmake -S src/asar/src -B src/asar/build -DCMAKE_BUILD_TYPE=Release >/dev/null
  cmake --build src/asar/build --target asar-standalone -j"$JOBS" >/dev/null
  cp "$(find src/asar/build -type f -name asar -perm -u+x | head -1)" bin/asar
fi

if [ ! -x bin/flips ]; then
  if [ ! -d src/flips ]; then
    git init -q src/flips
    git -C src/flips remote add origin https://github.com/Alcaro/Flips.git
    git -C src/flips fetch -q --depth 1 origin "$FLIPS_REV"
    git -C src/flips checkout -q FETCH_HEAD
  fi
  make -C src/flips TARGET=cli -j"$JOBS" >/dev/null
  cp src/flips/flips bin/flips
fi

bin/asar --version | head -1
echo "flips: $(bin/flips --version 2>&1 | head -1)"
