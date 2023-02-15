#compares current users of AD to a list provided by HR

#$userlist = Get-ADUser -Filter * | select surname,GivenName
#$user_formatted_list = @()
#foreach ($line in $userlist) {if ($line.surname -gt 0) {$user_formatted_list += ($line.surname + ',' + ' ' + $line.givenname)} else (continue)}

$hr_provided_users = @()
$hr_provided_users = Get-Content .\hr.txt

$users_in_ad = @()
$users_in_ad = Get-Content .\users_from_ad_query.txt



foreach ($ad_user in $users_in_ad) {
    if ($hr_provided_users.Contains($ad_user)){
        continue
    }
    else{
        Write-Host "$ad_user was not found in the HR provided list"
    }
}