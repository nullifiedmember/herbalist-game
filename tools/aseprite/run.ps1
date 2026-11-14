# Запуск скрипта Aseprite из командной строки: .\run.ps1 gen_stone.lua [only=rocks|ores|icons]
param([string]$Script, [string]$Only = "all")
$a = "C:\Program Files (x86)\Steam\steamapps\common\Aseprite\Aseprite.exe"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
New-Item -ItemType Directory -Force "$here\src" | Out-Null
$o = "$env:TEMP\ase_out.txt"; $e = "$env:TEMP\ase_err.txt"
$p = Start-Process $a -ArgumentList '-b', '--script-param', "only=$Only", '--script', "`"$here\$Script`"" -Wait -PassThru -NoNewWindow -RedirectStandardOutput $o -RedirectStandardError $e
"exit $($p.ExitCode)"
Get-Content $o, $e
