#requires -Version 5.1
[CmdletBinding()]
param([int]$StaleDays=90,[string]$OutputPath)
$stamp=Get-Date -Format 'yyyyMMdd_HHmmss'
if([string]::IsNullOrWhiteSpace($OutputPath)){$OutputPath=Join-Path ([Environment]::GetFolderPath('Desktop')) 'AD_Computer_Health_Reports'}
New-Item -ItemType Directory -Path $OutputPath -Force|Out-Null
try{Import-Module ActiveDirectory -ErrorAction Stop}catch{Write-Error 'ActiveDirectory module not found.';return}
$cutoff=(Get-Date).AddDays(-1*$StaleDays)
$computers=Get-ADComputer -Filter * -Properties Enabled,OperatingSystem,OperatingSystemVersion,LastLogonDate,PasswordLastSet,DistinguishedName|ForEach-Object{[PSCustomObject]@{Name=$_.Name;Enabled=$_.Enabled;OperatingSystem=$_.OperatingSystem;OSVersion=$_.OperatingSystemVersion;LastLogonDate=$_.LastLogonDate;PasswordLastSet=$_.PasswordLastSet;Stale=$(if(-not $_.LastLogonDate){$true}else{$_.LastLogonDate -lt $cutoff});DistinguishedName=$_.DistinguishedName}}
$summary=[PSCustomObject]@{ComputerAccounts=@($computers).Count;Enabled=@($computers|Where-Object Enabled).Count;Stale=@($computers|Where-Object Stale).Count;ThresholdDays=$StaleDays;Generated=Get-Date}
$computers|Export-Csv (Join-Path $OutputPath "ad_computers_$stamp.csv") -NoTypeInformation -Encoding UTF8
@{Summary=$summary;Computers=$computers}|ConvertTo-Json -Depth 6|Set-Content (Join-Path $OutputPath "ad_computer_health_$stamp.json") -Encoding UTF8
$html="<h1>AD Computer Account Health</h1><p>Generated $(Get-Date)</p><h2>Summary</h2>$(@($summary)|ConvertTo-Html -Fragment)<h2>Computers</h2>$($computers|ConvertTo-Html -Fragment)"
$html|ConvertTo-Html -Title 'AD Computer Account Health'|Set-Content (Join-Path $OutputPath "ad_computer_health_$stamp.html") -Encoding UTF8
$summary|Format-List
Write-Host "Reports saved to: $OutputPath" -ForegroundColor Green
