param(
    [switch]$CleanUp
)

if($CleanUp) {
    sc.exe delete "MaliciousService"
}
else {
    sc.exe create "MaliciousService" binPath= "%COMSPEC% /c powershell.exe -nop -w hidden -command New-Item -ItemType File C:\art-marker.txt"
    sc.exe start "MaliciousService"
}