[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ComputerName,
    [switch]$EnableAccount,
    [switch]$DisableAccount,
    [string]$MoveToOU,
    [string]$Description,
    [switch]$DryRun,
    [switch]$Yes,
    [string]$OutputPath = (Join-Path $env:ProgramData 'ADComputerAccountRepair')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$script:Failures = 0
$script:VerificationFailures = 0
$script:Actions = 0

if ($env:OS -ne 'Windows_NT') { Write-Error 'This tool requires Windows with RSAT.'; exit 3 }
if (-not ($EnableAccount -or $DisableAccount -or $MoveToOU -or $PSBoundParameters.ContainsKey('Description'))) { Write-Error 'Choose at least one repair action.'; exit 2 }
if ($EnableAccount -and $DisableAccount) { Write-Error 'Choose either -EnableAccount or -DisableAccount.'; exit 2 }
try { Import-Module ActiveDirectory -ErrorAction Stop } catch { Write-Error 'The ActiveDirectory PowerShell module is required.'; exit 3 }

function Get-RepairState {
    Get-ADComputer -Identity $ComputerName -Properties Enabled,OperatingSystem,LastLogonDate,PasswordLastSet,Description,DistinguishedName,PrimaryGroupID |
        Select-Object Name,Enabled,OperatingSystem,LastLogonDate,PasswordLastSet,Description,DistinguishedName,PrimaryGroupID,ObjectGUID,SID
}

try { $initialAccount = Get-RepairState } catch { Write-Error "AD computer '$ComputerName' was not found or could not be read."; exit 2 }
if ($initialAccount.PrimaryGroupID -eq 516 -and ($DisableAccount -or $MoveToOU)) { Write-Error 'Refusing to disable or move a domain controller account.'; exit 2 }
if ($MoveToOU) {
    try { Get-ADOrganizationalUnit -Identity $MoveToOU -ErrorAction Stop | Out-Null } catch { Write-Error "Target OU '$MoveToOU' was not found."; exit 2 }
}

$runPath = Join-Path $OutputPath (Get-Date -Format 'yyyyMMdd_HHmmss')
$backupPath = Join-Path $runPath 'backup'
New-Item -ItemType Directory -Path $backupPath -Force | Out-Null
$logPath = Join-Path $runPath 'repair.log'
$beforePath = Join-Path $runPath 'before.json'
$afterPath = Join-Path $runPath 'after.json'

function Write-Log([string]$Message) {
    "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $Message" | Tee-Object -FilePath $logPath -Append
}
function Invoke-RepairAction([string]$DescriptionText,[scriptblock]$Script) {
    $script:Actions++
    Write-Log "ACTION: $DescriptionText"
    if ($DryRun) { Write-Log "DRY-RUN: $DescriptionText"; return }
    try {
        & $Script
        Write-Log "SUCCESS: $DescriptionText"
    } catch {
        $script:Failures++
        Write-Log "FAILED: $DescriptionText - $($_.Exception.Message)"
    }
}

$initialAccount | ConvertTo-Json -Depth 6 | Set-Content $beforePath -Encoding UTF8
$initialAccount | Export-Clixml (Join-Path $backupPath 'computer-account-before.clixml')
Write-Log "Saved pre-change directory object state to $backupPath"

if (-not $DryRun -and -not $Yes) {
    if ((Read-Host "Apply selected changes to AD computer '$ComputerName'? Type YES") -cne 'YES') { Write-Log 'Repair cancelled.'; exit 10 }
}

if ($EnableAccount) { Invoke-RepairAction "Enabling AD computer $ComputerName" { Enable-ADAccount -Identity $ComputerName } }
if ($DisableAccount) { Invoke-RepairAction "Disabling AD computer $ComputerName" { Disable-ADAccount -Identity $ComputerName } }
if ($PSBoundParameters.ContainsKey('Description')) { Invoke-RepairAction "Updating description on $ComputerName" { Set-ADComputer -Identity $ComputerName -Description $Description } }
if ($MoveToOU) { Invoke-RepairAction "Moving $ComputerName to $MoveToOU" { Move-ADObject -Identity $initialAccount.DistinguishedName -TargetPath $MoveToOU } }

if (-not $DryRun) { Start-Sleep -Seconds 2 }
try { $finalAccount = Get-RepairState } catch { $script:VerificationFailures++; Write-Log 'VERIFY FAILED: the computer account could not be read after repair.'; $finalAccount = $null }
if ($finalAccount) { $finalAccount | ConvertTo-Json -Depth 6 | Set-Content $afterPath -Encoding UTF8 }

if (-not $DryRun -and $finalAccount) {
    if ($EnableAccount -and -not $finalAccount.Enabled) { $script:VerificationFailures++; Write-Log 'VERIFY FAILED: account is not enabled.' }
    if ($DisableAccount -and $finalAccount.Enabled) { $script:VerificationFailures++; Write-Log 'VERIFY FAILED: account is not disabled.' }
    if ($PSBoundParameters.ContainsKey('Description') -and $finalAccount.Description -cne $Description) { $script:VerificationFailures++; Write-Log 'VERIFY FAILED: description does not match.' }
    if ($MoveToOU -and $finalAccount.DistinguishedName -inotlike "*,$MoveToOU") { $script:VerificationFailures++; Write-Log 'VERIFY FAILED: account is not in the requested OU.' }
}

if ($script:Failures -gt 0) { exit 20 }
if ($script:VerificationFailures -gt 0) { exit 30 }
Write-Log "Workflow completed. Actions: $script:Actions; DryRun: $DryRun"
exit 0
