@echo off
setlocal enabledelayedexpansion
set "LEDGER=%~1"
if "%LEDGER%"=="" set "LEDGER=%~dp0Implementation_Ledger.txt"
if not exist "%LEDGER%" (
    echo FAIL: Ledger not found: %LEDGER%
    exit /b 1
)
set /p TOP_LINE=<"%LEDGER%"
if "!TOP_LINE:STATUS: ACTIVE=!"=="!TOP_LINE!" (
    if "!TOP_LINE:STATUS: HISTORY=!"=="!TOP_LINE!" (
        echo FAIL: First ledger block is not ACTIVE or HISTORY.
        exit /b 1
    )
)
for /f "tokens=2,4,6 delims=[]" %%A in ("!TOP_LINE!") do (
    set "VERSION_FIELD=%%A"
    set "COMMIT_FIELD=%%B"
    set "TYPE_FIELD=%%C"
)
set "VERSION=!VERSION_FIELD:VERSION: =!"
set "COMMIT=!COMMIT_FIELD:COMMIT: =!"
set "TYPE=!TYPE_FIELD:TYPE: =!"
echo VERSION=!VERSION!
echo COMMIT=!COMMIT!
echo TYPE=!TYPE!
exit /b 0
