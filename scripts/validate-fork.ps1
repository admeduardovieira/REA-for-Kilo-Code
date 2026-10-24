# REA for Kilo Code - Fork Validation Script
param(
    [Parameter(Mandatory=$true)]
    [string]$ForkPath,
    [string]$OriginalPath = $null
)

Write-Host "[REA] Validating fork: $ForkPath" -ForegroundColor Cyan

if (-not (Test-Path $ForkPath)) {
    Write-Error "Fork path not found: $ForkPath"
    exit 1
}

Push-Location $ForkPath

if (-not (Test-Path ".git")) {
    Write-Error "Not a git repository"
    Pop-Location
    exit 1
}

Write-Host "[REA] Checking remotes..." -ForegroundColor Yellow
git remote -v

Write-Host "
[REA] Diff stat:" -ForegroundColor Yellow
git diff --stat | Out-Host

Write-Host "
[REA] Modified files:" -ForegroundColor Yellow
git diff --name-only | Out-Host

Write-Host "
[REA] Checking JS syntax..." -ForegroundColor Yellow
$jsFiles = git diff --name-only | Where-Object { $_ -match '.js$' }
foreach ($file in $jsFiles) {
    if (Test-Path $file) {
        Write-Host "  Checking $file" -ForegroundColor Gray
        node --check $file
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Syntax error in $file"
            Pop-Location
            exit 1
        }
    }
}

Write-Host "
[REA] File count:" -ForegroundColor Yellow
$fileCount = (git ls-files | Measure-Object).Count
Write-Host "  Files in fork: $fileCount" -ForegroundColor Gray

if ($OriginalPath -and (Test-Path $OriginalPath)) {
    Push-Location $OriginalPath
    $origCount = (git ls-files | Measure-Object).Count
    Pop-Location
    Write-Host "  Files in original: $origCount" -ForegroundColor Gray
    if ($origCount -gt 0 -and $fileCount -lt ($origCount / 2)) {
        Write-Error "Fork appears truncated! Only $fileCount files vs $origCount in original."
        Pop-Location
        exit 1
    }
}

Write-Host "
[REA] Validation completed successfully" -ForegroundColor Green
Pop-Location
