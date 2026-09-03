@echo off
chcp 65001 >nul
title Hamyon bot - tuzatish
echo.
echo ==========================================
echo   Hamyon bot chatini tekshirish/tuzatish
echo ==========================================
echo.
echo Bu oyna botni tekshiradi va topilgan muammoni tuzatadi.
echo O'zgartirishdan oldin fayllarning zaxirasi olinadi.
echo.
pause

set "SCRIPT=%~dp0bot_chatini_tekshir.ps1"
if exist "%SCRIPT%" goto :run

echo.
echo Skript yonida yo'q - GitHub'dan yuklab olinmoqda...
set "SCRIPT=%TEMP%\bot_chatini_tekshir.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol='Tls12'; Invoke-WebRequest 'https://raw.githubusercontent.com/nurbektez/hamyon/main/bot_chatini_tekshir.ps1' -OutFile '%TEMP%\bot_chatini_tekshir.ps1'"
if not exist "%SCRIPT%" (
  echo.
  echo Yuklab bo'lmadi. Internetni tekshiring yoki faylni qo'lda yuklang.
  pause
  exit /b 1
)

:run
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%" -Fix

echo.
echo Tayyor. Endi Telegramda botga /start yozib sinang.
pause
