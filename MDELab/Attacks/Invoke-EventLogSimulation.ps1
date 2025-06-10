param(
    [string][ValidateSet("wevtutil", "wmic", "powershell")]$Mode
)

if($Mode -eq "webtutil") {
    wevtutil cl system
    wevtutil cl application
    wevtutil cl security
}
elseif ($Mode -eq "wmic") {
    wmic process call create "cmd.exe /c wevtutil cl Application"
    wmic process call create "cmd.exe /c wevtutil cl system"
    wmic process call create "cmd.exe /c wevtutil cl security"
}
else {
    Start-Process -FilePath "wevtutil" -ArgumentList "cl", "Application" -NoNewWindow -Wait
    Start-Process -FilePath "wevtutil" -ArgumentList "cl", "System" -NoNewWindow -Wait
    Start-Process -FilePath "wevtutil" -ArgumentList "cl", "Security" -NoNewWindow -Wait
}
