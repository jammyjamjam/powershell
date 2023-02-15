function Get-SuspiciousConnection {
    <# 
    .SYNOPSIS
    Given a suspicious IP or port via parameter this cmdlet will return a list of connections that exist that meet that criteria.
    
    .DESCRIPTION
    Given a suspicious IP or port via parameter this cmdlet will return a list of connections that exist that meet that criteria.
    
    .PARAMETER RemoteIP
    Specifies the suspicious IP to search for in active connections
    
    .PARAMETER RemotePort
    Specifies the suspicious port to search for in active connections
    
    .EXAMPLE
    .\Get-MatchingFiles.ps1 -Directory "C:\MyFiles" -Hash "d41d8cd98f00b204e9800998ecf8427e"
    Searches for files in "C:\MyFiles" that match the specified MD5 hash value.
    
    .EXAMPLE
    .\Get-MatchingFiles.ps1 -Directory "C:\MyFiles","D:\OtherFiles" -Hash "d41d8cd98f00b204e9800998ecf8427e","cfcd208495d565ef66e7dff9f98764da"
    Searches for files in "C:\MyFiles" and "D:\OtherFiles" that match the specified MD5 hash values.
    
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, ParameterSetName = 'RemoteIP')]
        [string[]] $RemoteIP,
        [Parameter(Mandatory=$true, ParameterSetName = 'RemotePort')]
        [string[]] $RemotePort
    )

    $active_remote_ips = @()
    $active_remote_ports = @()

    $active_remote_ips = Get-NetTCPConnection | Select-Object -expandProperty RemoteAddress
    $active_remote_ports = Get-NetTCPConnection | Select-Object -expandProperty RemotePort
    
    if ($RemoteIP.Length -gt 0) {
        foreach ($ip in $RemoteIP) {
            if ($active_remote_ips.Contains($ip)){
                Get-NetTCPConnection | Where-Object -Property RemoteAddress -like $ip
            }
            else {
                write-host "Remote IP $($ip) not found in any active connections"
            }
        }
    }

    if ($RemotePort.Length -gt 0) {
        foreach ($port in $RemotePort) {
            if ($active_remote_ports.Contains($port)){
                Get-NetTCPConnection | Where-Object -Property RemotePort -like $port
            }
            else {
                write-host "Remote port $($port) not found in any active connections"
            }
        }
    }
    
}