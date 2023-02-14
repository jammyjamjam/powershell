<#
Scenario
    You have been tasked to check systems on your network for malicous activity. Specifically, you will need to check Windows services for signs of malicious activity. Atackers have been know to steal code from the internet and make careless oversights when modifying code. They have been known to be careless with service descriptions.
Task 1)
    View the service descriptions of Windows services and find service descriptions that don’t begin with the letter 'T'
Task 2)
    View the service descriptions of Windows services and find service descriptions that contain parentheses.
Task 3)
    View the service descriptions of Windows services and find service descriptions that don’t end with a period.
Deliverables
    The Powershell code that accomplishes each of the 3 tasks.
Hint
    The Get-Service cmdlet does not contain a property called Description. However, Cim commands do have an instance command that contains this data.
#>
function Get-SuspiciousService{

    $list_of_sus_services = "$pwd\sus_services.txt"

    Add-content $list_of_sus_services -encoding utf8 -value "Task 1`n=================================================================================`n" 
    Get-CimInstance win32_service | Where-Object { $_.Description -notmatch "^T.*"} | Select-Object Name,Description | Format-Table -Wrap -AutoSize | out-file $list_of_sus_services -encoding utf8 -append 
    Add-Content $list_of_sus_services -encoding utf8 -value "Task 2`n=================================================================================`n"    
    Get-CimInstance win32_service | Where-Object {$_.Description -match "\(.*\)" } | Select-Object Name,Description | Format-Table -Wrap -AutoSize | out-file $list_of_sus_services -encoding utf8 -append
    Add-Content $list_of_sus_services -encoding utf8 -value "Task 3`n=================================================================================`n"
    Get-CimInstance win32_service | Where-Object {$_.Description -notmatch "\.$"} | Select-Object Name,Description | Format-Table -Wrap -AutoSize | out-file $list_of_sus_services -encoding utf8 -append

}

Get-SuspiciousService