#exercise3_fromchatgpt
$finalArray = @()
$innerArray = @()

while ($true) {
    $input = Read-Host "Enter a word or an integer (or an empty string to finish): "

    if ($input -eq "") {
        if ($innerArray) {
            $finalArray += ,$innerArray
        }
        break
    }

    if ([int]::TryParse($input, [ref]$null)) {
        $innerArray += ,[int]$input
        $finalArray += ,$innerArray
        $innerArray = @()
    } else {
        $innerArray += ,$input
    }
}

Write-Output $finalArray