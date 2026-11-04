<#
.SYNOPSIS
  Shared runner for Salesforce Code Analyzer (PMD engine) over Apex sources.
.DESCRIPTION
  Used by Scan-ApexAll/Scan-ApexFile/Scan-ApexChanged/Export-ApexReport and by
  .github/hooks/scripts/pre-push-quality.js. Keeps the exact `sf scanner`
  invocation in ONE place so a future CLI/scanner upgrade is a one-file change.
  NOTE: when --pmdconfig is used, scanner v4 ignores --category/--ruleset filters.
.PARAMETER Targets
  File or directory paths (classes/triggers). At least one required.
.PARAMETER Ruleset
  Path to a PMD ruleset XML. Defaults to pmd/apex-ruleset.xml when present.
.PARAMETER Format
  table | csv | html | json | junit | sarif | xml  (table = console default)
.PARAMETER OutFile
  Optional report output path (json/html/csv...). Parent dir is created.
.PARAMETER Quiet
  Suppress table output (for JSON-only programmatic use).
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)][string[]]$Targets,
  [string]$Ruleset,
  [ValidateSet('table','csv','html','json','junit','sarif','xml')][string]$Format = 'table',
  [string]$OutFile,
  [switch]$Quiet
)

$ErrorActionPreference = 'Stop'
$git = 'C:\Program Files\Git\cmd\git.exe'
if (-not (Test-Path $git)) { $git = 'git' }
$root = (& $git rev-parse --show-toplevel 2>$null) | Select-Object -First 1
if (-not $root) { $root = (Get-Location).Path }
$root = $root -replace '/', [IO.Path]::DirectorySeparatorChar

# Default ruleset: committed one wins; fall back to scanner defaults otherwise.
if (-not $Ruleset) {
  $candidate = Join-Path $root 'pmd/apex-ruleset.xml'
  if (Test-Path $candidate) { $Ruleset = $candidate }
}

$args = @('scanner','run','--engine','pmd','--normalize-severity')
foreach ($t in $Targets) { $args += @('--target', $t) }
if ($Ruleset) { $args += @('--pmdconfig', $Ruleset) }
if ($OutFile) {
  $dir = Split-Path $OutFile -Parent
  if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
  $args += @('--format', $Format, '--outfile', $OutFile)
} elseif (-not $Quiet) {
  $args += @('--format', $Format)
}

& sf @args
exit $LASTEXITCODE
