@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "BRANCH=%~1"
if "%BRANCH%"=="" (
  for /f "tokens=*" %%i in ('git branch --show-current 2^>nul') do set "BRANCH=%%i"
)
if "%BRANCH%"=="" set "BRANCH=main"
set "MENU_PS1=%TEMP%\patch_leak_menu_%RANDOM%%RANDOM%.ps1"
set "CHOICE_FILE=%TEMP%\patch_leak_choice_%RANDOM%%RANDOM%.txt"
set "STATUS_FILE=%TEMP%\patch_leak_status_%RANDOM%%RANDOM%.txt"

:MENU
set "BREAD=Menu"
call :MAIN_MENU
if /I "%MENU_CHOICE%"=="Q" goto END
if /I "%MENU_CHOICE%"=="A" goto STEP2
if /I "%MENU_CHOICE%"=="B" goto STEP3
if /I "%MENU_CHOICE%"=="C" goto STEP4
if /I "%MENU_CHOICE%"=="D" goto STEP5
if /I "%MENU_CHOICE%"=="R" goto STEP6
if /I "%MENU_CHOICE%"=="X" goto STEP8
goto END

:STEP2
set "BREAD=Menu > Step 2"
call :RUN_COMMAND "git reset --hard HEAD~1" || goto STOP_FLOW
goto STEP7

:STEP3
set "BREAD=Menu > Step 3"
set "BASE_COMMIT="
set /P "BASE_COMMIT=Commit before the bad commit: "
if "!BASE_COMMIT!"=="" goto STOP_FLOW
echo In the editor, change pick to drop for the bad commit.
set "CMD_TEXT=git rebase -i !BASE_COMMIT!"
call :RUN_COMMAND_FROM_ENV || goto STOP_FLOW
goto STEP7

:STEP4
set "BREAD=Menu > Step 4"
set "PRIVATE_PATH="
set /P "PRIVATE_PATH=Private file or folder to remove from all history: "
if "!PRIVATE_PATH!"=="" goto STOP_FLOW
set CMD_TEXT=git filter-repo --path "!PRIVATE_PATH!" --invert-paths
call :RUN_COMMAND_FROM_ENV || goto STOP_FLOW
goto STEP7

:STEP5
set "BREAD=Menu > Step 5"
set "BACKUP_MSG="
set /P "BACKUP_MSG=Enter a name for your temporary backup (or press Enter for default): "
if "!BACKUP_MSG!"=="" set "BACKUP_MSG=backup before fixing leaked private item"
set CMD_TEXT=git stash push -u -m "!BACKUP_MSG!"
call :RUN_COMMAND_FROM_ENV "SKIP_DIRTY" || goto STOP_FLOW
call :RUN_COMMAND "git reset --hard HEAD~1" "SKIP_DIRTY" || goto STOP_FLOW
goto STEP7_FROM_5

:STEP7_FROM_5
set "BREAD=Menu > Step 5 > Step 7"
call :RUN_PUSH "git push origin %BRANCH% --force-with-lease" || goto STOP_FLOW
call :RUN_COMMAND "git stash pop" "SKIP_DIRTY" || goto STOP_FLOW
goto END_FLOW

:STEP6
set "BREAD=Menu > Step 6"
call :RUN_COMMAND "git reflog" "SKIP_DIRTY" || goto STOP_FLOW
set "SAFE_COMMIT="
set /P "SAFE_COMMIT=Safe commit hash: "
if "!SAFE_COMMIT!"=="" goto STOP_FLOW
set "CMD_TEXT=git reset --hard !SAFE_COMMIT!"
call :RUN_COMMAND_FROM_ENV || goto STOP_FLOW
call :RUN_PUSH "git push origin %BRANCH% --force-with-lease" || goto STOP_FLOW
goto END_FLOW

:STEP7
set "BREAD=%BREAD% > Step 7"
call :RUN_PUSH "git push origin %BRANCH% --force-with-lease" || goto STOP_FLOW
goto END_FLOW

