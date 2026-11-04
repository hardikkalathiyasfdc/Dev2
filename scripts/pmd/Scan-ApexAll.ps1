<#
.SYNOPSIS
  PMD-scan every Apex class and trigger in the project.
.EXAMPLE
  pwsh -File scripts/pmd/Scan-ApexAll.ps1
#>
[CmdletBinding()] param([string]$Ruleset)
$params = @{ Targets = @('force-app/main/default/classes','force-app/main/default/triggers') ; Format = 'table' }
if ($Ruleset) { $params.Ruleset = $Ruleset }
& (Join-Path $PSScriptRoot 'Invoke-PmdScan.ps1') @params
exit $LASTEXITCODE
