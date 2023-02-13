$a = "a string"
write-host ("`n" + "======================" + "`n" + "$a")


foreach ($group in $adgroups) {write-host ("$($group | select-object -ExpandProperty Name)`n====================================`n$(Get-ADGroupMember -Identity ($group | select-object -ExpandProperty Name) | select-object -ExpandProperty Name)`n")}