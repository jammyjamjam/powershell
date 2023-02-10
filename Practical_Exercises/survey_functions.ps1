function get-systemdatetime {
    Get-Date -Format "yyyy-MM-dd@hh:mm:ss"
}
get-systemdatetime

function get-systemname {
    write-host $env:COMPUTERNAME
}
get-systemname

function get-users_of_groups {
    $groups = (Get-LocalGroup | select $_.name)
    
    foreach ($group in $groups) {
        $users = Get-LocalGroupMember -Group $group
        
        if ($users.Count -gt 0){
        write-host "$group`n====================================`n$users`n"
        $users = @()
        }
        else{
            continue
        }
    }
}
get-users_of_groups

function get-logged_on_users {

}

function get-pid_sorted_processes {
    
}