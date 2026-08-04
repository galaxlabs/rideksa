@echo off
REM RideKSA Deploy Script
REM =====================

echo === RideKSA - Firebase Deploy ===
echo.

REM 1. Build Release APK
echo [1/3] Building release APK...
call flutter build apk --release
if %ERRORLEVEL% neq 0 (
    echo Build failed! Fix errors and try again.
    exit /b 1
)
echo APK built: build\app\outputs\flutter-apk\app-release.apk
echo.

REM 2. Upload to Firebase App Distribution
echo [2/3] Uploading to Firebase App Distribution...
call firebase appdistribution:distribute build\app\outputs\flutter-apk\app-release.apk ^
    --app 1:482669449729:android:70e002d708a14a0ab3a600 ^
    --groups qa-testers ^
    --release-notes "RideKSA build %date% %time%"
if %ERRORLEVEL% neq 0 (
    echo.
    echo Upload failed. Make sure you are logged in:
    echo   firebase login
    echo.
    exit /b 1
)
echo Upload successful! Testers will receive an email.
echo.

REM 3. Deploy Web (optional)
echo [3/3] Do you want to deploy web version? (y/n)
set /p DEPLOY_WEB=
if /i "%DEPLOY_WEB%"=="y" (
    echo Building web...
    call flutter build web
    echo Deploying to Firebase Hosting...
    call firebase deploy --only hosting
)

echo.
echo === Done! ===
