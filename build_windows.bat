@echo off
REM Script untuk build Flutter Windows dengan Visual Studio 2022 generator

echo ========================================
echo Flutter Windows Build Script
echo Forcing Visual Studio 17 2022 Generator
echo ========================================
echo.

REM Set environment variable untuk memaksa CMake menggunakan VS 2022
set CMAKE_GENERATOR=Visual Studio 17 2022
set CMAKE_GENERATOR_PLATFORM=x64

echo Cleaning previous build...
call flutter clean

echo.
echo Getting dependencies...
call flutter pub get

echo.
echo Building Windows application with Visual Studio 2022...
call flutter build windows --release

echo.
echo ========================================
echo Build Complete!
echo ========================================
echo.
echo Executable location:
echo build\windows\x64\runner\Release\unit_activity.exe
echo.

pause
