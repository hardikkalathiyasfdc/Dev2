<#
.SYNOPSIS
  Generate PMD reports for the whole Apex codebase: JSON (machine) + HTML (human)
  into reports/ (gitignored). Prints a table summary to the console.
.EXAMPLE
  pwsh -File scripts/pmd/Export-ApexReport.ps1
#>
[CmdletBinding()] param([string]$Ruleset)
$root = (git rev-parse --show-toplevel) | Select-Object -First 1
$stamp = Get-Date -Format 'yyyy-MM-dd-HHmmss'
$reports = Join-Path $root 'reports'
$targets = @('force-app/main/default/classes','force-app/main/default/triggers')
$runner = Join-Path $PSScriptRoot 'Invoke-PmdScan.ps1'

$params = @{ Targets = $targets; Format = 'table' }
if ($Ruleset) { $params.Ruleset = $Ruleset }
& $runner @params   # console table

$p = @{ Targets = $targets; Format = 'json'; OutFile = (Join-Path $reports "pmd-$stamp.json"); Quiet = $true }
if ($Ruleset) { $p.Ruleset = $Ruleset }
& $runner @p

$p.Format = 'html'; $p.OutFile = Join-Path $reports "pmd-$stamp.html"
& $runner @p

Write-Host "Reports written to reports/pmd-$stamp.json and reports/pmd-$stamp.html"
