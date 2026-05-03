@echo off
setlocal EnableExtensions

set "MENU_PS1=%~dp0menu.ps1"

call :WRITE_MENU
powershell -NoProfile -ExecutionPolicy Bypass -File "%MENU_PS1%"
goto END

:WRITE_MENU
> "%MENU_PS1%" echo $menu = @(
>> "%MENU_PS1%" echo     [pscustomobject]@{ Text = "I want to see the changes"; Command = "status" },
>> "%MENU_PS1%" echo     [pscustomobject]@{ Text = "I want to see the remote"; Command = "remote" },
>> "%MENU_PS1%" echo     [pscustomobject]@{ Text = "I want to see the branch"; Command = "branch" },
>> "%MENU_PS1%" echo     [pscustomobject]@{ Text = "I want to initialise"; Command = "init" },
>> "%MENU_PS1%" echo     [pscustomobject]@{ Text = "I want stage"; Command = "stage" },
>> "%MENU_PS1%" echo     [pscustomobject]@{ Text = "I want to cancel stage"; Command = "unstage" }
>> "%MENU_PS1%" echo ^)
>> "%MENU_PS1%" echo $index = 0
>> "%MENU_PS1%" echo.
>> "%MENU_PS1%" echo while ($true^) {
>> "%MENU_PS1%" echo     Clear-Host
>> "%MENU_PS1%" echo     Write-Host "GIT MENU`n" -ForegroundColor Cyan
>> "%MENU_PS1%" echo     Write-Host "I want to watch" -ForegroundColor Yellow
>> "%MENU_PS1%" echo.
>> "%MENU_PS1%" echo     for ($i=0; $i -lt $menu.Count; $i++^) {
>> "%MENU_PS1%" echo         if ($i -eq 3^) {
>> "%MENU_PS1%" echo             Write-Host ""
>> "%MENU_PS1%" echo             Write-Host "I want to act" -ForegroundColor Yellow
>> "%MENU_PS1%" echo         }
>> "%MENU_PS1%" echo         if ($i -eq $index^) {
>> "%MENU_PS1%" echo             Write-Host ("^> " + $menu[$i].Text^) -BackgroundColor White -ForegroundColor Black
>> "%MENU_PS1%" echo         } else {
>> "%MENU_PS1%" echo             Write-Host ("  " + $menu[$i].Text^)
>> "%MENU_PS1%" echo         }
>> "%MENU_PS1%" echo     }
>> "%MENU_PS1%" echo.
>> "%MENU_PS1%" echo     $key = [Console]::ReadKey($true^)
>> "%MENU_PS1%" echo.
>> "%MENU_PS1%" echo     if ($key.Key -eq "UpArrow"^) {
>> "%MENU_PS1%" echo         $index = ($index - 1 + $menu.Count^) %% $menu.Count
>> "%MENU_PS1%" echo     }
>> "%MENU_PS1%" echo     elseif ($key.Key -eq "DownArrow"^) {
>> "%MENU_PS1%" echo         $index = ($index + 1^) %% $menu.Count
>> "%MENU_PS1%" echo     }
>> "%MENU_PS1%" echo     elseif ($key.Key -eq "Enter"^) {
>> "%MENU_PS1%" echo         break
>> "%MENU_PS1%" echo     }
>> "%MENU_PS1%" echo     elseif ($key.Key -eq "Escape"^) {
>> "%MENU_PS1%" echo         exit
>> "%MENU_PS1%" echo     }
>> "%MENU_PS1%" echo }
>> "%MENU_PS1%" echo.
>> "%MENU_PS1%" echo Clear-Host
>> "%MENU_PS1%" echo.
>> "%MENU_PS1%" echo switch ($menu[$index].Command^) {
>> "%MENU_PS1%" echo     "status" { git status }
>> "%MENU_PS1%" echo     "remote" { git remote -v }
>> "%MENU_PS1%" echo     "branch" { git branch }
>> "%MENU_PS1%" echo     "init" { git init }
>> "%MENU_PS1%" echo     "stage" { git add . }
>> "%MENU_PS1%" echo     "unstage" { git reset HEAD }
>> "%MENU_PS1%" echo }
exit /B 0

:END
if exist "%MENU_PS1%" del /Q "%MENU_PS1%" >nul 2>nul
endlocal
