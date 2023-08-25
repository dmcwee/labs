<#
  .Synopsis
  Use this script to configure the VictimPC for MDI Security Alert Lab

  .DESCRIPTION
  This scrips adds contoso\JeffL and Contoso\Helpdesk to the local admin group. This script creates the 
  timer job used to simulate a working an managed network where a user contoso\RonHD had logged into the machine.
  Ths script completes by disabling Defender AV so the common hacker tools can be downloaded and used on the machine.

  .EXAMPLE
  Invoke-VictimPcConfig -Password [lab admin password]
#>
param(
  [securestring] $Password
)


Write-Host "Creating Scheduled task run powershell as SamiraA"
$action = New-ScheduledTaskAction -Execute "cmd.exe" -Argument "dir \\contosodc\c$"
$trigger = New-ScheduledTaskTrigger -Daily -At 12am 
$runas = 'contoso\SamiraA'
$task = Register-ScheduledTask -TaskName "SamiraA Cmd.exe - MDI Sec Alert Playbook" -Trigger $trigger -User $runas -Password $Password -Action $action
$task.Triggers.Repetition.Duration = "P1D"
$task.Triggers.Repetition.Interval = "PT30M"
$task | Set-ScheduledTask

Write-Host "Disabling Defender AV Protection"
$registryPath = "HKLM:\SOFTWARE\Microsoft\Windows Defender"
$name = "DisableAntiVirus"
$value = 1
New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType Dword

Write-Host "Disabling Defender Anti Spyware"
$registryPath = "HKLM:\SOFTWARE\Microsoft\Windows Defender"
$name = "DisableAntiSpyware"
$value = 1
New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType Dword