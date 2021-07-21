<# HiveNightmareACLPatch.ps1 #>

$debug = $false
$DebugPing = "IP ADDRESS here you can monitor for a successful action from powershell test-connection"

function CheckResult
{
  Param
  (
    [Parameter(Mandatory=$true, Position=0)]
    [string] $strCommandOutput,
    [Parameter(Mandatory=$true, Position=1)]
    [string] $strIntendedResult
  )

  if (($strCommandOutput | Select-String $strIntendedResult).length -gt 0) {
    Write-host ".. Success" -Foreground Green
    return $true
  } else {
    Write-host ".. FAIL!" -Foreground Red
    return $false
  }
  return $false
}

$intTestsSuccessful = 0
$intTestsRan = 0

# Successful String for icals commands
$strResultSuccessful = "Successfully processed 1 files; Failed processing 0 files"

# SAM File
$intTestsRan++
Write-host "Setting SAM file"
$strCommand = icacls "$env:windir\system32\config\sam" /remove "Users"
if (CheckResult [String]$strCommand $strResultSuccessful) {$intTestsSuccessful++}

# Security File
$intTestsRan++
Write-host "Setting Security file"
$strCommand = icacls "$env:windir\system32\config\security" /remove "Users"
if (CheckResult [String]$strCommand $strResultSuccessful) {$intTestsSuccessful++}

# System File
$intTestsRan++
Write-host "Setting System file"
$strCommand = icacls "$env:windir\system32\config\security" /remove "Users"
if (CheckResult [String]$strCommand $strResultSuccessful) {$intTestsSuccessful++}

# Clear VSS
$intTestsRan++
$strResultSuccessful = "No items found that satisfy the query."
Write-host "Clearing VSS"
vssadmin delete shadows /for=c: /Quiet | out-null
Write-host "Validating cleared VSS"
$strCommand = vssadmin list shadows
if (CheckResult [String]$strCommand $strResultSuccessful) {$intTestsSuccessful++}

if ($intTestsRan -eq $intTestsSuccessful) {
  write-host "`r`n`t ** All Commands Successful" -Foreground Green
  if ($debug ) {
    Test-Connection $DebugPing -Protocol DCOM -Count 1 -ErrorAction SilentlyContinue
  }
}
