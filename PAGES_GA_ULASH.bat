@echo off
chcp 65001 >nul
title Hamyon - bot chatini va mini appni tuzatish
echo.
echo ==========================================
echo   Hamyon - tuzatish
echo ==========================================
echo.
echo Bu oyna ikkita muammoni birga hal qiladi:
echo.
echo   1. Bot chati jim - webhook o'lik tunnel manzilida qotib qolgan
echo   2. Mini app ochilmaydi (Error 1033) - tunnel o'lgan
echo.
echo Ikkalasining sababi bitta: cloudflare tunneli.
echo Tunnel olib tashlanadi, mini app doimiy manzilga o'tadi:
echo   https://nurbektez.github.io/hamyon/
echo.
echo Avval faqat NIMA o'zgarishini ko'rsatadi. Hech narsa yozilmaydi.
echo.
pause

set "SCRIPT=%~dp0botni_pages_ga_ulash.ps1"
if exist "%SCRIPT%" goto :preview

echo.
echo Skript yonida yo'q - GitHub'dan yuklab olinmoqda...
set "SCRIPT=%TEMP%\botni_pages_ga_ulash.ps1"
set "RAW=https://raw.githubusercontent.com/nurbektez/hamyon"
powershell -NoProfile -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol='Tls12'; try { Invoke-WebRequest '%RAW%/claude/local-mini-app-edit-46x5db/botni_pages_ga_ulash.ps1' -OutFile '%SCRIPT%' } catch { Invoke-WebRequest '%RAW%/main/botni_pages_ga_ulash.ps1' -OutFile '%SCRIPT%' }"
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
echo Bot javob bermasa - kompyuterda bot.py ishlab turganini tekshiring.
pause
