<#
This function presents the user with a menu to select options in order to generate a survey of the computer the user is on
#>
Import-Module -name "C:\Users\student\Documents\github_repo\powershell\Practical_Exercises\survey_functions.psm1"
Import-Module -name PSMenu

$Chosen = @()
$Chosen = Show-Menu -MenuItems @("SystemName", "SystemTime", "LoggedOnUsers", "ProcessList", "ServiceList","NetInfo","SystemInfo","MappedDrives","SharedResources","PlugNPlayDevices","ScheduledTasks", $(Get-menuSeparator), "Quit") -MultiSelect

foreach ($item in $Chosen) {
    switch ($item) {
        "SystemName" {
            get-systemname
        }
        "SystemTime" {
            get-systemdatetime
        }
        "LoggedOnUsers" {
            get-logged_on_users
        }
        "ProcessList" {
            get-pid_sorted_processes
        }
        "ServiceList" {
            get-service_state
        }
        "NetInfo" {
            get-NetInformation
        }
        "SystemInfo" {
            get-Sysinfo
        }
        "MappedDrives" {
            get-networkedDrives
        }
        "SharedResources" {
            get-sharedResources
        }
        "PlugNPlayDevices" {
            get-PlugNPlay
        }
        "ScheduledTasks" {
            get-schedTasks
        }
    }
}