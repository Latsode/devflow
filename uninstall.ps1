<#
.SYNOPSIS
    Remove devflow from Claude Code on Windows.
#>
[CmdletBinding()]
param(
    [ValidateSet('user', 'project')]
    [string]$Scope = 'user'
)

$ErrorActionPreference = 'Stop'

if ($Scope -eq 'user') {
    $target = Join-Path $HOME '.claude'
} else {
    $target = Join-Path (Get-Location) '.claude'
}

Write-Host "devflow uninstaller — target: $target" -ForegroundColor Cyan

$commands = @('devflow.md', 'devflow-plan.md', 'devflow-execute.md',
              'devflow-debug.md', 'devflow-review.md', 'devflow-finish.md')
foreach ($c in $commands) {
    $p = Join-Path $target "commands\$c"
    if (Test-Path $p) { Remove-Item $p -Force; Write-Host "  removed commands\$c" }
}

$agents = @('devflow-planner.md', 'devflow-implementer.md', 'devflow-debugger.md',
            'devflow-reviewer.md', 'devflow-tester.md')
foreach ($a in $agents) {
    $p = Join-Path $target "agents\$a"
    if (Test-Path $p) { Remove-Item $p -Force; Write-Host "  removed agents\$a" }
}

$skills = Get-ChildItem (Join-Path $target 'skills') -Filter 'devflow-*' -Directory -ErrorAction SilentlyContinue
foreach ($s in $skills) { Remove-Item $s.FullName -Recurse -Force; Write-Host "  removed skills\$($s.Name)" }

$dfRoot = Join-Path $target 'devflow'
if (Test-Path $dfRoot) { Remove-Item $dfRoot -Recurse -Force; Write-Host "  removed devflow/" }

Write-Host "Done." -ForegroundColor Cyan
Write-Host "Note: SessionStart hook (if installed) was NOT auto-removed — edit settings.json manually."
