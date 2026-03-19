<#
.SYNOPSIS
    Enumerates network sessions on a local or remote machine.

.DESCRIPTION
    This script uses the NetSessionEnum Windows API to retrieve information about
    established sessions on a computer. It can enumerate sessions on the local machine
    or a remote machine.

.PARAMETER ComputerName
    The name of the computer to query. Defaults to the local computer.

.PARAMETER ClientName
    Filter results to only show sessions from a specific client computer.

.PARAMETER UserName
    Filter results to only show sessions for a specific user.

.EXAMPLE
    .\Invoke-NetSessionEnumeration.ps1
    Lists all sessions on the local computer.

.EXAMPLE
    .\Invoke-NetSessionEnumeration.ps1 -ComputerName "SERVER01"
    Lists all sessions on SERVER01.

.EXAMPLE
    .\Invoke-NetSessionEnumeration.ps1 -ComputerName "SERVER01" -UserName "john"
    Lists all sessions for user 'john' on SERVER01.
#>

[CmdletBinding()]
param(
    [Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    [string]$ComputerName = $env:COMPUTERNAME,
    
    [Parameter()]
    [string]$ClientName,
    
    [Parameter()]
    [string]$UserName
)

begin {
    # Define the P/Invoke signatures
    $NetSessionEnumSignature = @"
    [DllImport("netapi32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern int NetSessionEnum(
        [MarshalAs(UnmanagedType.LPWStr)] string ServerName,
        [MarshalAs(UnmanagedType.LPWStr)] string ClientName,
        [MarshalAs(UnmanagedType.LPWStr)] string UserName,
        int Level,
        out IntPtr BufPtr,
        int PrefMaxLen,
        out int EntriesRead,
        out int TotalEntries,
        ref int ResumeHandle);
        
    [DllImport("netapi32.dll", SetLastError = true)]
    public static extern int NetApiBufferFree(IntPtr Buffer);
"@

    # Define SESSION_INFO_10 structure
    Add-Type -MemberDefinition $NetSessionEnumSignature -Name NetAPI -Namespace Win32 -ErrorAction SilentlyContinue

    # Define the SESSION_INFO_10 structure
    $SessionInfo10 = @"
    using System;
    using System.Runtime.InteropServices;
    
    namespace Win32
    {
        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
        public struct SESSION_INFO_10
        {
            [MarshalAs(UnmanagedType.LPWStr)]
            public string sesi10_cname;
            [MarshalAs(UnmanagedType.LPWStr)]
            public string sesi10_username;
            public uint sesi10_time;
            public uint sesi10_idle_time;
        }
    }
"@

    Add-Type -TypeDefinition $SessionInfo10 -ErrorAction SilentlyContinue
}

process {
    Write-Verbose "Enumerating sessions on $ComputerName"
    
    $BufPtr = [IntPtr]::Zero
    $EntriesRead = 0
    $TotalEntries = 0
    $ResumeHandle = 0
    $Level = 10  # SESSION_INFO_10 level
    
    # Prepare filter parameters
    $filterClient = if ($ClientName) { $ClientName } else { $null }
    $filterUser = if ($UserName) { $UserName } else { $null }
    $serverName = if ($ComputerName -eq $env:COMPUTERNAME) { $null } else { "\\$ComputerName" }
    
    try {
        # Call NetSessionEnum
        $result = [Win32.NetAPI]::NetSessionEnum(
            $serverName,
            $filterClient,
            $filterUser,
            $Level,
            [ref]$BufPtr,
            -1,  # MAX_PREFERRED_LENGTH
            [ref]$EntriesRead,
            [ref]$TotalEntries,
            [ref]$ResumeHandle
        )
        
        if ($result -eq 0) {
            Write-Verbose "Successfully retrieved $EntriesRead sessions"
            
            # Calculate the size of SESSION_INFO_10 structure
            $structSize = [Runtime.InteropServices.Marshal]::SizeOf([Type][Win32.SESSION_INFO_10])
            
            # Parse the results
            for ($i = 0; $i -lt $EntriesRead; $i++) {
                $offset = [IntPtr]::new($BufPtr.ToInt64() + ($i * $structSize))
                $sessionInfo = [Runtime.InteropServices.Marshal]::PtrToStructure($offset, [Type][Win32.SESSION_INFO_10])
                
                # Create custom object for output
                [PSCustomObject]@{
                    ComputerName = $ComputerName
                    ClientName   = $sessionInfo.sesi10_cname -replace '^\\\\'
                    UserName     = $sessionInfo.sesi10_username
                    ActiveTime   = [TimeSpan]::FromSeconds($sessionInfo.sesi10_time)
                    IdleTime     = [TimeSpan]::FromSeconds($sessionInfo.sesi10_idle_time)
                }
            }
        }
        elseif ($result -eq 5) {
            Write-Error "Access denied. You need administrative privileges to enumerate sessions."
        }
        elseif ($result -eq 53) {
            Write-Error "Network path not found. Unable to contact $ComputerName."
        }
        elseif ($result -eq 2312) {
            Write-Warning "No sessions found on $ComputerName"
        }
        else {
            Write-Error "NetSessionEnum failed with error code: $result"
        }
    }
    finally {
        # Free the buffer
        if ($BufPtr -ne [IntPtr]::Zero) {
            [void][Win32.NetAPI]::NetApiBufferFree($BufPtr)
        }
    }
}
