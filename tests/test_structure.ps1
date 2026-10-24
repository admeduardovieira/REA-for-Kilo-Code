# REA for Kilo Code - Structure tests
$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot

$required = @('AGENTS.md','README.md','scripts/validate-fork.ps1','.githooks/pre-push','tests/test_script.ps1','tests/test_structure.ps1')
$missing = @()
foreach ($r in $required) { $p = Join-Path $repoRoot $r; if (-not (Test-Path $p)) { $missing += $r } }
if ($missing.Count -gt 0) { Write-Error ('Missing required files: ' + ($missing -join ', ')); exit 1 }
Write-Host '[TEST] Structure OK' -ForegroundColor Green
exit 0