:STEP7_FROM_5
set "BREAD=Menu > Step 5 > Step 7"
call :RUN_PUSH "git push origin %BRANCH% --force-with-lease" || goto STOP_FLOW
call :RUN_COMMAND "git stash pop" "SKIP_DIRTY" || goto STOP_FLOW
goto END_FLOW

:STEP8
set "BREAD=Menu > Step 8"
call :RUN_COMMAND "git reset --hard" || goto STOP_FLOW
goto END_FLOW

:STOP_FLOW
echo.
call :SHOW_BREAD_EXTRA "Stopped"
echo Stopped. Nothing was executed.
call :PAUSE_SCREEN
goto END

:END_FLOW
echo.
call :SHOW_BREAD_EXTRA "END"
echo Flow complete. Commands were printed only; nothing was executed.
call :PAUSE_SCREEN
goto END

:RUN_COMMAND
call :CONFIRM "%~1" "%~2" || exit /B 1
call :SHOW_COMMAND "%~1"
call :PAUSE_SCREEN
exit /B 0

:RUN_COMMAND_FROM_ENV
call :CONFIRM_FROM_ENV "%~1" || exit /B 1
call :SHOW_COMMAND_FROM_ENV
call :PAUSE_SCREEN
exit /B 0

:RUN_PUSH
call :CONFIRM_PUSH "%~1" || exit /B 1
call :SHOW_COMMAND "%~1"
call :PAUSE_SCREEN
exit /B 0

:CONFIRM
call :SHOW_BREAD
echo This will do:
call :PRINT_COMMAND "%~1"
echo.
set "CONFIRM_ANSWER="
set /P "CONFIRM_ANSWER=Do you want to continue? Type notno or no. Anything else is no: "
if /I "!CONFIRM_ANSWER!"=="notno" goto CONFIRM_NOTNO
echo Cancelled.
call :PAUSE_SCREEN
exit /B 1

:CONFIRM_FROM_ENV
call :SHOW_BREAD
echo This will do:
call :PRINT_COMMAND_FROM_ENV
echo.
set "CONFIRM_ANSWER="
set /P "CONFIRM_ANSWER=Do you want to continue? Type notno or no. Anything else is no: "
if /I "!CONFIRM_ANSWER!"=="notno" goto CONFIRM_FROM_ENV_NOTNO
echo Cancelled.
call :PAUSE_SCREEN
exit /B 1

:CONFIRM_FROM_ENV_NOTNO
call :DIRTY_GUARD "%~1"
if errorlevel 1 exit /B 1
exit /B 0

:CONFIRM_NOTNO
call :DIRTY_GUARD "%~2"
if errorlevel 1 exit /B 1
exit /B 0

:CONFIRM_PUSH
call :SHOW_BREAD
echo This will do:
call :PRINT_COMMAND "%~1"
echo.
echo WARNING:
echo   This updates the remote branch history.
echo   Make sure your current work is saved, committed, stashed, or backed up first.
echo   If you are not completely sure, answer no.
echo.
set "CONFIRM_ANSWER="
set /P "CONFIRM_ANSWER=Do you want to continue? Type notno or no. Anything else is no: "
if /I "!CONFIRM_ANSWER!"=="notno" goto CONFIRM_PUSH_NOTNO
echo Cancelled.
call :PAUSE_SCREEN
exit /B 1

:CONFIRM_PUSH_NOTNO
call :DIRTY_GUARD
if errorlevel 1 exit /B 1
exit /B 0

:DIRTY_GUARD
if /I "%~1"=="SKIP_DIRTY" exit /B 0
git status --short > "%STATUS_FILE%"
for %%A in ("%STATUS_FILE%") do if %%~zA EQU 0 (
  del /Q "%STATUS_FILE%" >nul 2>nul
  exit /B 0
)

