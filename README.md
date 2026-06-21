# AD Computer Account Health Toolkit

PowerShell tooling for Active Directory computer-account health reporting and guarded account corrections.

## Scripts

- `AD_Computer_Account_Health_Toolkit.ps1` — read-only computer-account reporting.
- `AD_Computer_Account_Repair_Toolkit.ps1` — targeted enable, disable, description, and OU-move repairs.

## Requirements

- Windows PowerShell or PowerShell on Windows with the RSAT `ActiveDirectory` module.
- Connectivity to Active Directory.
- Delegated permissions for the selected changes.

Local elevation is not inherently required for AD object changes; authorization is determined by the credentials and delegated directory permissions used to run PowerShell.

## Examples

Preview enabling an account:

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\AD_Computer_Account_Repair_Toolkit.ps1 `
  -ComputerName PC01 -EnableAccount -DryRun
```

Move and describe an account:

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\AD_Computer_Account_Repair_Toolkit.ps1 `
  -ComputerName OLD-PC `
  -MoveToOU "OU=Quarantine,DC=contoso,DC=com" `
  -Description "Quarantined pending review" -Yes
```

The script validates the target OU before changes and refuses to disable or move a domain controller account. Omit `-Yes` to require typing `YES`.

## Evidence, backup, and verification

Each run creates a timestamped directory under `%ProgramData%\ADComputerAccountRepair` unless `-OutputPath` is supplied. It contains:

- `before.json` and `backup\computer-account-before.clixml` — pre-change object evidence;
- `after.json` — post-action object state;
- `repair.log` — action and verification results.

The final enabled state, description, and target OU are verified when requested. `-DryRun` records intended actions without applying or verifying them.

## Exit codes

| Code | Meaning |
|---:|---|
| 0 | Completed successfully, including a successful dry run |
| 2 | Invalid arguments, missing object/OU, or safety refusal |
| 3 | Unsupported platform or missing ActiveDirectory module |
| 10 | User cancelled |
| 20 | One or more repair actions failed |
| 30 | Post-repair verification failed |

## Validation status

The scripts were source-reviewed during this update. They were not runtime-tested in an Active Directory environment.

## Author

Dewald Pretorius — L2 IT Support Engineer
