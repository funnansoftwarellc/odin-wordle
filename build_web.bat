@echo off
rem Builds the Wordle game for the web (WebAssembly) using karl2d's web build tool.
rem
rem karl2d renders through its own WebGL backend on the plain core:sys/wasm/js
rem runtime, so -- unlike a raylib project -- no emscripten is required. The tool
rem generates a small web entry that calls this package's init/step/shutdown,
rem compiles to bin/web/main.wasm, and drops index.html + odin.js beside it.
rem
rem Output: bin/web/  -- serve it with any static web server, e.g.
rem   python -m http.server --directory bin/web
rem
rem Extra Odin flags are passed straight through, e.g. `build_web.bat -o:size`
rem for a smaller, faster-loading build.
setlocal

cd /d "%~dp0"

odin run karl2d/build_web -- . %*
