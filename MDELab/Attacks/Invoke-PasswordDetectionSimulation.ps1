param(
    [string]$OutputPath = "$env:Temp",
    [string]$SearchPath = "C:\Users",
    [switch]$CleanUp
)

$credPath = "$OutputPath\creds"

if($CleanUp) {
    Remove-Item -Path $credPath -Recurse -Force
}
else {
    New-Item -Path $credPath -ItemType Directory -ErrorAction SilentlyContinue

    reg query HKCU /f password /t REG_SZ /s > "$credPath\HKCU_Passwords.txt"
    reg query HKLM /f password /t REG_SZ /s > "$credPath\HKLM_Passwords.txt"

    $zipFilePath = "$credPath\passwords.zip"
    Compress-Archive -Path $credPath -DestinationPath $zipFilePath -Force

    #findstr /s /i /m "password" *.*
    Get-ChildItem -Path $SearchPath -Recurse -File | 
        Select-String -Pattern "password" | 
        Select-Object -ExpandProperty Path -Unique |
        Out-File -FilePath "$credPath\password_search_results.txt" -Encoding utf8
}