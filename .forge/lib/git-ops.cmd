@echo off
REM ============================================================
REM   forge-git / lib/git-ops.cmd
REM   Git operations
REM
REM   Usage:
REM     call "git-ops.cmd" init           - init repo
REM     call "git-ops.cmd" branch_main    - rename branch to main
REM     call "git-ops.cmd" has_changes    - check for pending changes
REM     call "git-ops.cmd" commit "msg"   - commit with message
REM     call "git-ops.cmd" tag            - create tag
REM
REM   Return codes:
REM     0 = nothing to do (already exists / no changes)
REM     1 = action performed
REM ============================================================

REM --- Detectar PROJECT_ROOT ---
REM Si git-ops.cmd esta en .forge/lib/ -> PROJECT_ROOT = ..\..
REM Si git-ops.cmd esta en lib/       -> PROJECT_ROOT = ..
set "ROOT=%~dp0"
REM Detectar si estamos dentro de .forge
echo "%ROOT%" | find /i ".forge" >nul
if not errorlevel 1 (
    set "PROJECT_ROOT=%ROOT%..\.."
) else (
    set "PROJECT_ROOT=%ROOT%.."
)

if "%~1"=="init"        goto :init
if "%~1"=="branch_main" goto :branch_main
if "%~1"=="has_changes" goto :has_changes
if "%~1"=="commit"      goto :commit
if "%~1"=="tag"         goto :tag
goto :eof

:init
pushd "%PROJECT_ROOT%"
if exist ".git" (
    popd
    call "%~dp0ui.cmd" step 3/17 "Repositorio Git" "YA EXISTE"
    exit /b 0
)
git init -q
if errorlevel 1 (
    popd
    call "%~dp0ui.cmd" step 3/17 "Repositorio Git" "ERROR"
    exit /b 1
)
popd
call "%~dp0ui.cmd" step 3/17 "Repositorio Git" "CREADO"
exit /b 1

:branch_main
pushd "%PROJECT_ROOT%"
git branch -M %BRANCH_MAIN% >nul 2>nul
popd
call "%~dp0ui.cmd" step 4/17 "Rama principal: %BRANCH_MAIN%" "OK"
exit /b 0

:has_changes
pushd "%PROJECT_ROOT%"
git add -A >nul 2>nul
git diff --cached --quiet
set "RC=%ERRORLEVEL%"
popd
if %RC% NEQ 0 ( exit /b 1 ) else ( exit /b 0 )

:commit
set "MSG=%~2"
if "!MSG!"=="" set "MSG=%COMMIT_MESSAGE%"
pushd "%PROJECT_ROOT%"
git commit -q -m "!MSG!"
set "RC=%ERRORLEVEL%"
popd
if %RC% NEQ 0 ( exit /b 0 ) else ( exit /b 1 )

:tag
pushd "%PROJECT_ROOT%"
git rev-parse %TAG_INITIAL% >nul 2>nul
if not errorlevel 1 (
    popd
    exit /b 0
)
git rev-parse HEAD >nul 2>nul
if errorlevel 1 (
    popd
    exit /b 0
)
git tag -a %TAG_INITIAL% -m "%TAG_MESSAGE%" 2>nul
popd
exit /b 1