echo.
call :SHOW_BREAD_EXTRA "Current work exists"
echo WARNING: modified, staged, or untracked files exist:
type "%STATUS_FILE%"
del /Q "%STATUS_FILE%" >nul 2>nul
echo.
call :DIRTY_MENU
exit /B 1

:DIRTY_MENU
set "DIRTY_CHOICE="
call :DIRTY_MENU_PS1
if /I "!DIRTY_CHOICE!"=="S" (
  set CMD_TEXT=git stash push -u -m "backup before patch leak"
  call :SHOW_COMMAND_FROM_ENV
)
if /I "!DIRTY_CHOICE!"=="A" call :SHOW_COMMAND "git add ."
if /I "!DIRTY_CHOICE!"=="C" (
  set CMD_TEXT=git commit -m "save work"
  call :SHOW_COMMAND_FROM_ENV
)
if /I "!DIRTY_CHOICE!"=="R" call :SHOW_COMMAND "review files first, then remove unwanted files manually"
if /I "!DIRTY_CHOICE!"=="K" echo Come back here after your working folder is clean.
if /I "!DIRTY_CHOICE!"=="P" echo Run this script again and choose Step 5 to preserve current work.
if not defined DIRTY_CHOICE echo Cancelled.
call :PAUSE_SCREEN
exit /B 0

:WAIT_DONE
echo.
set "MANUAL_DONE="
set /P "MANUAL_DONE=Are you done with your manual changes? Type done or no: "
if /I "!MANUAL_DONE!"=="done" exit /B 0
echo Cancelled.
call :PAUSE_SCREEN
exit /B 1

:SHOW_BREAD
echo.
set "BREAD_TEXT=Breadcrumb: !BREAD!"
powershell -NoProfile -Command "Write-Host $env:BREAD_TEXT -ForegroundColor Yellow"
set "BREAD_TEXT="
exit /B 0

:SHOW_BREAD_EXTRA
set "BREAD_TEXT=Breadcrumb: !BREAD! > %~1"
powershell -NoProfile -Command "Write-Host $env:BREAD_TEXT -ForegroundColor Yellow"
set "BREAD_TEXT="
exit /B 0

:SHOW_COMMAND
echo.
echo Command only. Nothing was executed:
call :PRINT_COMMAND "%~1"
exit /B 0

:SHOW_COMMAND_FROM_ENV
echo.
echo Command only. Nothing was executed:
call :PRINT_COMMAND_FROM_ENV
exit /B 0

:PRINT_COMMAND
set "CMD_TEXT=%~1"
powershell -NoProfile -Command "Write-Host ('  ' + $env:CMD_TEXT) -ForegroundColor Green"
set "CMD_TEXT="
exit /B 0

:PRINT_COMMAND_FROM_ENV
powershell -NoProfile -Command "Write-Host ('  ' + $env:CMD_TEXT) -ForegroundColor Green"
exit /B 0

:PAUSE_SCREEN
echo.
set "PAUSE_ANSWER="
set /P "PAUSE_ANSWER=Press Enter to continue..."
exit /B 0

:MAIN_MENU
set "MENU_CHOICE="
if exist "%CHOICE_FILE%" del /Q "%CHOICE_FILE%" >nul 2>nul
call :WRITE_MENU_PS1
powershell -NoProfile -ExecutionPolicy Bypass -File "%MENU_PS1%" "%BRANCH%" "%CHOICE_FILE%"
if exist "%CHOICE_FILE%" set /P "MENU_CHOICE="<"%CHOICE_FILE%"
if defined MENU_CHOICE exit /B 0
choice /C ABCDRXQ /N /M "Choose path: "
if errorlevel 7 set "MENU_CHOICE=Q" & exit /B 0
if errorlevel 6 set "MENU_CHOICE=X" & exit /B 0
if errorlevel 5 set "MENU_CHOICE=R" & exit /B 0
if errorlevel 4 set "MENU_CHOICE=D" & exit /B 0
if errorlevel 3 set "MENU_CHOICE=C" & exit /B 0
if errorlevel 2 set "MENU_CHOICE=B" & exit /B 0
if errorlevel 1 set "MENU_CHOICE=A" & exit /B 0
exit /B 0

