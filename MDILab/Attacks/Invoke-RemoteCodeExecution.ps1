<#
.SYNOPSIS
    Simulates remote code execution by connecting to a remote machine and writing an event log entry.

.DESCRIPTION
    This script connects to a remote machine using PowerShell remoting and executes a command
    to write an entry into the Windows Application Event Log, simulating remote code execution.

.PARAMETER ComputerName
    The name of the remote computer to connect to.

.PARAMETER Credential
    Optional credentials to use for the remote connection.

.EXAMPLE
    .\Invoke-RemoteCodeExecution.ps1 -ComputerName "DC01"

.EXAMPLE
    .\Invoke-RemoteCodeExecution.ps1 -ComputerName "DC01" -Credential (Get-Credential)
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ComputerName,

    [Parameter(Mandatory = $false)]
    [PSCredential]$Credential
)

try {
    # Get the current machine name
    $sourceMachine = $env:COMPUTERNAME
    
    Write-Host "Attempting to connect to remote machine: $ComputerName" -ForegroundColor Yellow
    Write-Host "Source machine: $sourceMachine" -ForegroundColor Cyan

    # Prepare the script block to execute on the remote machine
    $scriptBlock = {
        param($SourceMachine)
        
        $eventMessage = "Remote code was executed on this machine from a connection on $SourceMachine"
        
        # Create event source if it doesn't exist
        $sourceName = "RemoteCodeExecution"
        if (-not [System.Diagnostics.EventLog]::SourceExists($sourceName)) {
            New-EventLog -LogName Application -Source $sourceName
            Write-Output "Created event source: $sourceName"
        }
        
        # Write the event log entry
        Write-EventLog -LogName Application `
                       -Source $sourceName `
                       -EventId 2026 `
                       -EntryType Warning `
                       -Message $eventMessage `
                       -Category 0
        
        Write-Output "Event log entry created successfully"
        Write-Output "Message: $eventMessage"
    }

    # Execute the command on the remote machine
    $invokeParams = @{
        ComputerName = $ComputerName
        ScriptBlock  = $scriptBlock
        ArgumentList = $sourceMachine
    }

    if ($Credential) {
        $invokeParams.Add('Credential', $Credential)
    }

    $result = Invoke-Command @invokeParams

    Write-Host "`nRemote Execution Results:" -ForegroundColor Green
    $result | ForEach-Object { Write-Host $_ -ForegroundColor White }

    Write-Host "`nRemote code execution simulation completed successfully!" -ForegroundColor Green
}
catch {
    Write-Host "`nError occurred during remote code execution:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host "`nPossible issues:" -ForegroundColor Yellow
    Write-Host "  - PowerShell remoting may not be enabled on the target machine" -ForegroundColor Yellow
    Write-Host "  - Firewall rules may be blocking the connection" -ForegroundColor Yellow
    Write-Host "  - You may not have sufficient permissions on the remote machine" -ForegroundColor Yellow
    Write-Host "  - The remote machine may not be reachable" -ForegroundColor Yellow
    throw
}
