# Build script that automatically patches Firebase CMake issue
Write-Host "Starting Flutter Windows build with Firebase CMake patch..." -ForegroundColor Green

# Start flutter build in background
$job = Start-Job -ScriptBlock {
    Set-Location "D:\PLATFORM\ukm\Unit Activity Dev 2\Unit-Activity"
    flutter build windows --debug 2>&1
}

# Monitor for Firebase extraction
$firebaseCMake = "D:\PLATFORM\ukm\Unit Activity Dev 2\Unit-Activity\build\windows\x64\extracted\firebase_cpp_sdk_windows\CMakeLists.txt"
$patched = $false

Write-Host "Waiting for Firebase SDK extraction..." -ForegroundColor Yellow

while ($job.State -eq 'Running') {
    if (-not $patched -and (Test-Path $firebaseCMake)) {
        Write-Host "Firebase SDK detected! Applying CMake version patch..." -ForegroundColor Cyan
        Start-Sleep -Seconds 1
        
        try {
            $content = Get-Content $firebaseCMake -Raw
            if ($content -match 'cmake_minimum_required\(VERSION 3\.1\)') {
                $content = $content -replace 'cmake_minimum_required\(VERSION 3\.1\)', 'cmake_minimum_required(VERSION 3.5)'
                Set-Content $firebaseCMake -Value $content -NoNewline
                Write-Host "Firebase CMake patched successfully!" -ForegroundColor Green
                $patched = $true
            }
        } catch {
            Write-Host "Warning: Could not patch file" -ForegroundColor Yellow
        }
    }
    
    Receive-Job $job
    Start-Sleep -Milliseconds 500
}

Receive-Job $job
Remove-Job $job

Write-Host "Build process completed." -ForegroundColor Green
