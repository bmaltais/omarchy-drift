#!/usr/bin/env bash
# Record a tour with the devkit's recorder: scripts/tour.sh tours/hero.sh [--install]
export DEVKIT_APP_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
kit=${DEVKIT:-$DEVKIT_APP_ROOT/../omarchy-plugin-devkit}/bin/tour
[[ -x $kit ]] || { echo "set DEVKIT to a checkout of omarchy-plugin-devkit" >&2; exit 1; }
exec "$kit" "$@"
