# Intune Enrollment Troubleshooting Toolkit

A PowerShell toolkit for Intune enrollment diagnostics and local management-component repair.

## Diagnostic script

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\Intune_Enrollment_Troubleshooting_Toolkit.ps1
```

## Repair script

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\Intune_Enrollment_Repair_Toolkit.ps1 -TriggerMdmSync -DryRun
```

Available actions:

```powershell
.\Intune_Enrollment_Repair_Toolkit.ps1 -RestartIntuneManagementExtension
.\Intune_Enrollment_Repair_Toolkit.ps1 -RestartMdmServices
.\Intune_Enrollment_Repair_Toolkit.ps1 -TriggerMdmSync
.\Intune_Enrollment_Repair_Toolkit.ps1 -ResetCompanyPortal
```

The repair script restarts local Intune services, starts discovered management synchronisation tasks, and resets or re-registers Company Portal. It captures device-registration, service, task and application state before and after repair. It supports `-DryRun`, confirmation prompts, logs and clear exit codes.

It does not remove the device from management or change cloud-side Intune policies.

## Author

Dewald Pretorius — L2 IT Support Engineer
