@echo off
rem Builds the Wordle game as a native debug executable.
rem
rem Output: bin/odin-wordle.exe
rem
rem Extra Odin flags are passed straight through, e.g. `build_exe.bat -o:speed`
rem for an optimized build.
setlocal

cd /d "%~dp0"

if not exist bin mkdir bin

odin build . -debug -out:bin/odin-wordle.exe %*
