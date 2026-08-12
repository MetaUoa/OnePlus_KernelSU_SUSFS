@echo off
setlocal

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\sync-upstream.ps1"
set "sync_exit=%ERRORLEVEL%"

echo.
if not "%sync_exit%"=="0" (
  echo Sync stopped. Review the message above.
) else (
  echo Sync and upload completed successfully.
)
pause
exit /b %sync_exit%
