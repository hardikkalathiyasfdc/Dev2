<#
.SYNOPSIS
  PMD-scan a single Apex file (class or trigger).
.PARAMETER File
  Path to the .cls/.trigger file (absolute or repo-relative). Defaults to the
  currently open file when invoked from the VS Code task (${file}).
.EXAMPLE
  pwsh -File scripts/pmd/Scan-ApexFile.ps1 -File force-app/main/default/classes/Foo.cls
#>
[CmdletBinding()]
param([Parameter(Mandatory = $true)][string]$File, [string]$Ruleset)
if (-not [IO.Path]::IsPathRooted($File)) { $File = Join-Path (Get-Location) $File }
if (-not (Test-Path $File)) { Write-Error "File not found: $File"; exit 1 }
$params = @{ Targets = @($File); Format = 'table' }
if ($Ruleset) { $params.Ruleset = $Ruleset }
& (Join-Path $PSScriptRoot 'Invoke-PmdScan.ps1') @params
exit $LASTEXITCODE
