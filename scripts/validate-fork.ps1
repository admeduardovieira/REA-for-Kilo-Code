# REA - fail-closed fork validation (PowerShell 5.1+)
# Invoke before committing AND before pushing. Does not change the repository.
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$ForkPath,
    [string]$OriginalPath,
    [string[]]$ApprovedPaths,
    [string]$BaseRef,
    [string]$PushRemote = 'origin',
    [string]$ExpectedOwner = 'admeduardovieira',
    [int]$MaximumChangedFiles = 100,
    [int]$MaximumDeletedLines = 1000
)

# Initialize ApprovedPaths from environment if not provided (P1/P2 fix)
if (-not $ApprovedPaths) {
    $envPaths = $env:APPROVED_PATHS
    if (-not $envPaths) { throw 'ApprovedPaths not provided and APPROVED_PATHS env var not set.' }
    $ApprovedPaths = $envPaths -split ','
}

# Initialize BaseRef from environment if not provided (P5 fix)
if (-not $BaseRef -and $env:BASE_REF) {
    $BaseRef = $env:BASE_REF
}

$ErrorActionPreference = 'Stop'
if ($ApprovedPaths.Count -eq 1 -and $ApprovedPaths[0].Contains(',')) {
    $ApprovedPaths = @($ApprovedPaths[0] -split ',')
}
$locationPushed = $false
try {
    if (-not (Test-Path -LiteralPath $ForkPath -PathType Container)) {
        throw "Fork directory not found: $ForkPath"
    }
    Push-Location -LiteralPath $ForkPath
    $locationPushed = $true

    function GitLines([string[]]$GitArgs) {
        $output = @(& git @GitArgs 2>&1)
        if ($LASTEXITCODE -ne 0) { throw "git $($GitArgs -join ' ') failed: $($output -join ' ')" }
        return @($output | ForEach-Object { [string]$_ })
    }

    $inside = (GitLines @('rev-parse', '--is-inside-work-tree')) -join ''
    if ($inside -ne 'true') { throw 'Not inside a Git working tree.' }
    $root = (GitLines @('rev-parse', '--show-toplevel')) -join ''
$here = (Get-Location).Path

# O Git pode retornar caminhos Unix/MSYS no Windows.
# Confirma o diretório real usando o proprio Git.
$gitPrefix = (GitLines @('rev-parse', '--show-prefix')) -join ''

if ($gitPrefix -ne '') {
    throw 'ForkPath must be the repository root to prevent checking the wrong scope.'
}

if (-not (Test-Path -LiteralPath (Join-Path $here '.git'))) {
    throw 'ForkPath does not contain Git repository metadata.'
}

    # Check *push URL*, not only fetch URL, to catch pushurl overrides.
    $remoteUrl = (GitLines @('remote', 'get-url', '--push', $PushRemote)) -join ''
    $ownerRegex = [regex]::Escape($ExpectedOwner)
    if ($remoteUrl -notmatch "^(https://github\.com/|ssh://git@github\.com/|git@github\.com:)$ownerRegex/[^/]+?(\.git)?/?$") {
        throw "Unexpected push destination '$remoteUrl' (owner '$ExpectedOwner' required)."
    }
    Write-Host "[REA] Push remote verified: $remoteUrl" -ForegroundColor Cyan

    # A trusted baseline is mandatory for verifying already committed changes.
    if (-not $BaseRef) {
        $upstream = @(& git rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>$null)
        if ($LASTEXITCODE -ne 0 -or -not $upstream) {
            throw 'No upstream found. Specify -BaseRef explicitly (for example origin/master).'
        }
        $BaseRef = ([string]$upstream[0]).Trim()
    }
    $null = GitLines @('rev-parse', '--verify', $BaseRef)

$objectType = (GitLines @('cat-file', '-t', $BaseRef)) -join ''
if ($objectType -ne 'commit') {
    throw "BaseRef '$BaseRef' is not a commit."
}
    $mergeBase = (GitLines @('merge-base', $BaseRef, 'HEAD')) -join ''
    if (-not $mergeBase) { throw "No common ancestor for BaseRef '$BaseRef'." }
    Write-Host "[REA] Comparing HEAD and working tree against $BaseRef (merge-base $mergeBase)"

    # Includes outgoing commits, staged modifications, unstaged modifications, and untracked files.
    # --no-renames reports both sides of a rename so scope restrictions cannot be bypassed.
    $committed = @(GitLines @('diff', '--no-renames', '--name-only', $mergeBase, 'HEAD'))
    $staged = @(GitLines @('diff', '--cached', '--no-renames', '--name-only'))
    $unstaged = @(GitLines @('diff', '--no-renames', '--name-only'))
    $untracked = @(GitLines @('ls-files', '--others', '--exclude-standard'))
    $changed = @($committed + $staged + $unstaged + $untracked | Where-Object { $_ -ne '' } | Sort-Object -Unique)
    Write-Host "[REA] Changed files ($($changed.Count)):" -ForegroundColor Yellow
    $changed | ForEach-Object { Write-Host "  $_" }
    if ($changed.Count -gt $MaximumChangedFiles) {
        throw "Too many changed files: $($changed.Count) > $MaximumChangedFiles."
    }

    # Paths are literal Git-style paths or explicit glob patterns, relative to repo root.
    # Patterns such as * or ** are deliberately refused as overly permissive.
    foreach ($pattern in $ApprovedPaths) {
        if ([string]::IsNullOrWhiteSpace($pattern) -or $pattern -eq '*' -or $pattern -eq '**' -or $pattern.StartsWith('/') -or $pattern.Contains('..') -or $pattern.Contains('\')) {
            throw "Invalid/overly broad approved path: '$pattern'"
        }
    }
    $violations = @($changed | Where-Object {
        $file = $_
        -not (@($ApprovedPaths | Where-Object { $file -clike $_ }).Count -gt 0)
    })
    if ($violations.Count -gt 0) { throw "Changes outside authorized scope: $($violations -join ', ')" }

    # Count removed lines over outgoing committed changes and local staged/unstaged changes.
    $numstats = @(
        GitLines @('diff', '--no-renames', '--numstat', $mergeBase, 'HEAD')
        GitLines @('diff', '--cached', '--no-renames', '--numstat')
        GitLines @('diff', '--no-renames', '--numstat')
    )
    $deletedLines = 0
    foreach ($line in $numstats) {
        if ($line -match '^\d+\s+(\d+)\s+') { $deletedLines += [int]$Matches[1] }
        elseif ($line -match '^-\s+-\s+') { throw 'Binary modification requires manual review.' }
    }
    if ($deletedLines -gt $MaximumDeletedLines) {
        throw "Excessive deleted lines: $deletedLines > $MaximumDeletedLines."
    }

    # Validate the current content of all changed text files, including staged and untracked.
    foreach ($file in $changed) {
        if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { continue } # deletion
        $ext = [IO.Path]::GetExtension($file).ToLowerInvariant()
        switch ($ext) {
            '.js' {
                if (-not (Get-Command node -ErrorAction SilentlyContinue)) { throw 'Node.js unavailable; cannot check JS syntax.' }
                $nodeOutput = @(& node --check -- $file 2>&1)
                if ($LASTEXITCODE -ne 0) { throw "JS syntax error in '$file': $($nodeOutput -join ' ')" }
            }
            '.json' {
                $raw = [IO.File]::ReadAllText((Resolve-Path -LiteralPath $file).Path)
                $null = ConvertFrom-Json -InputObject $raw -ErrorAction Stop
            }
            '.xml' {
                $settings = New-Object System.Xml.XmlReaderSettings
                $settings.DtdProcessing = [System.Xml.DtdProcessing]::Prohibit
                $settings.XmlResolver = $null
                $reader = [System.Xml.XmlReader]::Create((Resolve-Path -LiteralPath $file).Path, $settings)
                $doc = New-Object System.Xml.XmlDocument
                $doc.Load($reader)
                $reader.Close()
            }
        }
    }

    # Optional tracked-file integrity check against a known original checkout.
    if ($OriginalPath) {
        if (-not (Test-Path -LiteralPath $OriginalPath -PathType Container)) { throw "OriginalPath missing: $OriginalPath" }
        $originalRoot = (& git -C $OriginalPath rev-parse --show-toplevel 2>&1)
        if ($LASTEXITCODE -ne 0) { throw 'OriginalPath is not a Git checkout.' }
        $originalFiles = @(& git -C $OriginalPath ls-files)
        if ($LASTEXITCODE -ne 0) { throw 'Could not list original tracked files.' }
        $forkFiles = @(GitLines @('ls-files'))
        if ($originalFiles.Count -gt 0 -and $forkFiles.Count -lt [math]::Ceiling($originalFiles.Count * 0.95)) {
            throw "Possible truncated fork: $($forkFiles.Count) tracked files vs $($originalFiles.Count) original."
        }
    }
    Write-Host '[REA] PASS: authorized scope, remote, baseline, change volume and syntax checks.' -ForegroundColor Green
    exit 0
}
catch {
    Write-Host "[REA] BLOCKED: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
finally {
    if ($locationPushed) { Pop-Location }
}
