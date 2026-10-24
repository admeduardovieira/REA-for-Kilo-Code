# REA for Kilo Code - Script validation tests
$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot | Split-Path -Parent
$validator = Join-Path $repoRoot 'scripts/validate-fork.ps1'
if (-not (Test-Path $validator)) { Write-Error 'validate-fork.ps1 not found'; exit 1 }
$errors = $null
[System.Management.Automation.Language.Parser]::ParseFile($validator, [ref]$null, [ref]$errors) | Out-Null
if ($errors.Count -gt 0) { $errors | ForEach-Object { Write-Error $_.Message }; exit 1 }
$content = Get-Content $validator -Raw
foreach ($c in @('ApprovedPaths','git diff','node --check')) { if ($content -notmatch [regex]::Escape($c)) { Write-Error ('Missing required check: ' + $c); exit 1 } }
Write-Host '[TEST] validate-fork.ps1 integrity OK' -ForegroundColor Green
exit 0
