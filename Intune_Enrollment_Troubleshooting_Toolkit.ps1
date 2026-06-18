#requires -Version 5.1
<#
.SYNOPSIS
    Intune Enrollment Troubleshooting Toolkit.
.DESCRIPTION
    Read-only Intune and MDM enrollment evidence collector for Windows support.
#>
[CmdletBinding()]
param([string]$OutputPath,[int]$Hours=72)
$RunStamp=Get-Date -Format 'yyyyMMdd_HHmmss'
if([string]::IsNullOrWhiteSpace($OutputPath)){$OutputPath=Join-Path ([Environment]::GetFolderPath('Desktop')) 'Intune_Enrollment_Reports'}
New-Item -Path $OutputPath -ItemType Directory -Force|Out-Null
try{dsregcmd.exe /status|Out-File (Join-Path $OutputPath "dsregcmd_status_$RunStamp.txt") -Encoding UTF8}catch{}
$start=(Get-Date).AddHours(-1*$Hours)
$logs='Microsoft-Windows-DeviceManagement-Enterprise-Diagnostics-Provider/Admin','Microsoft-Windows-AAD/Operational'
$events=@();foreach($log in $logs){try{$events+=Get-WinEvent -FilterHashtable @{LogName=$log;StartTime=$start;Level=1,2,3} -ErrorAction Stop|Select-Object @{n='Log';e={$log}},TimeCreated,Id,ProviderName,LevelDisplayName,Message}catch{}}
$events|Export-Csv (Join-Path $OutputPath "mdm_enrollment_events_$RunStamp.csv") -NoTypeInformation -Encoding UTF8
$services=Get-Service|Where-Object {$_.Name -match 'dmwappushservice|DeviceInstall|Schedule|Winmgmt'}|Select-Object Name,DisplayName,Status,StartType
$services|Export-Csv (Join-Path $OutputPath "device_management_services_$RunStamp.csv") -NoTypeInformation -Encoding UTF8
$tasks=Get-ScheduledTask -ErrorAction SilentlyContinue|Where-Object {$_.TaskPath -match 'EnterpriseMgmt|Workplace Join'}|Select-Object TaskName,TaskPath,State
$tasks|Export-Csv (Join-Path $OutputPath "mdm_related_tasks_$RunStamp.csv") -NoTypeInformation -Encoding UTF8
$app=Get-AppxPackage -Name '*CompanyPortal*' -ErrorAction SilentlyContinue|Select-Object Name,Version,PackageFullName
$app|Export-Csv (Join-Path $OutputPath "company_portal_$RunStamp.csv") -NoTypeInformation -Encoding UTF8
$html="<h1>Intune Enrollment Troubleshooting - $env:COMPUTERNAME</h1><p>Generated $(Get-Date)</p><h2>Events</h2>$($events|Select-Object -First 100|ConvertTo-Html -Fragment)<h2>Tasks</h2>$($tasks|ConvertTo-Html -Fragment)"
$html|ConvertTo-Html -Title 'Intune Enrollment Troubleshooting'|Set-Content (Join-Path $OutputPath "intune_enrollment_$RunStamp.html") -Encoding UTF8
Write-Host "Reports saved to: $OutputPath" -ForegroundColor Green
Start-Process explorer.exe -ArgumentList "`"$OutputPath`"" -ErrorAction SilentlyContinue
