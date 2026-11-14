# v24: быстрый прогон. Пример: powershell -File tools/t24.ps1 --test --only24
param([Parameter(ValueFromRemainingArguments=$true)][string[]]$rest)
$g = "C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe"
Set-Location (Join-Path $PSScriptRoot "..")
$a = @("--path", ".", "--") + $rest
$p = Start-Process -FilePath $g -ArgumentList $a -PassThru -Wait -WindowStyle Hidden -RedirectStandardError ../screenshots/err.txt -RedirectStandardOutput ../screenshots/out.txt
Select-String -Path ../screenshots/err.txt -Pattern "SCRIPT ERROR|Parse Error|ERROR: .*\.gd" -Context 0,2 | Select-Object -First 12 | ForEach-Object { $_.ToString() }
Select-String -Path ../screenshots/out.txt -Pattern "FAIL|TEST: итого" | ForEach-Object { $_.Line }
