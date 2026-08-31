@echo off
REM TezFast Hamyon - botni ishga tushirish. Shu faylni IKKI MARTA bosing.
REM PowerShell ning imzosiz skript cheklovini chetlab otish uchun kerak.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0start-bot.ps1"
if errorlevel 1 pause
