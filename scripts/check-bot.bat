@echo off
REM TezFast Hamyon - bot nega javob bermayotganini tekshiradi.
REM Natija: shu papkada hisobot.txt fayli (token ichida yoq).
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0check-bot.ps1"
if errorlevel 1 pause
