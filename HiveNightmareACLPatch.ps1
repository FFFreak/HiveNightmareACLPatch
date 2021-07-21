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
    [string] $strIntendedResult,
    [Parameter(Mandatory=$true, Position=2)]
    [Switch] $blnPresent
  )
  
  # Convert for Select-String 
  $strIntendedResult = [regex]::Escape($strIntendedResult)

  if (
      (($strCommandOutput | Select-String "$strIntendedResult").length -gt 0 -and $blnPresent) -or
      (($strCommandOutput | Select-String "$strIntendedResult").length -eq 0 -and -not $blnPresent)
     ) {
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
$blnSuccesIfPresent = $true

$strResultUnSuccessful = "BUILTIN\Users:(I)(RX)"
$blnFailIfPresent = $false

# SAM File
Write-host "Setting SAM file"
Write-host "`tRemoving ACL"
$strCommand = icacls "$env:windir\system32\config\sam" /remove "Users"
$intTestsRan++
if (CheckResult [String]$strCommand $strResultSuccessful $blnSuccesIfPresent) {$intTestsSuccessful++}
$intTestsRan++
Write-host "`tValidating ACL"
$strCommand = icacls "$env:windir\system32\config\sam"
if (CheckResult [String]$strCommand $strResultUnSuccessful $blnFailIfPresent) {$intTestsSuccessful++}

# Security File
Write-host "Setting Security file"
Write-host "`tRemoving ACL"
$strCommand = icacls "$env:windir\system32\config\security" /remove "Users"
$intTestsRan++
if (CheckResult [String]$strCommand $strResultSuccessful $blnSuccesIfPresent) {$intTestsSuccessful++}
$intTestsRan++
Write-host "`tValidating ACL"
$strCommand = icacls "$env:windir\system32\config\security"
if (CheckResult [String]$strCommand $strResultUnSuccessful $blnFailIfPresent) {$intTestsSuccessful++}

# System File
Write-host "Setting System file"
Write-host "`tRemoving ACL"
$strCommand = icacls "$env:windir\system32\config\system" /remove "Users"
$intTestsRan++
if (CheckResult [String]$strCommand $strResultSuccessful $blnSuccesIfPresent) {$intTestsSuccessful++}
$intTestsRan++
Write-host "`tValidating ACL"
$strCommand = icacls "$env:windir\system32\config\system"
if (CheckResult [String]$strCommand $strResultUnSuccessful $blnFailIfPresent) {$intTestsSuccessful++}

# Clear VSS
$strResultSuccessful = "No items found that satisfy the query."
Write-host "Clearing VSS"
vssadmin delete shadows /for=c: /Quiet | out-null

Write-host "Validating cleared VSS"
$intTestsRan++
$strCommand = vssadmin list shadows
if (CheckResult [String]$strCommand $strResultSuccessful $blnSuccesIfPresent) {$intTestsSuccessful++}

if ($intTestsRan -eq $intTestsSuccessful) {
  write-host "`r`n`t ** All Commands Successful" -Foreground Green
  if ($debug ) {
    Test-Connection $DebugPing -Protocol DCOM -Count 1 -ErrorAction SilentlyContinue
  }
}
