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

Write-Host "Adding JeffL to local admin group"
Add-LocalGroupMember -Group "Administrators" -Member "contoso\jeffl"

Write-Host "Adding Helpdesk to local admin group"
Add-LocalGroupMember -Group "Administrator" -Member "contoso\Helpdesk"

Write-Host "Creating Scheduled task run as RonHD"
$action = New-ScheduledTaskAction -Execute "cmd.exe"
$trigger = New-ScheduledTaskTrigger -AtLogOn
$runas = 'contoso\ronhd'
Register-ScheduledTask -TaskName "RonHD Cmd.exe - MDI Sec Alert Playbook" -Trigger $trigger -User $runas -Password $Password -Action $action

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