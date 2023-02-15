function read-hosts_file {

    $ip_addresses_in_host_file = @()
    $ip_addresses_in_host_file = Get-Content C:\Users\student\Documents\github_repo\powershell\Practical_Exercises\host.txt | select-string -Pattern "\b(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b" | foreach {$_.matches} | select value -Unique

    $ip_addresses_in_host_file = $ip_addresses_in_host_file.Value
    $ip_addresses_in_host_file > .\extracted_ips.txt

    $class_a = @()
    $class_b = @()
    $class_c = @()
    $class_d = @()
    $class_e = @()
    $invalid_ips = @()
    
    foreach ($ip in $ip_addresses_in_host_file){
        $octets = $ip.Split('.')
        switch ([int]$octets[0])
        {
        {$_ -ge 0 -and $_ -lt 128} {$class_a += $ip}
        {$_ -ge 128 -and $_ -lt 192} {$class_b += $ip}
        {$_ -ge 192 -and $_ -lt 224} {$class_c += $ip}
        {$_ -ge 224 -and $_ -lt 240} {$class_d += $ip}
        {$_ -ge 240 -and $_ -lt 256} {$class_e += $ip}

        default {$invalid_ips += $ip}

    }
}    
    write-host "Class A IP addresses found:`n $($class_a | Sort-Object {[System.Version]$_.Replace('.','.')})`n"
    write-host "Class B IP addresses found:`n $($class_b | Sort-Object {[System.Version]$_.Replace('.','.')})`n"
    write-host "Class C IP addresses found:`n $($class_c | Sort-Object {[System.Version]$_.Replace('.','.')})`n"
    write-host "Class D IP addresses found:`n $($class_d | Sort-Object {[System.Version]$_.Replace('.','.')})`n"
    write-host "Class E IP addresses found:`n $($class_e | Sort-Object {[System.Version]$_.Replace('.','.')})`n"
    write-host "Invalid IP addresses found:`n $($invalid_ips)`n"
    

}

read-hosts_file