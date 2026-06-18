# Intune Enrollment Troubleshooting Toolkit

A read-only PowerShell toolkit for Intune enrollment and MDM troubleshooting evidence.

## Features

- dsregcmd status export
- MDM enrollment event summary
- Device management service context
- Company Portal presence check
- Scheduled task context
- CSV, TXT, and HTML reports

## How to run

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\Intune_Enrollment_Troubleshooting_Toolkit.ps1
```

## Safety

Diagnostic-only. It does not enroll, unenroll, or modify MDM settings.
