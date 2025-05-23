param(
    [switch]$cleanup
)

if(!$cleanup) {
    Set-MpPreference -DisableRealtimeMonitoring $true
    Set-MpPreference -MAPSReporting 0
    Set-MpPreference -ExclusionExtension "exe" -ExclusionPath "C:\"
}
else {
    Set-MpPreference -DisableRealtimeMonitoring $false
    Set-MpPreference -MAPSReporting 2
    Remove-MpPreference -ExclusionExtension "exe" -ExclusionPath "C:\"
}