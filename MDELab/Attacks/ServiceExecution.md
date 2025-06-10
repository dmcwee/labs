# System Services: Service Execution

Service Execution is a technique where attackers abuse the Windows Service Control Manager (services.exe) to run malicious commands or payloads. The Service Control Manager, which allows the management of system services, can be accessed by attackers through both graphical interfaces and command-line utilities like sc.exe and net. This enables them to execute code with service-level privileges, which can aid in establishing persistence or elevating privileges.

## Simulation

Run the following commands in PowerShell on a test device.

```powershell
sc.exe create "MaliciousService" binPath= "%COMSPEC% /c powershell.exe -nop -w hidden -command New-Item -ItemType File C:\art-marker.txt"
sc.exe start "MaliciousService"
```

## Cleanup

```powershell
sc.exe delete "MaliciousService"
```

## Detection

| Alert Title | Alert Description | Alert Details |
| -- | -- | -- |
| Suspicious service registration | A system program was registered as a service. This can indicate malicious intent to establish persistence or gain system privileges. | **Category:** Persistence<br/>**MITRE ATT&CK Techniques:** T1036: Masquerading, T1036.004: Masquerade Task or Service, T1543.003: Windows Service, T1569.002: Service Execution, T1574.011: Services Registry Permissions Weakness<br/>**Service source:** Microsoft Defender for Endpoint <br/>**Detection source:** EDR<br/>**Detection technology:** Behavior<br/>**Detection status:** Detected<br/> |
