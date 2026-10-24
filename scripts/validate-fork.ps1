# REA for Kilo Code - Fork Validation Script
param(
    [Parameter(Mandatory=\True)]
    [string]\,
    [string]\ = \
)

Write-Host \"[REA] Validating fork: \\" -ForegroundColor Cyan

if (-not (Test-Path \)) {
    Write-Error \"Fork path not found: \\"
    exit 1
}

Push-Location \

# Check git repo
if (-not (Test-Path ".git")) {
    Write-Error \"Not a git repository\"
    Pop-Location
    exit 1
}

# Check remote
Write-Host \"[REA] Checking remotes...\" -ForegroundColor Yellow
git remote -v

# Check diff stat
Write-Host \"
[REA] Diff stat:\" -ForegroundColor Yellow
\ = git diff --stat
\ | Out-Host
\ = (\ | Select-String -Pattern \"files? changed|deletions?\").ToString()
if (\ -match \"[0-9]+,000\" -or \.Count -gt 50) {
    Write-Warning \"Large diff detected. Please review carefully.\"
}

# Check modified files
Write-Host \"
[REA] Modified files:\" -ForegroundColor Yellow
git diff --name-only | Out-Host

# Check JS syntax
Write-Host \"
[REA] Checking JS syntax...\" -ForegroundColor Yellow
\ = git diff --name-only | Where-Object { \ -match \"\.js$\" }
foreach (\ in \) {
    if (Test-Path \) {
        Write-Host \"  Checking \\" -ForegroundColor Gray
        node --check \
        if (\ -ne 0) {
            Write-Error \"Syntax error in \\"
            Pop-Location
            exit 1
        }
    }
}

# Check file count
Write-Host \"
[REA] File count:\" -ForegroundColor Yellow
\ = (git ls-files | Measure-Object).Count
Write-Host \"  Files in fork: \\" -ForegroundColor Gray

if (\ -and (Test-Path \)) {
    Push-Location \
    \ = (git ls-files | Measure-Object).Count
    Pop-Location
    Write-Host \"  Files in original: \\" -ForegroundColor Gray
    if (\ -gt 0 -and \ -lt (\ / 2)) {
        Write-Error \"Fork appears truncated! Only \ files vs \ in original.\"
        Pop-Location
        exit 1
    }
}

Write-Host \"
[REA] Validation completed successfully\" -ForegroundColor Green
Pop-Location
