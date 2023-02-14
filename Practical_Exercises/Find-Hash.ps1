<#
.SYNOPSIS
Takes in a directory and one or more file hashes and searches the given directory and subdirectories for files with matching hashes and returns the matches

.DESCRIPTION
The Find-Hash cmdlet takes in a directory and one or more file hashes and searches the given directory and subdirectories for files with matching hashes and returns the matches

.PARAMETER Directory
Specifies the starting directory to start searching for the hashes

.PARAMETER Hash
Specifies what hash to search for

.EXAMPLE
Find-Hash -Directory "C:\users\SomeUser\" -Hash "3b37902966082536964efdd8cf51ff5f"

.EXAMPLE
Find-Hash -Directory "C:\" -Hash "3b37902966082536964efdd8cf51ff5f" "7c678ef59b6a6addae22cffcfaf1dbaf" "821fa74b50ba3f7cba1e6c53e8fa6845"

#>

function Find-Hash{

    param (
        $Directory
    )
    Write-Output $Directory
    param (
        $Hash
    )
    Write-Output $Hash

}