:WRITE_MENU_PS1
> "%MENU_PS1%" echo param([string]$Branch = "main", [string]$ChoiceFile^)
>> "%MENU_PS1%" echo function Select-Choice([string]$Value^) {
>> "%MENU_PS1%" echo     Set-Content -LiteralPath $ChoiceFile -Value $Value -Encoding ASCII
>> "%MENU_PS1%" echo     exit
>> "%MENU_PS1%" echo }
>> "%MENU_PS1%" echo $items = @(
>> "%MENU_PS1%" echo     [pscustomobject]@{ Key = "A"; Text = "Forget the last thing I did on this computer"; Preview = "git reset --hard HEAD~1" },
>> "%MENU_PS1%" echo     [pscustomobject]@{ Key = "B"; Text = "Go back in time to fix a specific mistake"; Preview = "git rebase -i COMMIT_BEFORE_BAD" },
>> "%MENU_PS1%" echo     [pscustomobject]@{ Key = "C"; Text = "Scrub a private file out of every version ever saved"; Preview = "git filter-repo --path PRIVATE_PATH --invert-paths" },
>> "%MENU_PS1%" echo     [pscustomobject]@{ Key = "D"; Text = "Undo the last push but keep my current unsaved work safe"; Preview = "git stash push -u -m BACKUP_MESSAGE" },
>> "%MENU_PS1%" echo     [pscustomobject]@{ Key = "R"; Text = "Emergency recovery (if something went wrong)"; Preview = "git reflog" },
>> "%MENU_PS1%" echo     [pscustomobject]@{ Key = "X"; Text = "Clean up a broken working state"; Preview = "git reset --hard" },
>> "%MENU_PS1%" echo     [pscustomobject]@{ Key = "Q"; Text = "Quit"; Preview = "no command" }
>> "%MENU_PS1%" echo ^)
>> "%MENU_PS1%" echo if ([Console]::IsInputRedirected^) {
>> "%MENU_PS1%" echo     $line = [Console]::In.ReadLine(^)
>> "%MENU_PS1%" echo     if ([string]::IsNullOrWhiteSpace($line^)^) { Select-Choice "Q" }
>> "%MENU_PS1%" echo     $choice = $line.Trim(^).Substring(0, 1^).ToUpperInvariant(^)
>> "%MENU_PS1%" echo     if ($items.Key -contains $choice^) { Select-Choice $choice } else { Select-Choice "Q" }
>> "%MENU_PS1%" echo }
>> "%MENU_PS1%" echo $index = 0
>> "%MENU_PS1%" echo [Console]::CursorVisible = $false
>> "%MENU_PS1%" echo try {
>> "%MENU_PS1%" echo     while ($true^) {
>> "%MENU_PS1%" echo         Clear-Host
>> "%MENU_PS1%" echo         Write-Host ""
>> "%MENU_PS1%" echo         Write-Host "Fixing Leaked / Bad Commits" -ForegroundColor Cyan
>> "%MENU_PS1%" echo         Write-Host "Breadcrumb: Menu" -ForegroundColor Yellow
>> "%MENU_PS1%" echo         Write-Host "Branch: " -NoNewline
>> "%MENU_PS1%" echo         Write-Host $Branch -ForegroundColor Yellow
>> "%MENU_PS1%" echo         Write-Host ""
>> "%MENU_PS1%" echo         Write-Host "Use Up/Down arrows, then Enter. Press Esc to quit."
>> "%MENU_PS1%" echo         Write-Host ""
>> "%MENU_PS1%" echo         for ($i = 0; $i -lt $items.Count; $i++^) {
>> "%MENU_PS1%" echo             $line = "  " + $items[$i].Text
>> "%MENU_PS1%" echo             if ($i -eq $index^) {
>> "%MENU_PS1%" echo                 $line = "^> " + $items[$i].Text
>> "%MENU_PS1%" echo                 Write-Host $line -ForegroundColor Black -BackgroundColor Gray
>> "%MENU_PS1%" echo             } else {
>> "%MENU_PS1%" echo                 Write-Host $line
>> "%MENU_PS1%" echo             }
>> "%MENU_PS1%" echo         }
>> "%MENU_PS1%" echo         Write-Host ""
>> "%MENU_PS1%" echo         Write-Host "Status Bar (Command Preview)" -ForegroundColor Cyan
>> "%MENU_PS1%" echo         Write-Host ("  " + $items[$index].Preview) -ForegroundColor Green
>> "%MENU_PS1%" echo         $key = [Console]::ReadKey($true^)
>> "%MENU_PS1%" echo         if ($key.Key -eq [ConsoleKey]::UpArrow^) {
>> "%MENU_PS1%" echo             $index = ($index - 1 + $items.Count^) %% $items.Count
>> "%MENU_PS1%" echo         } elseif ($key.Key -eq [ConsoleKey]::DownArrow^) {
>> "%MENU_PS1%" echo             $index = ($index + 1^) %% $items.Count
>> "%MENU_PS1%" echo         } elseif ($key.Key -eq [ConsoleKey]::Enter^) {
>> "%MENU_PS1%" echo             Select-Choice $items[$index].Key
>> "%MENU_PS1%" echo         } elseif ($key.Key -eq [ConsoleKey]::Escape^) {
>> "%MENU_PS1%" echo             Select-Choice "Q"
>> "%MENU_PS1%" echo         }
>> "%MENU_PS1%" echo     }
>> "%MENU_PS1%" echo } finally {
>> "%MENU_PS1%" echo     [Console]::CursorVisible = $true
>> "%MENU_PS1%" echo }
exit /B 0

