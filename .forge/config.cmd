REM ============================================================
REM   forge-git / config.cmd
REM   Configuration - edit these values to customize
REM   Called from init.cmd via: call config.cmd
REM ============================================================

set "FG_VERSION=1.5.8"
set "TAG_INITIAL=v1.0.0"
set "TAG_MESSAGE=Primera version estable"
set "BRANCH_MAIN=main"
set "COMMIT_MESSAGE=chore: initial commit"

REM --- Exclusions for subir.cmd (robocopy) ---
set "EXCLUDE_DIRS=.git versiones old_versions backup backups node_modules __pycache__ venv .venv env dist build out cache .cache .parcel-cache .vite .vscode .idea"
set "EXCLUDE_FILES=*.log *.tmp *.bak *.orig Thumbs.db .DS_Store"