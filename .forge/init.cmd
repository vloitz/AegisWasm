@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul 2>nul

REM ============================================================
REM   forge-git / .forge/init.cmd
REM   init.cmd SIEMPRE vive en .forge/
REM   PROJECT_ROOT es el padre (../)
REM ============================================================

pushd "%~dp0.."
set "PROJECT_ROOT=%CD%"
popd

set "FORGE_DIR=%~dp0"
set "LIB=%FORGE_DIR%lib"
set "TPL=%FORGE_DIR%templates"
set "CMDS=%FORGE_DIR%commands"

set "FORCE=0"
if /i "%~1"=="--force" set "FORCE=1"
if /i "%~1"=="force"   set "FORCE=1"
if /i "%~1"=="-f"      set "FORCE=1"

call "%FORGE_DIR%config.cmd"

pushd "%PROJECT_ROOT%"
for %%a in ("%CD%") do set "PROJECT_NAME=%%~nxa"
popd

call "%LIB%\ui.cmd" banner

cd /d "%PROJECT_ROOT%"

where node >nul 2>nul
if errorlevel 1 (
    echo   [1/17] Node.js    MISSING
    echo          Descargalo desde: https://nodejs.org/
    goto :abort
)
for /f "tokens=*" %%v in ('node --version 2^>nul') do set "NODE_VER=%%v"
call "%LIB%\ui.cmd" step 1/17 "Node.js !NODE_VER!" "OK"

where git >nul 2>nul
if errorlevel 1 (
    echo   [2/17] Git    MISSING
    echo          Descargalo desde: https://git-scm.com/download/win
    goto :abort
)
for /f "tokens=*" %%v in ('git --version 2^>nul') do set "GIT_VER=%%v"
call "%LIB%\ui.cmd" step 2/17 "!GIT_VER!" "OK"

call "%LIB%\git-ops.cmd" init
call "%LIB%\git-ops.cmd" branch_main

if exist ".forge\commands" (
    call "%LIB%\ui.cmd" step 5/17 "Estructura .forge/" "YA EXISTE"
) else (
    mkdir ".forge" 2>nul
    mkdir ".forge\commands" 2>nul
    mkdir ".forge\lib" 2>nul
    mkdir ".forge\templates" 2>nul
    call "%LIB%\ui.cmd" step 5/17 "Estructura .forge/" "CREADO"
)

if exist ".gitignore" (
    call "%LIB%\ui.cmd" step 6/17 ".gitignore" "YA EXISTE"
) else (
    call "%LIB%\templates.cmd" write_gitignore
    call "%LIB%\ui.cmd" step 6/17 ".gitignore universal" "CREADO"
)

if exist "README.md" (
    call "%LIB%\ui.cmd" step 7/17 "README.md" "YA EXISTE"
) else (
    call "%LIB%\templates.cmd" write_readme
    call "%LIB%\ui.cmd" step 7/17 "README.md adaptativo" "CREADO"
)

if exist "forge.cmd" (
    call "%LIB%\ui.cmd" step 8/17 "forge.cmd" "YA EXISTE"
) else (
    call "%LIB%\templates.cmd" write_forge
    call "%LIB%\ui.cmd" step 8/17 "forge.cmd menu" "CREADO"
)

if exist ".forge\commands\save.cmd" (
    call "%LIB%\ui.cmd" step 9/17 "save.cmd" "YA EXISTE"
) else (
    call "%LIB%\templates.cmd" write_save
    call "%LIB%\ui.cmd" step 9/17 "save.cmd" "CREADO"
)

if exist ".forge\commands\push.cmd" (
    call "%LIB%\ui.cmd" step 10/17 "push.cmd" "YA EXISTE"
) else (
    call "%LIB%\templates.cmd" write_push
    call "%LIB%\ui.cmd" step 10/17 "push.cmd" "CREADO"
)

if exist ".forge\commands\snapshots.cmd" (
    call "%LIB%\ui.cmd" step 11/17 "snapshots.cmd" "YA EXISTE"
) else (
    call "%LIB%\templates.cmd" write_snapshots
    call "%LIB%\ui.cmd" step 11/17 "snapshots.cmd" "CREADO"
)

if exist ".forge\commands\historial.cmd" (
    call "%LIB%\ui.cmd" step 12/17 "historial.cmd" "YA EXISTE"
) else (
    call "%LIB%\templates.cmd" write_historial
    call "%LIB%\ui.cmd" step 12/17 "historial.cmd" "CREADO"
)

if exist ".forge\commands\abrir.cmd" (
    call "%LIB%\ui.cmd" step 13/17 "abrir.cmd" "YA EXISTE"
) else (
    call "%LIB%\templates.cmd" write_abrir
    call "%LIB%\ui.cmd" step 13/17 "abrir.cmd" "CREADO"
)

if exist ".forge\commands\auditar.cmd" (
    call "%LIB%\ui.cmd" step 14/17 "auditar.cmd" "YA EXISTE"
) else (
    call "%LIB%\templates.cmd" write_auditar
    call "%LIB%\ui.cmd" step 14/17 "auditar.cmd" "CREADO"
)

if exist ".forge\commands\serve.cmd" (
    call "%LIB%\ui.cmd" step 15/17 "serve.cmd" "YA EXISTE"
) else (
    call "%LIB%\templates.cmd" write_serve
    call "%LIB%\ui.cmd" step 15/17 "serve.cmd" "CREADO"
)

call "%LIB%\git-ops.cmd" has_changes
if errorlevel 1 (
    set "USER_MSG="
    set /p "USER_MSG=  Mensaje del commit [Enter = default]: "
    if "!USER_MSG!"=="" set "USER_MSG=%COMMIT_MESSAGE%"
    call "%LIB%\git-ops.cmd" commit "!USER_MSG!"
    call "%LIB%\ui.cmd" step 16/17 "Commit: !USER_MSG!" "CREADO"
) else (
    call "%LIB%\ui.cmd" step 16/17 "Sin cambios para commit" "SKIP"
)

call "%LIB%\git-ops.cmd" tag
if errorlevel 1 (
    call "%LIB%\ui.cmd" step 17/17 "Tag %TAG_INITIAL%" "CREADO"
) else (
    call "%LIB%\ui.cmd" step 17/17 "Tag %TAG_INITIAL%" "YA EXISTE"
)

call "%LIB%\ui.cmd" done
call :shell_if_double_click
endlocal
exit /b 0

:abort
call "%LIB%\ui.cmd" abort
call :shell_if_double_click
endlocal
exit /b 1

:shell_if_double_click
if "%NO_PAUSE%"=="1" goto :eof
echo %cmdcmdline% | find /i "%~nx0" >nul
if errorlevel 1 goto :eof
echo.
echo   Sesion interactiva abierta. Escribe 'exit' para cerrar.
echo.
cmd /k
goto :eof