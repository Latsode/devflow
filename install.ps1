<#
.SYNOPSIS
    Install devflow into Claude Code on Windows.

.DESCRIPTION
    Copies devflow commands, agents, skills, hooks, and templates into
    Claude Code's config directory. Supports user-global or project-local
    install.

.PARAMETER Scope
    'user'    -> $HOME\.claude   (default; available in every project)
    'project' -> .\.claude       (current directory only)

.PARAMETER NoForce
    Skip devflow files that already exist (keep local edits). Default is to
    forcibly overwrite all devflow-owned files. Non-devflow files in the
    target are never read or modified.

.PARAMETER InstallHook
    Wire the SessionStart hint hook into settings.json.

.EXAMPLE
    .\install.ps1
    .\install.ps1 -Scope project
    .\install.ps1 -NoForce
    .\install.ps1 -InstallHook
#>
[CmdletBinding()]
param(
    [ValidateSet('user', 'project')]
    [string]$Scope = 'user',
    [switch]$NoForce,
    [switch]$InstallHook
)

$Force = -not $NoForce

$ErrorActionPreference = 'Stop'
$source = $PSScriptRoot

if ($Scope -eq 'user') {
    $target = Join-Path $HOME '.claude'
} else {
    $target = Join-Path (Get-Location) '.claude'
}

Write-Host "devflow installer" -ForegroundColor Cyan
Write-Host "  source : $source"
Write-Host "  target : $target"
Write-Host "  scope  : $Scope"
Write-Host ""

# Ensure target subdirectories exist
$subdirs = @('commands', 'agents', 'skills', 'devflow', 'devflow\hooks', 'devflow\templates', 'devflow\docs')
foreach ($d in $subdirs) {
    $path = Join-Path $target $d
    if (-not (Test-Path $path)) {
        New-Item -ItemType Directory -Path $path -Force | Out-Null
    }
}

function Copy-Asset {
    param([string]$From, [string]$To, [string]$Label)

    if (-not (Test-Path $From)) { return }

    $items = Get-ChildItem -Path $From -Force
    foreach ($item in $items) {
        $dest = Join-Path $To $item.Name
        if ((Test-Path $dest) -and -not $Force) {
            Write-Host "  skip  ($Label) $($item.Name) - exists" -ForegroundColor Yellow
            continue
        }
        Copy-Item -Path $item.FullName -Destination $dest -Recurse -Force
        Write-Host "  copy  ($Label) $($item.Name)" -ForegroundColor Green
    }
}

Copy-Asset (Join-Path $source 'commands')   (Join-Path $target 'commands')           'cmd  '
Copy-Asset (Join-Path $source 'agents')     (Join-Path $target 'agents')             'agent'
Copy-Asset (Join-Path $source 'skills')     (Join-Path $target 'skills')             'skill'
Copy-Asset (Join-Path $source 'hooks')      (Join-Path $target 'devflow\hooks')      'hook '
Copy-Asset (Join-Path $source 'templates')  (Join-Path $target 'devflow\templates')  'tmpl '
Copy-Asset (Join-Path $source 'docs')       (Join-Path $target 'devflow\docs')       'doc  '

if ($InstallHook) {
    $settingsPath = Join-Path $target 'settings.json'
    Write-Host ""
    Write-Host "Wiring SessionStart hook into $settingsPath" -ForegroundColor Cyan

    if (Test-Path $settingsPath) {
        $backup = "$settingsPath.devflow.bak"
        Copy-Item $settingsPath $backup -Force
        Write-Host "  backed up existing settings.json -> $backup"
        $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
    } else {
        $settings = [pscustomobject]@{}
    }

    if (-not $settings.PSObject.Properties.Match('hooks')) {
        $settings | Add-Member -NotePropertyName hooks -NotePropertyValue ([pscustomobject]@{})
    }
    if (-not $settings.hooks.PSObject.Properties.Match('SessionStart')) {
        $settings.hooks | Add-Member -NotePropertyName SessionStart -NotePropertyValue @()
    }

    # Windows-native command — no bash dependency (session-start.sh needs a
    # working bash, which bare Windows lacks). Absolute path, like statusLine.
    $hookScript = Join-Path $target 'devflow\hooks\session-start.ps1'
    $hookEntry = [pscustomobject]@{
        matcher = 'startup'
        hooks   = @([pscustomobject]@{
            type    = 'command'
            command = "powershell -NoProfile -File `"$hookScript`""
        })
    }

    $settings.hooks.SessionStart = @($hookEntry)
    $settings | ConvertTo-Json -Depth 10 | Set-Content -Path $settingsPath -Encoding UTF8
    Write-Host "  hook installed" -ForegroundColor Green
}

Write-Host ""
Write-Host "Done. Restart Claude Code (or just open a new conversation)." -ForegroundColor Cyan
Write-Host "Try: /devflow help me refactor the order service" -ForegroundColor Cyan
