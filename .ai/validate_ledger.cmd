@echo off
setlocal enabledelayedexpansion
set "LEDGER=%~1"
if "%LEDGER%"=="" set "LEDGER=%~dp0Implementation_Ledger.txt"
if not exist "%LEDGER%" (
    echo [PROTOCOL FAILURE] Ledger not found: %LEDGER%
    exit /b 1
)
set /p FIRST=<"%LEDGER%"
if "!FIRST!"=="" (
    echo [PROTOCOL FAILURE] Ledger is empty.
    exit /b 1
)
if "!FIRST:[VERSION:=!"=="!FIRST!" (
    echo [PROTOCOL FAILURE] First line has no VERSION field.
    exit /b 1
)
if "!FIRST:[COMMIT:=!"=="!FIRST!" (
    echo [PROTOCOL FAILURE] First line has no COMMIT field.
    exit /b 1
)
if "!FIRST:[TYPE:=!"=="!FIRST!" (
    echo [PROTOCOL FAILURE] First line has no TYPE field.
    exit /b 1
)
if "!FIRST:STATUS: ACTIVE=!"=="!FIRST!" (
    if "!FIRST:STATUS: HISTORY=!"=="!FIRST!" (
         echo [PROTOCOL FAILURE] No ACTIVE or HISTORY block found at top.
         exit /b 1
    )
)
for /f %%A in ('findstr /c:"STATUS: ACTIVE" "%LEDGER%" ^| find /c /v ""') do set "ACTIVE_COUNT=%%A"
if !ACTIVE_COUNT! GTR 1 (
    echo [PROTOCOL FAILURE] Expected at most one ACTIVE block. Found !ACTIVE_COUNT!.
    exit /b 1
)
for /f %%A in ('findstr /c:"========================= VERSION HISTORY =========================" "%LEDGER%" ^| find /c /v ""') do set "SEP_COUNT=%%A"
if not "!SEP_COUNT!"=="1" (
    echo [PROTOCOL FAILURE] Expected exactly one VERSION HISTORY separator. Found !SEP_COUNT!.
    exit /b 1
)
echo [SECURITY] Verifying historical commit hashes...
for /f "tokens=5 delims=|[] " %%H in ('findstr /r /c:"## \\\[VERSION:.*\\\] | \\\[COMMIT: [0-9a-f][0-9a-f]*\\\]" "%LEDGER%"') do (
    git cat-file -t %%H >nul 2>&1
    if errorlevel 1 (
        echo [INTEGRITY VIOLATION] Hash %%H in ledger does not exist in git history.
        exit /b 1
    )
    echo [OK] Verified %%H
)
findstr /v "STATUS: ACTIVE" "%LEDGER%" | findstr /c:"[PENDING_HUMAN_HASH]" >nul
if not errorlevel 1 (
    echo [HALLUCINATION DETECTED] [PENDING_HUMAN_HASH] found in historical or non-active block.
    exit /b 1
)
echo [PASS] Ledger integrity verified.
exit /b 0
