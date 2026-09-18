@echo off
REM ============================================================
REM   forge-git / lib/templates.cmd
REM   Copies templates from templates/ to destinations
REM ============================================================

if "%~1"=="write_gitignore"  goto :write_gitignore
if "%~1"=="write_readme"     goto :write_readme
if "%~1"=="write_forge"      goto :write_forge
if "%~1"=="write_save"       goto :write_save
if "%~1"=="write_push"       goto :write_push
if "%~1"=="write_snapshots"  goto :write_snapshots
if "%~1"=="write_historial"  goto :write_historial
if "%~1"=="write_abrir"      goto :write_abrir
if "%~1"=="write_auditar"    goto :write_auditar
if "%~1"=="write_serve"      goto :write_serve
goto :eof

:write_gitignore
call :copy_root "gitignore.tpl" ".gitignore"
goto :eof

:write_readme
call :apply_root "readme.md.tpl" "README.md"
goto :eof

:write_forge
call :copy_root "forge.cmd.tpl" "forge.cmd"
goto :eof

:write_save
call :copy_cmd "save.cmd.tpl" "save.cmd"
goto :eof

:write_push
call :copy_cmd "push.cmd.tpl" "push.cmd"
goto :eof

:write_snapshots
call :copy_cmd "snapshots.cmd.tpl" "snapshots.cmd"
goto :eof

:write_historial
call :copy_cmd "historial.cmd.tpl" "historial.cmd"
goto :eof

:write_abrir
call :copy_cmd "abrir.cmd.tpl" "abrir.cmd"
goto :eof

:write_auditar
call :copy_cmd "auditar.cmd.tpl" "auditar.cmd"
goto :eof

:write_serve
call :copy_cmd "serve.cmd.tpl" "serve.cmd"
call :copy_forge_root "serve-static.js" "serve-static.js"
goto :eof

:copy_root
set "SRC=%~dp0..\templates\%~1"
set "DST=%~dp0..\..\%~2"
if not exist "%SRC%" (
    echo   [X] Template no encontrado: %SRC%
    exit /b 1
)
copy /Y "%SRC%" "%DST%" >nul
exit /b 0

:copy_cmd
set "SRC=%~dp0..\templates\%~1"
set "DST=%~dp0..\commands\%~2"
if not exist "%SRC%" (
    echo   [X] Template no encontrado: %SRC%
    exit /b 1
)
copy /Y "%SRC%" "%DST%" >nul
exit /b 0

:copy_forge_root
set "SRC=%~dp0..\templates\%~1"
set "DST=%~dp0..\%~2"
if not exist "%SRC%" (
    echo   [X] Template no encontrado: %SRC%
    exit /b 1
)
copy /Y "%SRC%" "%DST%" >nul
exit /b 0

:apply_root
set "SRC=%~dp0..\templates\%~1"
set "DST=%~dp0..\..\%~2"
if not exist "%SRC%" (
    echo   [X] Template no encontrado: %SRC%
    exit /b 1
)
powershell -NoProfile -ExecutionPolicy Bypass -Command "$c = Get-Content -Raw -LiteralPath '%SRC%'; $c = $c.Replace('{{PROJECT_NAME}}', '%PROJECT_NAME%'); $c = $c.Replace('{{FG_VERSION}}', '%FG_VERSION%'); [System.IO.File]::WriteAllText('%DST%', $c, [System.Text.UTF8Encoding]::new($false))"
exit /b 0
