<#
    You have been tasked to collect user information on a unit’s server. The supported unit’s commander is worried that a malicious user could have added an account to the server. Write a Powershell script that will display groups and the users assigned to them.
Task 1)
    Connect to the Workstation(1,2,3) and install the RSAT_Install file on the Public Desktop.
Task 2)
    Write a PowerShell Script to retrieve a list of all domain groups on the system and list the members of each.
Deliverables
    A script that lists each group and the user that is a member

    For each group, format your output as follows:

        The Group Name

        A line divider, such as ====================================

        A new line character
Hints:
    Search for PowerShell commands that will list users in Active Directory
    Search for PowerShell commands that will list groups in Active Directory
    Search for PowerShell commands that will list the members of groups
#>
foreach ($group in $adgroups) {write-host ("$($group | select-object -ExpandProperty Name)`n====================================`n$(Get-ADGroupMember -Identity ($group | select-object -ExpandProperty Name) | select-object -ExpandProperty Name)`n")}

#V2:
Get-Adgroup -filter * | ForEach-Object {
    $groupName = $_ | Select-Object -ExpandProperty Name
    $userNames = (Get-ADGroupMember -Identity $groupName | Select-Object -ExpandProperty Name) -join "`n"
    Write-Host "$groupName`n====================================`n$userNames`n"
}
