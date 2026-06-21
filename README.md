# AD Computer Account Health Toolkit

PowerShell tools for Active Directory computer-account health reporting and guarded account corrections.

## Audit

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\AD_Computer_Account_Health_Toolkit.ps1
```

## Repair

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\AD_Computer_Account_Repair_Toolkit.ps1 -ComputerName PC01 -EnableAccount -DryRun
```

Examples:

```powershell
.\AD_Computer_Account_Repair_Toolkit.ps1 -ComputerName PC01 -EnableAccount
.\AD_Computer_Account_Repair_Toolkit.ps1 -ComputerName OLD-PC -DisableAccount
.\AD_Computer_Account_Repair_Toolkit.ps1 -ComputerName PC01 -Description 'Finance workstation'
.\AD_Computer_Account_Repair_Toolkit.ps1 -ComputerName OLD-PC -MoveToOU 'OU=Quarantine,DC=contoso,DC=com'
```

The repair workflow validates the target and destination OU, captures the object before and after changes, and supports `-DryRun`, confirmation, logging and clear exit codes. Domain controller accounts cannot be disabled or moved by this script.

## Requirements

RSAT Active Directory module and appropriate delegated permissions.

## Author

Dewald Pretorius — L2 IT Support Engineer
