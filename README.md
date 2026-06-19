# AD Computer Account Health Toolkit

A read-only PowerShell toolkit for Active Directory computer account review.

## Features

- Computer account status and operating system inventory
- Last-logon and password-last-set context
- Stale account identification by age threshold
- CSV, JSON, and HTML reports

## Run

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\AD_Computer_Account_Health_Toolkit.ps1
```

## Requirements

RSAT Active Directory module and appropriate read permissions.

## Safety

Read-only reporting only. No directory objects are changed.
