[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$UpstreamUrl = 'https://github.com/WildKernels/OnePlus_KernelSU_SUSFS.git'

function Invoke-Git {
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]] $GitArgs
    )

    & git @GitArgs
    if ($LASTEXITCODE -ne 0) {
        throw "git $($GitArgs -join ' ') failed with exit code $LASTEXITCODE"
    }
}

Set-Location -LiteralPath (Split-Path -Parent $PSScriptRoot)

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw 'Git is not installed or is missing from PATH.'
}

if (-not (Test-Path -LiteralPath '.git')) {
    throw 'Run this script from a clone of OnePlus_KernelSU_SUSFS.'
}

$dirty = @(& git status --porcelain)
if ($LASTEXITCODE -ne 0) {
    throw 'Failed to inspect the working tree.'
}
if ($dirty.Count -gt 0) {
    Write-Host 'The working tree contains uncommitted changes:' -ForegroundColor Yellow
    $dirty | ForEach-Object { Write-Host $_ }
    throw 'Commit or stash these changes before syncing.'
}

$remotes = @(& git remote)
if ($remotes -notcontains 'origin') {
    throw 'The origin remote is missing. Set origin to your GitHub fork first.'
}

$originUrl = ((& git remote get-url origin) -join '').Trim()
if ($LASTEXITCODE -ne 0) {
    throw 'Failed to read the origin URL.'
}
if ($originUrl -match 'github\.com[/:]WildKernels/OnePlus_KernelSU_SUSFS(?:\.git)?$') {
    throw 'origin points to WildKernels. Set origin to your personal fork before uploading.'
}

if ($remotes -contains 'upstream') {
    Invoke-Git remote set-url upstream $UpstreamUrl
} else {
    Invoke-Git remote add upstream $UpstreamUrl
}

Write-Host "Fork:    $originUrl" -ForegroundColor Cyan
Write-Host "Upstream: $UpstreamUrl" -ForegroundColor Cyan

Invoke-Git checkout main
Invoke-Git fetch origin main
Invoke-Git merge --ff-only origin/main
Invoke-Git fetch --no-tags upstream main

& git merge-base --is-ancestor upstream/main HEAD
$alreadyCurrent = $LASTEXITCODE -eq 0

if ($alreadyCurrent) {
    Write-Host 'The local branch already contains the latest upstream changes.' -ForegroundColor Green
} else {
    Write-Host 'Merging upstream/main into main...' -ForegroundColor Cyan
    & git merge --no-edit upstream/main
    if ($LASTEXITCODE -ne 0) {
        Write-Host ''
        Write-Host 'Merge conflicts detected. The merge was left open for manual resolution.' -ForegroundColor Yellow
        Write-Host 'After resolving files, run:' -ForegroundColor Yellow
        Write-Host '  git add <resolved-files>'
        Write-Host '  git commit'
        Write-Host '  git push origin main'
        Write-Host ''
        Write-Host 'To cancel instead, run: git merge --abort'
        exit 1
    }
}

Invoke-Git push origin main

$head = ((& git rev-parse --short=8 HEAD) -join '').Trim()
Write-Host ''
Write-Host "Done. origin/main is now at $head." -ForegroundColor Green
