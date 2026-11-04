<#
.SYNOPSIS
  PMD-scan only Git-changed Apex files (staged + unstaged + untracked, and
  unpushed commits when on a branch with origin/main). Handles spaces in
  filenames and renames/deletes via NUL-delimited git output.
.EXAMPLE
  pwsh -File scripts/pmd/Scan-ApexChanged.ps1
#>
[CmdletBinding()] param([string]$Ruleset)
$ErrorActionPreference = 'Stop'
$git = 'C:\Program Files\Git\cmd\git.exe'
if (-not (Test-Path $git)) { $git = 'git' }
$root = (& $git rev-parse --show-toplevel) | Select-Object -First 1
if (-not $root) { Write-Error 'Not inside a git repository.'; exit 1 }
$root = $root -replace '/', [IO.Path]::DirectorySeparatorChar

$changed = @()
# NUL-delimited so filenames with spaces survive; renames list the new path.
foreach ($argSet in @(
  @('diff', '--name-only', '-z', 'HEAD', '--'),
  @('diff', '--name-only', '-z', 'origin/main...HEAD', '--'),
  @('ls-files', '--others', '--exclude-standard', '-z')
)) {
  $out = & $git @argSet 2>$null
  if ($out) { $changed += ($out -join "`0") -split "`0" }
}
$changed = $changed | Where-Object { $_ } | Sort-Object -Unique

$apex = $changed |
  Where-Object { $_ -match '\.(cls|trigger)$' -and $_ -match 'force-app' } |
  ForEach-Object { Join-Path $root $_ } |
  Where-Object { Test-Path $_ }

if (-not $apex) { Write-Host 'No changed Apex files to scan.'; exit 0 }
Write-Host ("Scanning {0} changed Apex file(s)..." -f $apex.Count)
$params = @{ Targets = $apex; Format = 'table' }
if ($Ruleset) { $params.Ruleset = $Ruleset }
& (Join-Path $PSScriptRoot 'Invoke-PmdScan.ps1') @params
exit $LASTEXITCODE
