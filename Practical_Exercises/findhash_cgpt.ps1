<# 
.SYNOPSIS
Identifies files in a given directory and its subdirectories that match one or more MD5 hashes.

.DESCRIPTION
This script hashes each individual file in a given directory and its subdirectories and compares each hash against a list of known MD5 hashes. It sends to standard output the name, with full file path, of any matching files.

.PARAMETER Directory
Specifies the directory to search for files. Default value is "C:\Windows\System32".

.PARAMETER Hash
Specifies the MD5 hash value(s) to compare against.

.EXAMPLE
.\Get-MatchingFiles.ps1 -Directory "C:\MyFiles" -Hash "d41d8cd98f00b204e9800998ecf8427e"
Searches for files in "C:\MyFiles" that match the specified MD5 hash value.

.EXAMPLE
.\Get-MatchingFiles.ps1 -Directory "C:\MyFiles","D:\OtherFiles" -Hash "d41d8cd98f00b204e9800998ecf8427e","cfcd208495d565ef66e7dff9f98764da"
Searches for files in "C:\MyFiles" and "D:\OtherFiles" that match the specified MD5 hash values.

#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false, ValueFromPipeline=$true)]
    [string[]]$Directory = "C:\Windows\System32",
    [Parameter(Mandatory=$true)]
    [string[]]$Hash
)

$ErrorActionPreference = "SilentlyContinue"

$files = Get-ChildItem -Path $Directory -Recurse -File
foreach ($file in $files) {
    $hash = Get-FileHash $file.FullName -Algorithm MD5
    if ($hash.Hash -in $Hash) {
        Write-Output $file.FullName
    }
}