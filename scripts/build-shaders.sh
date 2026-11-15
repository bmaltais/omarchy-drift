#!/usr/bin/env bash
# Compile the shaders for Qt's RHI. The .qsb outputs are committed so a plugin install needs no Qt tools.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/../shaders"
qsb=${QSB:-/usr/lib/qt6/bin/qsb}
for f in *.frag; do
  "$qsb" --qt6 -o "$f.qsb" "$f"
done
echo "build-shaders: ok"
