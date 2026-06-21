[CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact='High')]
param(
 [switch]$RestartIntuneManagementExtension,
 [switch]$RestartMdmServices,
 [switch]$TriggerMdmSync,
 [switch]$ResetCompanyPortal,
 [switch]$DryRun,[switch]$Yes,
 [string]$OutputPath=(Join-Path $env:ProgramData 'IntuneEnrollmentRepair')
)
$ErrorActionPreference='Stop';$script:Failures=0;$script:Actions=0
$run=Join-Path $OutputPath (Get-Date -Format yyyyMMdd_HHmmss);New-Item -ItemType Directory $run -Force|Out-Null
$log=Join-Path $run 'repair.log';$before=Join-Path $run 'before.txt';$after=Join-Path $run 'after.txt'
function Log($m){"$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $m"|Tee-Object -FilePath $log -Append}
function Admin{$p=[Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent());$p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)}
function State($path){@("Collected: $(Get-Date -Format o)",(& dsregcmd.exe /status|Out-String),(Get-Service IntuneManagementExtension,dmwappushservice,DiagTrack -ErrorAction SilentlyContinue|Format-Table -Auto|Out-String),(Get-ScheduledTask -TaskPath '\Microsoft\Windows\EnterpriseMgmt\*' -ErrorAction SilentlyContinue|Select-Object TaskName,TaskPath,State|Format-Table -Auto|Out-String),(Get-AppxPackage Microsoft.CompanyPortal -ErrorAction SilentlyContinue|Select-Object Name,Version,InstallLocation|Format-List|Out-String))|Set-Content $path -Encoding UTF8}
function Act($d,[scriptblock]$a){$script:Actions++;Log $d;if($DryRun){Log "DRY-RUN: $d";return};try{&$a;Log "SUCCESS: $d"}catch{$script:Failures++;Log "FAILED: $d - $($_.Exception.Message)"}}
if(-not($RestartIntuneManagementExtension -or $RestartMdmServices -or $TriggerMdmSync -or $ResetCompanyPortal)){Write-Error 'Choose at least one repair action.';exit 2}
if(($RestartIntuneManagementExtension -or $RestartMdmServices -or $TriggerMdmSync) -and -not $DryRun -and -not(Admin)){Write-Error 'Run from elevated PowerShell.';exit 4}
State $before
if(-not $Yes -and -not $DryRun){if((Read-Host 'Apply selected Intune enrollment repairs? Type YES') -ne 'YES'){Log 'Cancelled.';exit 10}}
if($RestartIntuneManagementExtension){if(Get-Service IntuneManagementExtension -ErrorAction SilentlyContinue){Act 'Restarting Intune Management Extension' {Restart-Service IntuneManagementExtension -Force}}else{$script:Failures++;Log 'Intune Management Extension is not installed.'}}
if($RestartMdmServices){foreach($s in 'dmwappushservice','DiagTrack'){if(Get-Service $s -ErrorAction SilentlyContinue){Act "Starting service $s" {Set-Service $s -StartupType Automatic -ErrorAction SilentlyContinue;Start-Service $s -ErrorAction Stop}}}}
if($TriggerMdmSync){$tasks=Get-ScheduledTask -TaskPath '\Microsoft\Windows\EnterpriseMgmt\*' -ErrorAction SilentlyContinue|Where-Object {$_.TaskName -match 'PushLaunch|Schedule|Policy|OMADM'};if(-not $tasks){$script:Failures++;Log 'No EnterpriseMgmt sync tasks were found.'}else{foreach($task in $tasks){Act "Starting MDM task $($task.TaskPath)$($task.TaskName)" {Start-ScheduledTask -InputObject $task}}}}
if($ResetCompanyPortal){$pkg=Get-AppxPackage Microsoft.CompanyPortal -ErrorAction SilentlyContinue;if(-not $pkg){$script:Failures++;Log 'Company Portal package was not found.'}elseif(Get-Command Reset-AppxPackage -ErrorAction SilentlyContinue){Act 'Resetting Company Portal package' {$pkg|Reset-AppxPackage}}else{Act 'Re-registering Company Portal package' {Add-AppxPackage -DisableDevelopmentMode -Register (Join-Path $pkg.InstallLocation 'AppxManifest.xml')}}}
Start-Sleep 3;State $after
if($script:Failures){Log "Completed with $script:Failures failure(s).";exit 20};Log "Repair completed. Actions: $script:Actions";exit 0
