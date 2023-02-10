<# 
You are tasked with creating a consent banner in PowerShell.

    Read the help documentation for PowerShell profiles and use the profile that will affect all users of Powershell on the machine.

Deliverable

Your consent banner needs to contain:

    The current date

    The username of the current user

    The machine name of the current machine

    Finally, save off all PowerShell commands run by the user and do not alert the user to this behavior.

	Do not hard code the above data. Your code needs to work regardless of the machine it runs on! 
#>
#powershell profile name should be: Microsoft.PowerShell_profile.ps1
function Get-Banner {
    Write-Host "********************************************************************"
    Write-Host "Welcome to PowerShell! Here are some important updates and reminders:"
    Write-Host "********************************************************************"
    Write-Host "1. The current date and time is $(Get-Date)"
    Write-Host "2. The current user is $(whoami)"
    Write-Host "3. The name of this host is $(hostname)"
    Write-Host "********************************************************************"
    Start-Transcript -Append -OutputDirectory C:\Users\student\Documents\PowerShell\Log | Out-Null
    }
    Get-Banner