function read-hosts_file {

    $ip_addresses = Get-Content C:\windows\System32\drivers\etc\hosts | select-string -Pattern "\b(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b" | foreach {$_.matches} | select value | sort

    #$a_class = 
    #$b_class = 
    #$c_class =

}

read-hosts_file