@echo off
chcp 65001 >nul
title Hamyon - botni doimiy manzilga ulash
echo.
echo ==========================================
echo   Botni GitHub Pages ga ulash
echo ==========================================
echo.
echo Cloudflare tunneli o'rniga (Error 1033) bot doimiy manzilga ulanadi:
echo   https://nurbektez.github.io/hamyon/
echo.
echo Bu manzil hech qachon o'zgarmaydi - tunnel butunlay kerak bo'lmaydi.
echo.
echo Avval faqat NIMA o'zgarishini ko'rsatadi. Hech narsa yozilmaydi.
echo.
pause

set "SCRIPT=%~dp0botni_pages_ga_ulash.ps1"
if exist "%SCRIPT%" goto :preview

echo.
echo Skript yonida yo'q - GitHub'dan yuklab olinmoqda...
set "SCRIPT=%TEMP%\botni_pages_ga_ulash.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol='Tls12'; Invoke-WebRequest 'https://raw.githubusercontent.com/nurbektez/hamyon/main/botni_pages_ga_ulash.ps1' -OutFile '%TEMP%\botni_pages_ga_ulash.ps1'"
if not exist "%SCRIPT%" (
  echo.
  echo Yuklab bo'lmadi. Internetni tekshiring yoki faylni qo'lda yuklang:
  echo   https://github.com/nurbektez/hamyon/blob/main/botni_pages_ga_ulash.ps1
  pause
  exit /b 1
)

:preview
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%"
if errorlevel 1 (
  echo.
  echo Skript xato berdi - yuqoridagi xabarni o'qing.
  echo Bot papkasi topilmagan bo'lsa, bu faylni bot papkasiga ko'chirib qayta bosing.
  pause
  exit /b 1
)

echo.
echo ==========================================
echo   Yuqorida nima o'zgarishi yozilgan.
echo   Rozi bo'lsangiz - o'zgartiramiz va botni qayta ishga tushiramiz.
echo   Har bir faylning zaxirasi olinadi (.bak-...).
echo ==========================================
echo.
set "JAVOB="
set /p JAVOB="Davom etamizmi? ha deb yozing (bekor qilish - Enter): "
if /i not "%JAVOB%"=="ha" (
  echo.
  echo Bekor qilindi - hech narsa o'zgartirilmadi.
  pause
  exit /b 0
)

echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%" -Apply -Restart
if errorlevel 1 (
  echo.
  echo O'zgartirishda xato. Zaxira fayllar (.bak-...) bot papkasida qoldi.
  pause
  exit /b 1
)

echo.
echo Tayyor. Endi Telegramda botga /start yozing va "Hamyon" tugmasini bosing.
pause
