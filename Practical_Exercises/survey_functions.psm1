function get-systemdatetime {
    Get-Date -Format "yyyy-MM-dd@hh:mm:ss"
}

function get-systemname {
    write-host $env:COMPUTERNAME
}

#function get-users_of_groups {
#    Get-Adgroup -filter * | ForEach-Object {
#        $groupName = $_ | Select-Object -ExpandProperty Name
#        $userNames = (Get-ADGroupMember -Identity $groupName | Select-Object -ExpandProperty Name) -join "`n"
#        Write-Host "$groupName`n====================================`n$userNames`n"
#    }
#}
#get-users_of_groups

function get-logged_on_users {
    Get-WmiObject -Class Win32_LoggedOnUser | Select-Object Antecedent -Unique
}

function get-pid_sorted_processes {
    Get-WmiObject Win32_Process | select name,processid,parentprocessid,executablepath
}
function get-service_state {
    Get-WmiObject win32_service | select name,state,processid,pathname
}

function get-NetInformation {
    Get-NetTCPConnection
    Get-NetAdapter
}

function get-Sysinfo {
    Get-ComputerInfo
}

function get-networkedDrives {
    get-smbMapping
}

function get-PlugNPlay {
    Get-PnpDevice
}

function get-sharedResources {
    get-fileshare
}

function get-schedTasks {
    get-ScheduledTask
}