:DIRTY_MENU_PS1
set "DIRTY_CHOICE="
if exist "%CHOICE_FILE%" del /Q "%CHOICE_FILE%" >nul 2>nul
call :WRITE_DIRTY_PS1
powershell -NoProfile -ExecutionPolicy Bypass -File "%MENU_PS1%" "%CHOICE_FILE%" "%BREAD%"
if exist "%CHOICE_FILE%" set /P "DIRTY_CHOICE="<"%CHOICE_FILE%"
exit /B 0

:WRITE_DIRTY_PS1
> "%MENU_PS1%" echo param([string]$ChoiceFile, [string]$Bread = "Current command"^)
>> "%MENU_PS1%" echo function Select-Choice([string]$Value^) {
>> "%MENU_PS1%" echo     Set-Content -LiteralPath $ChoiceFile -Value $Value -Encoding ASCII
>> "%MENU_PS1%" echo     exit
>> "%MENU_PS1%" echo }
>> "%MENU_PS1%" echo $items = @(
>> "%MENU_PS1%" echo     [pscustomobject]@{ Key = "S"; Text = "Save my current work safely for later"; Preview = "git stash push -u -m BACKUP_MESSAGE" },
>> "%MENU_PS1%" echo     [pscustomobject]@{ Key = "A"; Text = "Get all my current work ready to be saved"; Preview = "git add ." },
>> "%MENU_PS1%" echo     [pscustomobject]@{ Key = "C"; Text = "Save my ready work with a note"; Preview = "git commit -m MESSAGE" },
>> "%MENU_PS1%" echo     [pscustomobject]@{ Key = "R"; Text = "Let me delete unwanted files myself first"; Preview = "no command" },
>> "%MENU_PS1%" echo     [pscustomobject]@{ Key = "K"; Text = "I'll come back when my folder is empty/clean"; Preview = "no command" },
>> "%MENU_PS1%" echo     [pscustomobject]@{ Key = "P"; Text = "Use the 'Keep my work safe' path"; Preview = "no command" }
>> "%MENU_PS1%" echo ^)
>> "%MENU_PS1%" echo if ([Console]::IsInputRedirected^) {
>> "%MENU_PS1%" echo     $line = [Console]::In.ReadLine(^)
>> "%MENU_PS1%" echo     if ([string]::IsNullOrWhiteSpace($line^)^) { Select-Choice "K" }
>> "%MENU_PS1%" echo     $choice = $line.Trim(^).Substring(0, 1^).ToUpperInvariant(^)
>> "%MENU_PS1%" echo     if ($items.Key -contains $choice^) { Select-Choice $choice } else { Select-Choice "K" }
>> "%MENU_PS1%" echo }
>> "%MENU_PS1%" echo $index = 0
>> "%MENU_PS1%" echo [Console]::CursorVisible = $false
>> "%MENU_PS1%" echo try {
>> "%MENU_PS1%" echo     while ($true^) {
>> "%MENU_PS1%" echo         Clear-Host
>> "%MENU_PS1%" echo         Write-Host ""
>> "%MENU_PS1%" echo         Write-Host "Unsaved Work Detected" -ForegroundColor Yellow
>> "%MENU_PS1%" echo         Write-Host ("Breadcrumb: " + $Bread + " > Unsaved work exists"^) -ForegroundColor Yellow
>> "%MENU_PS1%" echo         Write-Host ""
>> "%MENU_PS1%" echo         for ($i = 0; $i -lt $items.Count; $i++^) {
>> "%MENU_PS1%" echo             $line = "  " + $items[$i].Text
>> "%MENU_PS1%" echo             if ($i -eq $index^) {
>> "%MENU_PS1%" echo                 $line = "^> " + $items[$i].Text
>> "%MENU_PS1%" echo                 Write-Host $line -ForegroundColor Black -BackgroundColor Gray
>> "%MENU_PS1%" echo             } else {
>> "%MENU_PS1%" echo                 Write-Host $line
>> "%MENU_PS1%" echo             }
>> "%MENU_PS1%" echo         }
>> "%MENU_PS1%" echo         Write-Host ""
>> "%MENU_PS1%" echo         Write-Host "Status Bar (Command Preview)" -ForegroundColor Cyan
>> "%MENU_PS1%" echo         Write-Host ("  " + $items[$index].Preview) -ForegroundColor Green
>> "%MENU_PS1%" echo         $key = [Console]::ReadKey($true^)
>> "%MENU_PS1%" echo         if ($key.Key -eq [ConsoleKey]::UpArrow^) {
>> "%MENU_PS1%" echo             $index = ($index - 1 + $items.Count^) %% $items.Count
>> "%MENU_PS1%" echo         } elseif ($key.Key -eq [ConsoleKey]::DownArrow^) {
>> "%MENU_PS1%" echo             $index = ($index + 1^) %% $items.Count
>> "%MENU_PS1%" echo         } elseif ($key.Key -eq [ConsoleKey]::Enter^) {
>> "%MENU_PS1%" echo             Select-Choice $items[$index].Key
>> "%MENU_PS1%" echo         } elseif ($key.Key -eq [ConsoleKey]::Escape^) {
>> "%MENU_PS1%" echo             Select-Choice "K"
>> "%MENU_PS1%" echo         }
>> "%MENU_PS1%" echo     }
>> "%MENU_PS1%" echo } finally {
>> "%MENU_PS1%" echo     [Console]::CursorVisible = $true
>> "%MENU_PS1%" echo }
exit /B 0

:END
if exist "%MENU_PS1%" del /Q "%MENU_PS1%" >nul 2>nul
if exist "%CHOICE_FILE%" del /Q "%CHOICE_FILE%" >nul 2>nul
if exist "%STATUS_FILE%" del /Q "%STATUS_FILE%" >nul 2>nul
echo.
echo Done.
endlocal
