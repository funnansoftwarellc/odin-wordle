#!/usr/bin/env bash
# Builds the Odin + raylib program for the web (WebAssembly via emscripten).
#
# Output goes to build/:  index.html, index.js, index.wasm, odin.js
#
# raylib's web build REQUIRES emscripten: the prebuilt raylib wasm library
# (vendor/raylib/wasm/libraylib.a) is compiled against emscripten + GLFW3, and
# the GL/canvas context can only be set up through emscripten's runtime. The
# plain core:sys/wasm/js runtime (odin.runWasm) cannot drive raylib.
set -euo pipefail

cd "$(dirname "$0")"

# Make emcc available (adjust EMSDK if you installed it elsewhere).
EMSDK="${EMSDK:-/opt/emsdk}"
export EMSDK_QUIET=1
if [[ -f "$EMSDK/emsdk_env.sh" ]]; then
    # shellcheck disable=SC1091
    source "$EMSDK/emsdk_env.sh" >/dev/null 2>&1
fi

if ! command -v emcc >/dev/null 2>&1; then
    echo "error: emcc not found. Install emscripten and/or set EMSDK." >&2
    exit 1
fi

OUT_DIR="build"
ODIN_PATH="$(odin root)"
mkdir -p "$OUT_DIR"

# 1) Compile Odin to a wasm object file.
#    - js_wasm32 so Odin emits `_start` (entry) + the odin_env imports.
#    - RAYLIB_WASM_LIB=env.o so the raylib symbols stay undefined here and are
#      resolved by emcc from the real libraylib.a below.
odin build . \
    -target:js_wasm32 \
    -build-mode:obj \
    -define:RAYLIB_WASM_LIB=env.o \
    -vet \
    -out:"$OUT_DIR/odin-demo.wasm.o"

# 2) Provide Odin's js runtime next to the page.
cp "$ODIN_PATH/core/sys/wasm/js/odin.js" "$OUT_DIR/odin.js"

# 3) Link with emcc, pulling in the prebuilt raylib wasm library and generating
#    index.html / index.js / index.wasm from our shell template.
emcc -o "$OUT_DIR/index.html" \
    "$OUT_DIR/odin-demo.wasm.o" \
    "$ODIN_PATH/vendor/raylib/wasm/libraylib.a" \
    -sUSE_GLFW=3 \
    -sWASM_BIGINT \
    -sASSERTIONS \
    -sINVOKE_RUN=0 \
    -sEXPORTED_RUNTIME_METHODS=HEAPF32 \
    -sGL_ENABLE_GET_PROC_ADDRESS \
    -sWARN_ON_UNDEFINED_SYMBOLS=0 \
    --shell-file web/shell.html

# 4) The object file is no longer needed.
rm -f "$OUT_DIR/odin-demo.wasm.o"

echo "Web build created in $OUT_DIR/ (open index.html via a web server)."
