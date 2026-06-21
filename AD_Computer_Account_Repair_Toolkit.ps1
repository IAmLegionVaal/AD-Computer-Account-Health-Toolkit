[CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact='High')]
param(
 [Parameter(Mandatory)][string]$ComputerName,
 [switch]$EnableAccount,
 [switch]$DisableAccount,
 [string]$MoveToOU,
 [string]$Description,
 [switch]$DryRun,
 [switch]$Yes,
 [string]$OutputPath=(Join-Path $env:ProgramData 'ADComputerAccountRepair')
)
$ErrorActionPreference='Stop';Import-Module ActiveDirectory -ErrorAction Stop;$script:Failures=0;$script:Actions=0
$run=Join-Path $OutputPath (Get-Date -Format yyyyMMdd_HHmmss);New-Item -ItemType Directory $run -Force|Out-Null
$log=Join-Path $run 'repair.log';$before=Join-Path $run 'before.json';$after=Join-Path $run 'after.json'
function Log($m){"$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $m"|Tee-Object -FilePath $log -Append}
function State{Get-ADComputer -Identity $ComputerName -Properties Enabled,OperatingSystem,LastLogonDate,PasswordLastSet,Description,DistinguishedName,PrimaryGroupID|Select-Object Name,Enabled,OperatingSystem,LastLogonDate,PasswordLastSet,Description,DistinguishedName,PrimaryGroupID}
function Act($d,[scriptblock]$a){$script:Actions++;Log $d;if($DryRun){Log "DRY-RUN: $d";return};try{&$a;Log "SUCCESS: $d"}catch{$script:Failures++;Log "FAILED: $d - $($_.Exception.Message)"}}
$account=State;$account|ConvertTo-Json -Depth 4|Set-Content $before -Encoding UTF8
if(-not($EnableAccount -or $DisableAccount -or $MoveToOU -or $PSBoundParameters.ContainsKey('Description'))){Write-Error 'Choose at least one repair action.';exit 2}
if($EnableAccount -and $DisableAccount){Write-Error 'Choose either enable or disable.';exit 2}
if($account.PrimaryGroupID -eq 516 -and ($DisableAccount -or $MoveToOU)){Write-Error 'Refusing to disable or move a domain controller account.';exit 2}
if($MoveToOU){Get-ADOrganizationalUnit -Identity $MoveToOU -ErrorAction Stop|Out-Null}
if(-not $Yes -and -not $DryRun){if((Read-Host "Apply selected changes to AD computer '$ComputerName'? Type YES") -ne 'YES'){Log 'Cancelled.';exit 10}}
if($EnableAccount){Act "Enabling AD computer $ComputerName" {Enable-ADAccount -Identity $ComputerName}}
if($DisableAccount){Act "Disabling AD computer $ComputerName" {Disable-ADAccount -Identity $ComputerName}}
if($PSBoundParameters.ContainsKey('Description')){Act "Updating description on $ComputerName" {Set-ADComputer -Identity $ComputerName -Description $Description}}
if($MoveToOU){Act "Moving $ComputerName to $MoveToOU" {Move-ADObject -Identity $account.DistinguishedName -TargetPath $MoveToOU}}
Start-Sleep 1;State|ConvertTo-Json -Depth 4|Set-Content $after -Encoding UTF8
if($script:Failures){exit 20};Log "Repair completed. Actions: $script:Actions";exit 0
