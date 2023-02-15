function read-hosts_file {

    $ip_addresses_in_host_file = @()
    $ip_addresses_in_host_file = Get-Content C:\windows\System32\drivers\etc\hosts | select-string -Pattern "\b(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b" | foreach {$_.matches} | select value

    write-host $ip_addresses_in_host_file

}

read-hosts_file