# Script to fix Firebase C++ SDK CMake version issue
$firebaseCMake = "D:\PLATFORM\ukm\Unit Activity Dev 2\Unit-Activity\build\windows\x64\extracted\firebase_cpp_sdk_windows\CMakeLists.txt"

if (Test-Path $firebaseCMake) {
    Write-Host "Fixing Firebase CMake version..."
    $content = Get-Content $firebaseCMake -Raw
    $content = $content -replace 'cmake_minimum_required\(VERSION 3\.1\)', 'cmake_minimum_required(VERSION 3.5)'
    Set-Content $firebaseCMake -Value $content
    Write-Host "Fixed!"
} else {
    Write-Host "Firebase CMake file not found yet. Waiting for extraction..."
}
