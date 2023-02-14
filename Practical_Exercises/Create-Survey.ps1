<#
This function presents the user with a menu to select options in order to generate a survey of the computer the user is on
#>
Import-Module -name "C:\Users\student\Documents\github_repo\powershell\Practical_Exercises\survey_functions.psm1"
Import-Module -name PSMenu

$Chosen = @()
$Chosen = Show-Menu -MenuItems @("SystemName", "SystemTime", "LoggedOnUsers", "ProcessList", "ServiceList","NetInfo","SystemInfo","MappedDrives","SharedResources","PlugNPlayDevices","ScheduledTasks", $(Get-menuSeparator), "Quit") -MultiSelect

$output_file = "$pwd\survey_results_are_in.txt"
foreach ($item in $Chosen) {
    switch ($item) {
        "SystemName" {get-systemname | out-file $output_file -append -encoding utf8}
        "SystemTime" {get-systemdatetime | out-file $output_file -append -encoding utf8}
        "LoggedOnUsers" {get-logged_on_users | out-file $output_file -append -encoding utf8}
        "ProcessList" {get-pid_sorted_processes | out-file $output_file -append -encoding utf8}
        "ServiceList" {get-service_state | out-file $output_file -append -encoding utf8}
        "NetInfo" {get-NetInformation | out-file $output_file -append -encoding utf8}
        "SystemInfo" {get-Sysinfo | out-file $output_file -append -encoding utf8}
        "MappedDrives" {get-networkedDrives | out-file $output_file -append -encoding utf8}
        "SharedResources" {get-sharedResources | out-file $output_file -append -encoding utf8}
        "PlugNPlayDevices" {get-PlugNPlay | out-file $output_file -append -encoding utf8}
        "ScheduledTasks" {get-schedTasks | out-file $output_file -append -encoding utf8}
    }

}