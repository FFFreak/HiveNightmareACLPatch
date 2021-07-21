<# HiveNightmareACLPatch.ps1
     by Danny Gorman - Coast 
  
	Using Suggestion from CERT, though converted to PoSh
  https://www.kb.cert.org/vuls/id/506989
	
  
  Create the below as a SCHEDULED TASK IN a GPO with script hosted on a Domain Controller or other public network location to domain computers.
	Computer Configuration -> Preferences -> Control Panel Settings -> Scheduled tasks
	  Right click white area: New -> Scheduled task
	** ALL DEFAULTS are fine if not mentioned below.
    Run as:
		NT AUTHORITY\System
	Run whether user is Logged on or not 
		RADIAL SELECTED
	Run as Highest Privileges
		SELECTED
	Hidden
		SELECTED
	Scheduled
		Trigger 1 - One time
			Repeat every 15 min for 1 hour
			Enabled
		Trigger 2 - On Login
		Trigger 3 - On Startup
	Start a program
		Command: 
			C:\Windows\system32\WindowsPowerShell\v1.0\powershell.exe
		Argument: 
		    ** MODIFY BELOW COMMAND FOR YOUR NETLOGON or FILE SERVER!
			NORMAL MODE (workstations):
			-WindowStyle hidden -ExecutionPolicy bypass -NoProfile -file "\\server\share\folder\HiveNightmareACLPatch.ps1"
	Conditions
		Start only if network connection is availible (Bottom most option)
	Settings
		Allow to be ran on demand
		Run task as soon as possible after a schedule is missed.
		Stop if task runs longer than 1 hour
#>

# A function check for a given string from the result of the command, with a boolean to determine if Success if the string is present or not.
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

# Keep track of success states versus tests ran
$intTestsSuccessful = 0
$intTestsRan = 0

# Successful String for icals commands
$strResultSuccessful = "Successfully processed 1 files; Failed processing 0 files"
$blnSuccesIfPresent = $true

# UnSuccessful String for ical validation
$strResultUnSuccessful = "BUILTIN\Users:(I)(RX)"
$blnFailIfPresent = $false

# SAM File
Write-host "Setting SAM file"
Write-host "`tRemoving ACL"
$strCommand = icacls "$env:windir\system32\config\sam" /remove "Users"
if (CheckResult [String]$strCommand $strResultSuccessful $blnSuccesIfPresent) {$intTestsSuccessful++}
$intTestsRan++

Write-host "`tValidating ACL"
$strCommand = icacls "$env:windir\system32\config\sam"
if (CheckResult [String]$strCommand $strResultUnSuccessful $blnFailIfPresent) {$intTestsSuccessful++}
$intTestsRan++

# Security File
Write-host "Setting Security file"
Write-host "`tRemoving ACL"
$strCommand = icacls "$env:windir\system32\config\security" /remove "Users"
if (CheckResult [String]$strCommand $strResultSuccessful $blnSuccesIfPresent) {$intTestsSuccessful++}
$intTestsRan++

Write-host "`tValidating ACL"
$strCommand = icacls "$env:windir\system32\config\security"
if (CheckResult [String]$strCommand $strResultUnSuccessful $blnFailIfPresent) {$intTestsSuccessful++}
$intTestsRan++

# System File
Write-host "Setting System file"
Write-host "`tRemoving ACL"
$strCommand = icacls "$env:windir\system32\config\system" /remove "Users"
if (CheckResult [String]$strCommand $strResultSuccessful $blnSuccesIfPresent) {$intTestsSuccessful++}
$intTestsRan++

Write-host "`tValidating ACL"
$strCommand = icacls "$env:windir\system32\config\system"
if (CheckResult [String]$strCommand $strResultUnSuccessful $blnFailIfPresent) {$intTestsSuccessful++}
$intTestsRan++

# Clear VSS
$strResultSuccessful = "No items found that satisfy the query."
Write-host "Clearing VSS"
vssadmin delete shadows /for=c: /Quiet | out-null

Write-host "Validating cleared VSS"
$strCommand = vssadmin list shadows
if (CheckResult [String]$strCommand $strResultSuccessful $blnSuccesIfPresent) {$intTestsSuccessful++}
$intTestsRan++

# Check if all tests were successful
if ($intTestsRan -eq $intTestsSuccessful) {
  write-host "`r`n`t ** All Commands Successful" -Foreground Green
}

# end.
