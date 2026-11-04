<#
.SYNOPSIS
  Shared runner for Salesforce Code Analyzer (PMD engine) over Apex sources.
.DESCRIPTION
  Used by Scan-ApexAll/Scan-ApexFile/Scan-ApexChanged/Export-ApexReport and by
  .github/hooks/scripts/pre-push-quality.js. Keeps the exact CLI invocation in
  ONE place so a future CLI/Analyzer upgrade is a one-file change.

  Prefers Code Analyzer v5 (`sf code-analyzer run`) when the plugin is on the
  resolved `sf` binary; falls back to v4 (`sf scanner run`) otherwise. This is
  what lets tooling/skills-base work in environments that have not upgraded yet.

  v5 notes (no --pmdconfig/--engine/--normalize-severity flags):
    - engine filter  -> --rule-selector pmd
    - custom rules   -> code-analyzer.yml at the repo ROOT (auto-loaded)
    - severity       -> single `severity` field, 1=Critical..5=Info
    - config file    -> pass -ConfigFile or place code-analyzer.yml at root
.PARAMETER Targets
  File or directory paths (classes/triggers). At least one required.
.PARAMETER ConfigFile
  v5: path to code-analyzer.yml. Defaults to <root>/code-analyzer.yml when present.
.PARAMETER Ruleset
  v4-only: path to a PMD ruleset XML (pmd/apex-ruleset.xml when present).
.PARAMETER Format
  table | csv | html | json | junit | sarif | xml  (table = console default)
.PARAMETER OutFile
  Optional report output path. Parent dir is created. (v4 maps table->csv on file.)
.PARAMETER Quiet
  Suppress console view (for JSON-only programmatic use).
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)][string[]]$Targets,
  [string]$ConfigFile,
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

# Resolve the sf binary. Prefer an npm-global install (PATH often shadows it with
# a stale C:\Program Files\sf). Probe candidates for code-analyzer v5.
function Resolve-Sf {
  $npmGlobal = Join-Path $env:APPDATA 'npm\sf.cmd'
  $cands = @($npmGlobal, 'sf', 'C:\Program Files\sf\bin\sf.cmd')
  $v4 = $null
  foreach ($c in $cands) {
    try {
      $plugins = & $c plugins 2>$null | Out-String
      if ($plugins -match 'code-analyzer\s+\d') { return @{ bin = $c; v5 = $true } }
      if (-not $v4 -and $plugins -match 'sfdx-scanner') { $v4 = @{ bin = $c; v5 = $false } }
    } catch { }
  }
  return ($v4 ? $v4 : @{ bin = 'sf'; v5 = $false })
}
$sf = Resolve-Sf

if ($OutFile) {
  $dir = Split-Path $OutFile -Parent
  if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
}

if ($sf.v5) {
  if (-not $ConfigFile) {
    $c = Join-Path $root 'code-analyzer.yml'
    if (Test-Path $c) { $ConfigFile = $c }
  }
  # v5.16 requires config_root as an absolute path. If the config file does not
  # set it, generate a temp overlay that prepends it (committed yml stays portable).
  if ($ConfigFile) {
    $raw = Get-Content $ConfigFile -Raw
    if ($raw -notmatch '(?m)^\s*config_root\s*:') {
      $overlay = Join-Path $env:TEMP ("code-analyzer-overlay-" + [Guid]::NewGuid().ToString('N') + '.yml')
      Set-Content -Path $overlay -Value ("config_root: '" + $root + "'`n" + $raw)
      $ConfigFile = $overlay
    }
  }
  $args = @('code-analyzer','run','--rule-selector','pmd')
  $args += @('--workspace', $root)   # workspace must contain the targets
  foreach ($t in $Targets) { $args += @('--target', $t) }
  if ($ConfigFile) { $args += @('--config-file', $ConfigFile) }
  if ($OutFile) { $args += @('--output-file', $OutFile) }
  if (-not $Quiet) { $args += @('--view', ($Format -eq 'table' ? 'table' : 'detail')) }
} else {
  # v4 fallback (sf scanner). Honor a committed PMD ruleset if present.
  if (-not $Ruleset) {
    $candidate = Join-Path $root 'pmd/apex-ruleset.xml'
    if (Test-Path $candidate) { $Ruleset = $candidate }
  }
  $args = @('scanner','run','--engine','pmd','--normalize-severity')
  foreach ($t in $Targets) { $args += @('--target', $t) }
  if ($Ruleset) { $args += @('--pmdconfig', $Ruleset) }
  if ($OutFile) {
    # v4 cannot write 'table' to a file; use csv for file output in that case.
    $fileFormat = ($Format -eq 'table') ? 'csv' : $Format
    $args += @('--format', $fileFormat, '--outfile', $OutFile)
  } elseif (-not $Quiet) {
    $args += @('--format', $Format)
  }
}

Write-Verbose ("Using " + ($sf.v5 ? 'Code Analyzer v5' : 'scanner v4') + " via " + $sf.bin)
& $sf.bin @args
exit $LASTEXITCODE
