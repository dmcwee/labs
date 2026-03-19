param(
    [Parameter(Mandatory=$true)]$password
)

# Add JeffL to local Administrators group on VictimPC
Add-LocalGroupMember -Group "Administrators" -Member "Contoso\JeffL"

# Add Helpdesk to local Administrators group on VictimPC
Add-LocalGroupMember -Group "Administrators" -Member "Contoso\Helpdesk"

$action = New-ScheduledTaskAction -Execute 'cmd.exe'
$trigger = New-ScheduledTaskTrigger -AtLogOn
$runAs = 'Contoso\RonHD'
Register-ScheduledTask -TaskName "RonHD Cmd.exe - MDI SA Playbook" -Trigger $trigger -User $runAs -Password $password -Action $action

Write-Host "!!! WARNING !!! The Real Time Protection on this machine is being turned off in accordance with the lab. Be Careful!"
Set-MpPreference -DisableRealtimeMonitoring $true