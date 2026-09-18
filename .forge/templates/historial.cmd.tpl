@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul 2>nul

cd /d "%~dp0..\.."

REM --- Colores ANSI ---
for /F %%a in ('echo prompt $E ^| cmd') do set "ESC=%%a"
if "!ESC!"=="" (
    set "C_CY=" & set "C_BC=" & set "C_GR=" & set "C_YE="
    set "C_RE=" & set "C_GY=" & set "C_WH=" & set "C_RS="
) else (
    set "C_CY=!ESC![36m"  & set "C_BC=!ESC![96m"
    set "C_GR=!ESC![32m"  & set "C_YE=!ESC![33m"
    set "C_RE=!ESC![31m"  & set "C_GY=!ESC![90m"
    set "C_WH=!ESC![97m"  & set "C_RS=!ESC![0m"
)

echo.
echo   !C_CY!============================================!C_RS!
echo   !C_BC! HISTORIAL!C_RS! !C_GY!- Vista rapida del proyecto!C_RS!
echo   !C_CY!============================================!C_RS!
echo.

REM --- COMMITS ---
if not exist ".git" (
    echo   !C_RE![X]!C_RS! Sin repositorio Git.
    goto :tags
)

echo   !C_CY!-------------------------------------------------------------!C_RS!
echo   !C_BC! ULTIMOS 20 COMMITS!C_RS!
echo   !C_CY!-------------------------------------------------------------!C_RS!
echo   !C_GY! IDX    FECHA                 HASH      MENSAJE!C_RS!
echo   !C_CY!-------------------------------------------------------------!C_RS!

git log -n 20 --date=format:"%%Y-%%m-%%d %%H:%%M:%%S" --pretty=format:"%%h %%ad %%s" > "%TEMP%\fgh_log.txt" 2>nul

set "IDX=0"
for /f "delims=" %%L in ('type "%TEMP%\fgh_log.txt"') do (
    set "LINE=%%L"
    set "HASH=!LINE:~0,7!"
    set "DT=!LINE:~8,19!"
    set "MSG=!LINE:~28!"
    echo   !C_YE![!IDX!]!C_RS! !C_GY!!DT!!C_RS!  !C_YE!!HASH!!C_RS!  !C_WH!!MSG!!C_RS!
    set /a IDX+=1
)
del "%TEMP%\fgh_log.txt" >nul 2>nul
echo   !C_CY!-------------------------------------------------------------!C_RS!
echo.

:tags
echo   !C_CY!-------------------------------------------------------------!C_RS!
echo   !C_BC! TAGS!C_RS!
echo   !C_CY!-------------------------------------------------------------!C_RS!
if exist ".git" git tag -l
echo.

echo   !C_CY!-------------------------------------------------------------!C_RS!
echo   !C_BC! SNAPSHOTS!C_RS!
echo   !C_CY!-------------------------------------------------------------!C_RS!
if exist "versiones" goto :show_snaps
echo   !C_GY!sin snapshots!C_RS!
goto :end_snaps

:show_snaps
dir /b /o-n "versiones" 2>nul

:end_snaps
echo   !C_CY!-------------------------------------------------------------!C_RS!
echo.

call :shell_if_double_click
endlocal
exit /b 0

:shell_if_double_click
if "%NO_PAUSE%"=="1" goto :eof
echo %cmdcmdline% | find /i "%~nx0" >nul
if errorlevel 1 goto :eof
echo.
echo   !C_GY!Sesion interactiva. Escribe 'exit' para cerrar.!C_RS!
echo.
cmd /k
goto :eof