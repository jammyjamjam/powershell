<#
You are part of a team of software developers tasked to write the program for remote Agents to make mission reports into. Specifically, YOU are tasked to write the password system that will take the Agent’s creditionals, place them into a jagged array and then return them to the larger reporting system.

The format of the jagged array will be as such. Agents will provide key words, which must be in placed into the inner arrays. Each array will end in an integer, which must be placed into the array as a type of integer. The final inner array may or may not end with a integer value. When the Agent enters an empty string, this will signal the end of their input, and the finalized jagged array should be returned.

For example, if you were given the following inputs:
Example: Submitted Values

"Longing", "rusted", "furnace", "daybreak", "17", "benign", "9", "homecoming", "1", "freight car", ""

The returned jagged array would be formatted as such:
Example: Returned Value

(("Longing", "rusted", "furnace", "daybreak", 17), ("benign", 9), ("homecoming", 1), ("freight car"))
#>

function agent_credentials {

    $jagged_array = @()
    $temp_array = @()
    
    while ($True){
        $input = Read-Host "Enter Credentials "

        if ([Int]::TryParse($input, [ref] $null)) {
            $temp_array += ,[int]$input
            $jagged_array += ,$temp_array
            $temp_array = @()
            }
        
        elseif($input -eq ""){
            if($temp_array.count -gt 0){
                $jagged_array += ,$temp_array
                break
            }
            else {
                break
            }
        }
        else{
            $temp_array += ,$input
        }
    }

    foreach($array in $jagged_array){
        $arrayForDisplay += "( "
        foreach($arrayelement in $array)
        {
            $arrayForDisplay += $arrayelement.ToString() + ","
        }
    
        $arrayForDisplay = $arrayForDisplay -replace ".$"
        $arrayForDisplay += " ), "
    }
    $arrayForDisplay = $arrayForDisplay.Trim() -replace ".$"
    $arrayForDisplay += " )"
    
    $arrayForDisplay
    
}

agent_credentials

