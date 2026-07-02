#!/usr/bin/env bash
# Builds the Wordle game as a native debug executable.
#
# Output: bin/odin-wordle(.exe)
#
# Extra Odin flags are passed straight through, e.g. `./build_exe.sh -o:speed`
# for an optimized build.
set -euo pipefail

cd "$(dirname "$0")"

mkdir -p bin

out="bin/odin-wordle"
case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*) out="bin/odin-wordle.exe" ;;
esac

odin build . -debug -out:"$out" "$@"
