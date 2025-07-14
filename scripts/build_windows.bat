@echo off
REM Build script for Windows - MTG Card Display
REM Usage: build_windows.bat [debug|release]

set BUILD_MODE=%1
if "%BUILD_MODE%"=="" set BUILD_MODE=debug

echo 🃏 MTG Card Display - Windows Build Script
echo Build mode: %BUILD_MODE%

REM Check if Flutter is installed
flutter --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Flutter not found. Please install Flutter first.
    exit /b 1
)

REM Check if we're in the project directory
if not exist pubspec.yaml (
    echo ❌ Please run this script from the project root directory.
    exit /b 1
)

echo 📦 Installing dependencies...
flutter pub get
if %errorlevel% neq 0 (
    echo ❌ Failed to install dependencies
    exit /b 1
)

echo 🔧 Generating code...
flutter packages pub run build_runner build --delete-conflicting-outputs
if %errorlevel% neq 0 (
    echo ❌ Failed to generate code
    exit /b 1
)

if "%BUILD_MODE%"=="release" (
    echo 🏗️ Building Windows release version...
    flutter build windows --release
    if %errorlevel% neq 0 (
        echo ❌ Failed to build release version
        exit /b 1
    )
    echo ✅ Build complete! Executable at: build\windows\runner\Release\random_mtg_card.exe
) else (
    echo 🏗️ Building Windows debug version...
    flutter build windows --debug
    if %errorlevel% neq 0 (
        echo ❌ Failed to build debug version
        exit /b 1
    )
    echo ✅ Build complete! Executable at: build\windows\runner\Debug\random_mtg_card.exe
)

echo 🎉 Windows build completed successfully!
echo.
echo To run the app:
if "%BUILD_MODE%"=="release" (
    echo   build\windows\runner\Release\random_mtg_card.exe
) else (
    echo   build\windows\runner\Debug\random_mtg_card.exe
)
echo.
echo To run tests:
echo   flutter test
echo   flutter test integration_test/ 