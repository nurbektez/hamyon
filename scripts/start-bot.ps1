# TezFast Hamyon — botni ishga tushirish skripti
#
# Ishlatish: shu papkadagi start-bot.bat ni IKKI MARTA bosing.
# Yoki PowerShell da: powershell -ExecutionPolicy Bypass -File .\start-bot.ps1
#
# Skript nima qiladi:
#   1. bot.py ni topadi
#   2. Python ni topadi (py / python / python3)
#   3. requirements.txt bo'lsa kutubxonalarni o'rnatadi
#   4. .env ni tekshiradi (BOT_TOKEN bormi, WEBAPP_URL tunnelga qarab turmaganmi)
#   5. Boshqa nusxa ishlayotgan bo'lsa ogohlantiradi (409 Conflict sababi)
#   6. Botni ishga tushiradi, yiqilsa qayta ko'taradi, hammasini bot.log ga yozadi

function Say($msg, $color = 'Gray') { Write-Host $msg -ForegroundColor $color }
function Finish($code) { Write-Host ''; Read-Host 'Yopish uchun Enter bosing' | Out-Null; exit $code }

Say ''
Say '=== TezFast Hamyon — bot ishga tushirilmoqda ===' Cyan
Say ''

# ── 1. bot.py ──
$dir = $PSScriptRoot
$bot = $null
foreach ($c in @("$dir\bot.py", "$dir\..\bot.py")) {
  if (Test-Path $c) { $bot = (Resolve-Path $c).Path; break }
}
if (-not $bot) {
  Say 'bot.py topilmadi.' Red
  Say "Bu skriptni bot.py turgan papkaga (yoki uning ichidagi papkaga) ko'chiring." Yellow
  Finish 1
}
$root = Split-Path $bot -Parent
Set-Location $root
Say "bot.py    : $bot" Gray

# ── 2. Python ──
$pyExe = $null; $pyPre = @()
if     (Get-Command py      -ErrorAction SilentlyContinue) { $pyExe = 'py'; $pyPre = @('-3') }
elseif (Get-Command python  -ErrorAction SilentlyContinue) { $pyExe = 'python' }
elseif (Get-Command python3 -ErrorAction SilentlyContinue) { $pyExe = 'python3' }

if (-not $pyExe) {
  Say 'Python topilmadi.' Red
  Say 'https://python.org dan o''rnating va o''rnatishda "Add python.exe to PATH" ni belgilang.' Yellow
  Finish 1
}
$ver = (& $pyExe @pyPre --version 2>&1) -join ' '
if ($LASTEXITCODE -ne 0 -and $pyExe -eq 'py' -and (Get-Command python -ErrorAction SilentlyContinue)) {
  # "py" launcher bor, lekin Python 3 o'rnatilmagan — to'g'ridan-to'g'ri python ga o'tamiz
  $pyExe = 'python'; $pyPre = @()
  $ver = (& $pyExe --version 2>&1) -join ' '
}
if ($LASTEXITCODE -ne 0) {
  Say "Python ishga tushmadi: $ver" Red
  Say 'Python ni qayta o''rnating: https://python.org' Yellow
  Finish 1
}
Say "Python    : $ver" Gray

# ── 3. Kutubxonalar ──
$req = Join-Path $root 'requirements.txt'
if (Test-Path $req) {
  Say 'Kutubxonalar tekshirilmoqda...' Gray
  & $pyExe @pyPre -m pip install -q -r $req
  if ($LASTEXITCODE -ne 0) {
    Say 'pip install xato berdi — davom etamiz, lekin bot yiqilishi mumkin.' Yellow
  }
}

# ── 4. .env ──
$envFile = Join-Path $root '.env'
if (-not (Test-Path $envFile)) {
  Say "OGOHLANTIRISH: .env fayl yo'q ($envFile)" Yellow
  Say '  Ichida kamida BOT_TOKEN=... bo''lishi kerak.' Yellow
} else {
  $envText = Get-Content $envFile -Raw
  if ($envText -notmatch '(?m)^\s*BOT_TOKEN\s*=\s*\S') {
    Say 'OGOHLANTIRISH: .env da BOT_TOKEN topilmadi — bot ishga tushmaydi.' Yellow
  }
  if ($envText -match '(?m)^\s*WEBAPP_URL\s*=\s*(\S+)') {
    $u = $Matches[1]
    if ($u -match 'trycloudflare|ngrok|localhost\.run|loca\.lt|serveo') {
      Say ''
      Say 'OGOHLANTIRISH: WEBAPP_URL hali vaqtinchalik tunnelga qarab turibdi:' Yellow
      Say "  $u" Yellow
      Say '  Bu manzil har qayta ishga tushganda o''zgaradi. Doimiysi:' Yellow
      Say '  WEBAPP_URL=https://nurbektez.github.io/hamyon/' Yellow
      Say '  (o''zgartirgach botni qayta ishga tushiring va Telegramda /start bosing)' Yellow
    }
  }
}

# ── 5. Ikkinchi nusxa ──
$others = @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -match '^pythonw?\.exe$' -and $_.CommandLine -like '*bot.py*' })
if ($others.Count -gt 0) {
  Say ''
  Say "Diqqat: bot.py allaqachon ishlayapti (PID: $($others.ProcessId -join ', '))." Yellow
  Say 'Ikkita nusxa bir vaqtda ishlasa Telegram 409 Conflict beradi va bot javob bermay qo''yadi.' Yellow
  $a = Read-Host "Eskilarini yopib, yangisini ishga tushiraymi? (ha/yo'q)"
  if ($a -match '^(h|ha|y|yes)$') {
    $others | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
    Say 'Yopildi.' Gray
    Start-Sleep -Seconds 2
  } else {
    Say 'Bekor qilindi.' Gray
    Finish 0
  }
}

# ── 6. Ishga tushirish + qayta ko'tarish ──
$log = Join-Path $root 'bot.log'
Say ''
Say "Log       : $log" Gray
Say "To'xtatish : Ctrl+C. Bu oynani YOPSANGIZ bot ham o'chadi." Yellow
Say ''
Say '--- bot chiqishi ---' Cyan

$fails = 0
while ($true) {
  $started = Get-Date
  "=== $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ishga tushdi ===" |
    Out-File -FilePath $log -Append -Encoding utf8

  & $pyExe @pyPre -u $bot 2>&1 | Tee-Object -FilePath $log -Append
  $code = $LASTEXITCODE
  $ran  = (Get-Date) - $started

  if ($code -eq 0) { Say ''; Say 'Bot normal yakunladi.' Green; Finish 0 }

  if ($ran.TotalSeconds -lt 10) { $fails++ } else { $fails = 0 }

  Say ''
  Say "Bot to'xtadi (chiqish kodi $code, $([int]$ran.TotalSeconds) soniya ishladi)." Red

  if ($fails -ge 3) {
    Say 'Uch marta ketma-ket darhol yiqildi — qayta urinishni to''xtatdim.' Red
    Say "Yuqoridagi xato matnini o'qing (yoki $log ni oching) va shu matnni menga yuboring." Yellow
    Finish 1
  }

  Say '5 soniyadan keyin qayta ko''taraman...' Yellow
  Start-Sleep -Seconds 5
}
