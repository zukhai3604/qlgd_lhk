@echo off
echo ======================================
echo Quick Flutter Rebuild
echo ======================================
echo.

cd frontend

echo [1/3] Cleaning...
call flutter clean

echo.
echo [2/3] Getting dependencies...
call flutter pub get

echo.
echo [3/3] Ready to run!
echo Now execute: flutter run
echo.
pause
