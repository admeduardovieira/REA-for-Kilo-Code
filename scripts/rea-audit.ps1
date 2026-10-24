# REA Audit Script

param(
  [Parameter(Mandatory=$true)]
  [string]$RepoPath
)

$ErrorActionPreference = "Stop"

function Write-Report {
  param([string]$Content)
  $reportDir = "reports"
  if (-not (Test-Path $reportDir)) { New-Item -ItemType Directory -Path $reportDir | Out-Null }
  $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
  $reportPath = Join-Path $reportDir "rea-audit-$timestamp.md"
  Set-Content -Path $reportPath -Value $Content
  Write-Host "Report saved: $reportPath"
}

Write-Host "REA for Kilo Code - Audit Script"
Write-Host "Target: $RepoPath"

if (-not (Test-Path $RepoPath)) {
  Write-Error "Repository path does not exist: $RepoPath"
  exit 1
}

$env:REA_REPO = $RepoPath
$tools = @{}

# Detect tools
$tools["git"] = [bool](Get-Command git -ErrorAction SilentlyContinue)
$tools["rea"] = [bool](Get-Command rea -ErrorAction SilentlyContinue)
$tools["ast-grep"] = [bool](Get-Command ast-grep -ErrorAction SilentlyContinue)
$tools["gitleaks"] = [bool](Get-Command gitleaks -ErrorAction SilentlyContinue)
$tools["osv-scanner"] = [bool](Get-Command osv-scanner -ErrorAction SilentlyContinue)
$tools["actionlint"] = [bool](Get-Command actionlint -ErrorAction SilentlyContinue)

$report = @()
$report += "# REA Audit Report"
$report += "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$report += "Target: $RepoPath"
$report += ""
$report += "## Tools detected"
foreach ($k in $tools.Keys) {
  $report += "- $k : $($tools[$k])"
}
$report += ""
$report += "## Git info"
if ($tools["git"]) {
  Push-Location $RepoPath
  try {
    $branch = git branch --show-current 2>$null
    $commit = git log -1 --oneline 2>$null
    $report += "- Branch: $branch"
    $report += "- Commit: $commit"
  } finally {
    Pop-Location
  }
}
$report += ""
$report += "## Notes"
$report += "- Read-only audit. No files modified."
$report += "- Tools missing are reported as not available."
$report += "- Confirmed findings require evidence and reproduction."

Write-Report -Content ($report -join "`n")
Write-Host "Audit completed (read-only)."
