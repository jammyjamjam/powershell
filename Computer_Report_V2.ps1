#Common Variables
#Get Current Date
$date = ((Get-Date -Format u).Replace(":", "_")).Replace(" ", "-")
Function Export-Excel {
    #requires -Version 2
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [System.Management.Automation.PSObject]$InputObject,
        [Parameter(Mandatory = $true, Position = 0)]
        [Alias('PSPath', 'FilePath')]
        [System.String]$Path,
        [Switch]$NoClobber,
        [Switch]$Force,
        [Switch]$NoHeader,
        [Switch]$Append,
        [String]$WorkSheetName
    )	
    Begin {
        $Null = [Reflection.Assembly]::LoadWithPartialName("WindowsBase")
        $AssemblyLoaded = $False
        ForEach ($asm in [AppDomain]::CurrentDomain.GetAssemblies()) {
            If ($asm.GetName().Name -eq 'WindowsBase') { $AssemblyLoaded = $True }
        }
        If (-not $AssemblyLoaded) {
            $message = "Could not load 'WindowsBase.dll' assembly from .NET Framework 3.0!"
            $exception = New-Object System.IO.FileNotFoundException $message
            $errorID = 'AssemblyFileNotFound'
            $errorCategory = [Management.Automation.ErrorCategory]::NotInstalled
            $target = 'C:\Program Files\Reference Assemblies\Microsoft\Framework\v3.0\WindowsBase.dll'
            $errorRecord = New-Object Management.Automation.ErrorRecord $exception, $errorID, $errorCategory, $target
            $PSCmdlet.ThrowTerminatingError($errorRecord)
            return
        }
        Function Test-FileLocked {
            param(
                [Parameter(Mandatory = $True,
                    Position = 0,
                    ValueFromPipeline = $True,
                    ValueFromPipelinebyPropertyName = $True
                )]
                [String]$Path,
                [System.IO.FileAccess]$FileAccessMode = [System.IO.FileAccess]::Read,
                [Switch]$PassThru)
            If (Test-Path $Path) { $FileInfo = Get-Item $Path } 
            Else { Return $False }
            try { $Stream = $FileInfo.Open([System.IO.FileMode]::Open, $FileAccessMode, [System.IO.FileShare]::None) }
            catch [System.IO.IOException] {
                If ($PassThru.IsPresent) {             
                    $exception = $_.Exception
                    $errorID = 'FileIsLocked'
                    $errorCategory = [Management.Automation.ErrorCategory]::OpenError
                    $target = $Path
                    $errorRecord = New-Object Management.Automation.ErrorRecord $exception, $errorID, $errorCategory, $target
                    Return $errorRecord
                } 
                Else { Return $True }
            }
            finally { if ($stream) { $stream.Close() } }
            If ($PassThru.IsPresent) { Return $Null } 
            Else { $False }
        }
        Function Add-XLSXWorkSheet {                        
            [CmdletBinding()]
            param([Parameter(Mandatory = $True,
                    Position = 0,
                    ValueFromPipeline = $True,
                    ValueFromPipelinebyPropertyName = $True)]
                [String]$Path,
                [String]$Name)
            Begin {
                $New_Worksheet_xml = New-Object System.Xml.XmlDocument
                $XmlDeclaration = $New_Worksheet_xml.CreateXmlDeclaration("1.0", "UTF-8", "yes")
                $Null = $New_Worksheet_xml.InsertBefore($XmlDeclaration, $New_Worksheet_xml.DocumentElement)
                $workSheetElement = $New_Worksheet_xml.CreateElement("worksheet")
                $Null = $workSheetElement.SetAttribute("xmlns", "http://schemas.openxmlformats.org/spreadsheetml/2006/main")
                $Null = $workSheetElement.SetAttribute("xmlns:r", "http://schemas.openxmlformats.org/officeDocument/2006/relationships")
                $Null = $New_Worksheet_xml.AppendChild($workSheetElement)
                $Null = $New_Worksheet_xml.DocumentElement.AppendChild($New_Worksheet_xml.CreateElement("sheetData"))
            }
            Process {
                If ($ErrorRecord = Test-FileLocked 'D:\temp\PSExcel.xlsx' -PassThru) {
                    $PSCmdlet.WriteError($ErrorRecord)
                    return
                }
                Try {
                    $Null = Get-Item -Path $Path -ErrorAction stop
                }
                Catch {
                    $Error.RemoveAt(0)
                    $NewError = New-Object System.Management.Automation.ErrorRecord -ArgumentList $_.Exception, $_.FullyQualifiedErrorId, $_.CategoryInfo.Category, $_.TargetObject
                    $PSCmdlet.WriteError($NewError)
                    Return
                }
                Try {
                    $exPkg = [System.IO.Packaging.Package]::Open($Path, [System.IO.FileMode]::Open)
                }
                catch {
                    $_
                    Return
                }
                ForEach ($Part in $exPkg.GetParts()) {
                    IF ($Part.ContentType -eq "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml" -or $Part.Uri.OriginalString -eq "/xl/workbook.xml") {
                        $WorkBookPart = $Part
                        break
                    }
                }
                If (-not $WorkBookPart) {
                    Write-Error "Excel Workbook not found in : $Path"
                    $exPkg.Close()
                    return
                }
                $WorkBookRels = $WorkBookPart.GetRelationships()
                $WorkBookRelIds = [System.Collections.ArrayList]@()
                $WorkSheetPartNames = [System.Collections.ArrayList]@()
                ForEach ($Rel in $WorkBookRels) {
                    $Null = $WorkBookRelIds.Add($Rel.ID)
                    If ($Rel.RelationshipType -like '*worksheet*' ) {
                        $WorkSheetName = Split-Path $Rel.TargetUri.ToString() -Leaf
                        $Null = $WorkSheetPartNames.Add($WorkSheetName)
                    }
                }
                $IdCounter = 0
                $NewWorkBookRelId = ''
                Do {
                    $IdCounter++
                    If (-not ($WorkBookRelIds -contains "rId$IdCounter")) {
                        $NewWorkBookRelId = "rId$IdCounter"
                    }
                } while ($NewWorkBookRelId -eq '')
                $WorksheetCounter = 0
                $NewWorkSheetPartName = ''
                Do {
                    $WorksheetCounter++
                    If (-not ($WorkSheetPartNames -contains "sheet$WorksheetCounter.xml")) {
                        $NewWorkSheetPartName = "sheet$WorksheetCounter.xml"
                    }
                } while ($NewWorkSheetPartName -eq '')
                $WorkbookWorksheetNames = [System.Collections.ArrayList]@()
                $WorkBookXmlDoc = New-Object System.Xml.XmlDocument
                $WorkBookXmlDoc.Load($WorkBookPart.GetStream([System.IO.FileMode]::Open, [System.IO.FileAccess]::Read))
                ForEach ($Element in $WorkBookXmlDoc.documentElement.Item("sheets").get_ChildNodes()) {
                    $Null = $WorkbookWorksheetNames.Add($Element.Name)
                }
                $DuplicateName = ''
                If (-not [String]::IsNullOrEmpty($Name)) {
                    If ($WorkbookWorksheetNames -Contains $Name) {
                        $DuplicateName = $Name
                        $Name = ''
                    }
                } 
                If ([String]::IsNullOrEmpty($Name)) {
                    $WorkSheetNameCounter = 0
                    $Name = "Table$WorkSheetNameCounter"
                    While ($WorkbookWorksheetNames -Contains $Name) {
                        $WorkSheetNameCounter++
                        $Name = "Table$WorkSheetNameCounter"
                    }
                    If (-not [String]::IsNullOrEmpty($DuplicateName)) {
                        Write-Warning "Worksheetname '$DuplicateName' allready exist!`nUsing automatically generated name: $Name"
                    }
                }
                $Uri_xl_worksheets_sheet_xml = New-Object System.Uri -ArgumentList ("/xl/worksheets/$NewWorkSheetPartName", [System.UriKind]::Relative)
                $Part_xl_worksheets_sheet_xml = $exPkg.CreatePart($Uri_xl_worksheets_sheet_xml, "application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml")
                $dest = $part_xl_worksheets_sheet_xml.GetStream([System.IO.FileMode]::Create, [System.IO.FileAccess]::Write)
                $New_Worksheet_xml.Save($dest)
                $Null = $WorkBookPart.CreateRelationship($Uri_xl_worksheets_sheet_xml, [System.IO.Packaging.TargetMode]::Internal, "http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet", $NewWorkBookRelId)
                $WorkBookXmlDoc = New-Object System.Xml.XmlDocument
                $WorkBookXmlDoc.Load($WorkBookPart.GetStream([System.IO.FileMode]::Open, [System.IO.FileAccess]::Read))
                $WorkBookXmlSheetNode = $WorkBookXmlDoc.CreateElement('sheet', $WorkBookXmlDoc.DocumentElement.NamespaceURI)
                $Null = $WorkBookXmlSheetNode.SetAttribute('name', $Name)
                $Null = $WorkBookXmlSheetNode.SetAttribute('sheetId', $IdCounter)
                $NamespaceR = $WorkBookXmlDoc.DocumentElement.GetNamespaceOfPrefix("r")
                If ($NamespaceR) {
                    $Null = $WorkBookXmlSheetNode.SetAttribute('id', $NamespaceR, $NewWorkBookRelId)
                }
                Else { $Null = $WorkBookXmlSheetNode.SetAttribute('id', $NewWorkBookRelId) }
                $Null = $WorkBookXmlDoc.DocumentElement.Item("sheets").AppendChild($WorkBookXmlSheetNode)
                $WorkBookXmlDoc.Save($WorkBookPart.GetStream([System.IO.FileMode]::Open, [System.IO.FileAccess]::Write))
                $exPkg.Close()
                New-Object -TypeName PsObject -Property @{Uri = $Uri_xl_worksheets_sheet_xml; WorkbookRelationID = $NewWorkBookRelId; Name = $Name; WorkbookPath = $Path }
            } 
            End {}
        }
    
        Function New-XLSXWorkBook {        
            param(
                [Parameter(Mandatory = $True,
                    Position = 0,
                    ValueFromPipeline = $True,
                    ValueFromPipelinebyPropertyName = $True
                )]
                [String]$Path,
                [ValidateNotNull()]
                [Switch]$NoClobber,
                [Switch]$Force
            )
            Begin {
                $xl_Workbook_xml = New-Object System.Xml.XmlDocument
                $XmlDeclaration = $xl_Workbook_xml.CreateXmlDeclaration("1.0", "UTF-8", "yes")
                $Null = $xl_Workbook_xml.InsertBefore($XmlDeclaration, $xl_Workbook_xml.DocumentElement)
                $workBookElement = $xl_Workbook_xml.CreateElement("workbook")
                $Null = $workBookElement.SetAttribute("xmlns", "http://schemas.openxmlformats.org/spreadsheetml/2006/main")
                $Null = $workBookElement.SetAttribute("xmlns:r", "http://schemas.openxmlformats.org/officeDocument/2006/relationships")
                $Null = $xl_Workbook_xml.AppendChild($workBookElement)
                $Null = $xl_Workbook_xml.DocumentElement.AppendChild($xl_Workbook_xml.CreateElement("sheets"))
            }
            Process {
                $Path = [System.IO.Path]::ChangeExtension($Path, 'xlsx')
                Try {
                    Out-File -InputObject "" -FilePath $Path -NoClobber:$NoClobber.IsPresent -Force:$Force.IsPresent -ErrorAction stop
                    Remove-Item $Path -Force
                }
                Catch {
                    $Error.RemoveAt(0)
                    $NewError = New-Object System.Management.Automation.ErrorRecord -ArgumentList $_.Exception, $_.FullyQualifiedErrorId, $_.CategoryInfo.Category, $_.TargetObject
                    $PSCmdlet.WriteError($NewError)
                    Return
                }
                Try { $exPkg = [System.IO.Packaging.Package]::Open($Path, [System.IO.FileMode]::Create) } 
                Catch {
                    $_
                    return
                }
                $Uri_xl_workbook_xml = New-Object System.Uri -ArgumentList ("/xl/workbook.xml", [System.UriKind]::Relative)
                $Part_xl_workbook_xml = $exPkg.CreatePart($Uri_xl_workbook_xml, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml")
                $dest = $part_xl_workbook_xml.GetStream([System.IO.FileMode]::Create, [System.IO.FileAccess]::Write)
                $xl_workbook_xml.Save($dest)
                $Null = $exPkg.CreateRelationship($Uri_xl_workbook_xml, [System.IO.Packaging.TargetMode]::Internal, "http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument", "rId1")
                $exPkg.Close()
                Return Get-Item $Path
            }
            End {}
        }
        Function Export-WorkSheet {
            [CmdletBinding()]
            param(
                [Parameter(Mandatory = $True,
                    Position = 0,
                    ValueFromPipeline = $True,
                    ValueFromPipelinebyPropertyName = $True
                )]
                [System.String]$Path,
                [Parameter(Mandatory = $True,
                    Position = 1,
                    ValueFromPipeline = $True,
                    ValueFromPipelinebyPropertyName = $True
                )]
                [System.Uri]$WorksheetUri,
                [Parameter(Mandatory = $true,
                    Position = 1,
                    ValueFromPipeline = $true,
                    ValueFromPipelineByPropertyName = $true
                )]
                [System.Management.Automation.PSObject]$InputObject,
                [Switch]$NoHeader
            )
            Begin {
                $exPkg = [System.IO.Packaging.Package]::Open($Path, [System.IO.FileMode]::Open)
                $WorkSheetPart = $exPkg.GetPart($WorksheetUri)
                $WorkSheetXmlDoc = New-Object System.Xml.XmlDocument
                $WorkSheetXmlDoc.Load($WorkSheetPart.GetStream([System.IO.FileMode]::Open, [System.IO.FileAccess]::Read))
                $HeaderWritten = $False
            }
            Process {
                If ($InputObject.GetType().Name -match 'byte|short|int32|long|sbyte|ushort|uint32|ulong|float|double|decimal|string') {
                    Add-Member -InputObject $InputObject -MemberType NoteProperty -Name ($InputObject.GetType().Name) -Value $InputObject
                }        
                If ((-not $HeaderWritten) -and (-not $NoHeader.IsPresent) ) {
                    $RowNode = $WorkSheetXmlDoc.CreateElement('row', $WorkSheetXmlDoc.DocumentElement.Item("sheetData").NamespaceURI)
                    ForEach ($Prop in $InputObject.psobject.Properties) {
                        $CellNode = $WorkSheetXmlDoc.CreateElement('c', $WorkSheetXmlDoc.DocumentElement.Item("sheetData").NamespaceURI)
                        $Null = $CellNode.SetAttribute('t', "inlineStr")
                        $Null = $RowNode.AppendChild($CellNode)
                        $CellNodeIs = $WorkSheetXmlDoc.CreateElement('is', $WorkSheetXmlDoc.DocumentElement.Item("sheetData").NamespaceURI)
                        $Null = $CellNode.AppendChild($CellNodeIs)
                        $CellNodeIsT = $WorkSheetXmlDoc.CreateElement('t', $WorkSheetXmlDoc.DocumentElement.Item("sheetData").NamespaceURI)
                        $CellNodeIsT.InnerText = [String]$Prop.Name
                        $Null = $CellNodeIs.AppendChild($CellNodeIsT)
                        $Null = $WorkSheetXmlDoc.DocumentElement.Item("sheetData").AppendChild($RowNode)	
                    }$HeaderWritten = $True
                }
                $RowNode = $WorkSheetXmlDoc.CreateElement('row', $WorkSheetXmlDoc.DocumentElement.Item("sheetData").NamespaceURI)
                ForEach ($Prop in $InputObject.psobject.Properties) {
                    $CellNode = $WorkSheetXmlDoc.CreateElement('c', $WorkSheetXmlDoc.DocumentElement.Item("sheetData").NamespaceURI)
                    $Null = $CellNode.SetAttribute('t', "inlineStr")
                    $Null = $RowNode.AppendChild($CellNode)
                    $CellNodeIs = $WorkSheetXmlDoc.CreateElement('is', $WorkSheetXmlDoc.DocumentElement.Item("sheetData").NamespaceURI)
                    $Null = $CellNode.AppendChild($CellNodeIs)
                    $CellNodeIsT = $WorkSheetXmlDoc.CreateElement('t', $WorkSheetXmlDoc.DocumentElement.Item("sheetData").NamespaceURI)
                    $CellNodeIsT.InnerText = [String]$Prop.Value
                    $Null = $CellNodeIs.AppendChild($CellNodeIsT)
                    $Null = $WorkSheetXmlDoc.DocumentElement.Item("sheetData").AppendChild($RowNode)
                }
            }
            End {
                $WorkSheetXmlDoc.Save($WorkSheetPart.GetStream([System.IO.FileMode]::Open, [System.IO.FileAccess]::Write))
                $exPkg.Close()
            }
        }
        $Path = [System.IO.Path]::GetFullPath($Path)
        $Path = [System.IO.Path]::ChangeExtension($Path, 'xlsx')
        If ((Test-Path $Path) -and $Append.IsPresent ) { $WorkSheet = Add-XLSXWorkSheet -Name $WorkSheetName -Path $Path } 
        Else {
            Try {
                Out-File -InputObject "" -FilePath $Path -NoClobber:$NoClobber.IsPresent -Force:$Force.IsPresent -ErrorAction stop
                Remove-Item $Path -Force
            }
            Catch {
                $Error.RemoveAt(0)
                $NewError = New-Object System.Management.Automation.ErrorRecord -ArgumentList $_.Exception, $_.FullyQualifiedErrorId, $_.CategoryInfo.Category, $_.TargetObject
                $PSCmdlet.WriteError($NewError)
                Return
            }
            $Null = New-XLSXWorkBook -Path $Path -Force:$Force.IsPresent -NoClobber:$NoClobber.IsPresent
            $WorkSheet = Add-XLSXWorkSheet -Name $WorkSheetName -Path $Path
        }
        $HeaderWritten = $False
    }
    Process {
        Export-WorkSheet -InputObject $InputObject -NoHeader:($NoHeader.IsPresent -or $HeaderWritten) -Path $Path -WorksheetUri $WorkSheet.Uri
        $HeaderWritten = $True
    }
    End {}
}
function Show-Menu {
    param (
        [string]$Title = 'Enumerate Windows'
    )
    Clear-Host
    Write-Host "================ Enumerate Windows ================"
    Write-Host "1: Press '1' to pull Local Computer Report"
    Write-Host "2: Press '2' to pull Remote Computer Report"
    Write-Host "Q: Press 'Q' to quit."
}
#
do {
    Show-Menu
    $input = Read-Host "Please make a selection"
    switch ($input) {
        '1' {
            #Common Variables
            #Local Hostnames
            $ahostname = "HostName = $env:COMPUTERNAME"
            #Export Path
            $exportname = $ahostname + "_" + $date
            $exportlocation = Read-Host "Input Export Destination"
            $exportpath = "$exportlocation\Machine_Pull_$exportname.xlsx"
            #Maps to Local ADSI
            $adsi = [ADSI]"WinNT://$env:COMPUTERNAME"
            ################
            ################
            #Local Machine Groups
            ################
            $alocalgroups = "Local Groups"
            $localgroups = Get-LocalGroup | Sort-Object -Property Name | Select-Object -Property Name, Description, SID, PrincipalSource, Objectclass
            $localgroups | Export-Excel -Append -WorkSheetName $alocalgroups -Path $exportpath
            ################
            #Local User Information
            ################
            $alocaluserinfo = "Local User Info"
            $localuserinformation = Get-WmiObject -Class Win32_UserAccount | Select-Object -Property Name, Domain, Accounttype, SID, Disabled, PasswordExpires | Sort-Object -Property Name
            $localuserinformation | Export-Excel -Append -WorkSheetName $alocaluserinfo -Path $exportpath
            ################
            #Get Users in each group
            ################
            $auseringroups = "Users In Groups"
            $Usersingroups = $adsi.Children | Where-Object { $_.SchemaClassName -eq 'user' } | Foreach-Object { $groups = $_.Groups() | Foreach-Object { $_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null) }
                $_ | Select-Object @{n = 'UserName'; e = { $_.Name } }, @{n = 'Groups'; e = { $groups -join ';' } } }     
            $Usersingroups | Export-Excel -Append -WorkSheetName $auseringroups -Path $exportpath
            ################
            #Get Logged on Users
            ################
            $aloggedonuser = "Logged On Users"
            $loggedonusers = query user /server:$envm:computername
            $loggedonusers | Export-Excel -Append -WorkSheetName $aloggedonuser -Path $exportpath
            ################
            #Get Processes
            ################
            $aprocesses = "Processes"
            $processes = Get-Process -IncludeUserName | Sort-Object -Property Id | Select-Object -Property Name, Id, Path, UserName
            $processes | Export-Excel -Append -WorkSheetName $aprocesses -Path $exportpath
            ################
            #Get List of when a service was installed
            ################
            $aserviceswhen = "Services_Install_Date"
            $servicewhen = Get-EventLog -LogName System | Where-Object { $_.EventID -eq '7045' } | Sort-Object -Property TimeGenerated -Descending | Select-Object -Property TimeGenerated, UserName, Message, MachineName, Index
            $servicewhen | Export-Excel -Append -WorkSheetName $aserviceswhen -Path $exportpath
            ################
            #List of services
            ################
            $aservices = "Services"
            $services = Get-CimInstance -ClassName Win32_Service | Select-Object -Property Name, StartName, ProcessId, PathName, Caption, Description, DisplayName, StartMode, Started, ErrorControl | Sort-Object -Property ProcessId -Descending
            $services | Export-Excel -Append -WorkSheetName $aservices -Path $exportpath
            ################
            #IP Info
            ################
            $anetworkinfo = "IP INFO"
            $networkip = Get-NetIPConfiguration | Select-Object InterfaceAlias, IPv4Address, IPv4DefaultGateway, DNSServer
            $networkip | Export-Excel -Append -WorkSheetName $anetworkinfo -Path $exportpath
            ################
            #MAC Info
            ################
            $anetworkMAC = "MAC Info"
            $networkMAC = Get-NetAdapter | Select-Object -Property Name, MacAddress, MediaConnectionState, Status, DriverInformation, ifDesc, ComponentID, DeviceWakeUpEnable, LinkLayerAddress | Sort-Object -Property Name
            $networkMAC | Export-Excel -Append -WorkSheetName $anetworkMAC -Path $exportpath
            ################
            #Open UDP Connections
            ################
            $audpinfo = "UDP Connections Open"
            $udpinfo = Get-NetUDPEndpoint | Sort-Object -Property OwningProcess | Select-Object -Property CreationTime, OwningProcess, LocalPort, LocalAddress, InstanceID, EnabledDefault, RequestedState
            $udpinfo | Export-Excel -Append -WorkSheetName $audpinfo -Path $exportpath
            ################
            #Open TCP Connections
            ################
            $atcpconnection = "TCP Connections"
            $tcpconnection = Get-NetTCPConnection | Sort-Object OwningProcess | Select-Object -Property OwningProcess, CreationTime, State, LocalPort, LocalAddress, RemoteAddress, RemotePort, OffloadState, InstanceID, EnabledDefault, EnabledState, TransitioningToState
            $tcpconnection | Export-Excel -Append -WorkSheetName $atcpconnection -Path $exportpath
            ################
            #System Information
            ################
            $asysteminfo = "System Info"
            $systeminfo = Get-CimInstance Win32_OperatingSystem | Select-Object -Property * -ExcludeProperty Description, OthertypeDescription, TotalSwapSpaceSize, CSDVersion, Organization, PAEEnabled, PlusProductID, PlusVersionNumber, CIMClass, CimInstanceProperties, CimSystemProperties, PSComputerName, LargeSystemCache
            $systeminfo | Export-Excel -Append -WorkSheetName $asysteminfo -Path $exportpath
            ################
            #Drive Information
            ################
            $adrives = "Drive Information"
            $drives = Get-PSDrive -PSProvider Filesystem | Select-Object -Property *
            $drives | Export-Excel -Append -WorkSheetName $adrives -Path $exportpath
            ################
            #PnP Devices
            ################
            $apnpdevices = "PNP Devices"
            $pnpdevices = Get-PnpDevice | Sort-Object -Property Class | Select-Object -Property * -ExcludeProperty ProblemDescription, InstallDate, Availability, ConfigManagerUserConfig, CreationClassName, ErrorDescription, LastErrorCode, StatusInfo, SystemCreationClassName, SystemName, PSComputerName, CIMClass, CimInstanceProperties, CimSystemProperties
            #-Class Keyboard, SoftwareDevice, DiskDrive, MEDIA, SoftwareDevice, SCSIAdapter, USB, WPD, USBDevice
            $pnpdevices | Export-Excel -Append -WorkSheetName $apnpdevices -Path $exportpath
            ################
            #Shares
            ################
            $ashares = "Share Drives"
            $shares = Get-CimInstance -ClassName Win32_Share | Select-Object Name, Path, Status, Caption, Description, Type, AllowMaximum
            $shares | Export-Excel -Append -WorkSheetName $ashares -Path $exportpath
            ################
            #Schedualed Tasks
            ################
            $ascheduledtasks = "Scheduled Tasks"
            $scheduledtasks = Get-ScheduledTask | Select-Object -Property TaskName, Author, Description, State, Actions, Triggers, Source, Date, Settings, TaskPath, URI, Version, SecurityDescriptor | Sort-Object -Property Author
            $scheduledtasks | Export-Excel -Append -WorkSheetName $ascheduledtasks -Path $exportpath
        }
        '2' {
            #Get hostname
            $hostname = Read-Host "Enter Computername if on domain, or IP Address"
            #Get Credentials
            Write-Host "Enter domain or computer name first then \ then username" -ForegroundColor Green
            $creds = Get-Credential
            #Local Hostnames
            $ahostname = "HostName = $hostname"
            #Export Path
            $exportname = $ahostname + "_" + $date
            $exportlocation = Read-Host "Input Export Destination"
            $exportpath = "$exportlocation\Machine_Pull_$exportname.xlsx"
            ################
            ################
            #Local Machine Groups
            ################
            $alocalgroups = "Local Groups"
            $localgroups = Invoke-Command -ComputerName $hostname -Credential $creds -ScriptBlock { Get-LocalGroup | Sort-Object -Property Name | Select-Object -Property Name, Description, SID, PrincipalSource, Objectclass }
            $localgroups | Export-Excel -Append -WorkSheetName $alocalgroups -Path $exportpath
            ################
            #Local User Information
            ################
            $alocaluserinfo = "Local User Info"
            $localuserinformation = Invoke-Command -ComputerName $hostname -Credential $creds -ScriptBlock { Get-WmiObject -Class Win32_UserAccount | Select-Object -Property Name, Domain, Accounttype, SID, Disabled, PasswordExpires | Sort-Object -Property Name }
            $localuserinformation | Export-Excel -Append -WorkSheetName $alocaluserinfo -Path $exportpath
            ################
            #Get Users in each group
            ################
            $auseringroups = "Users In Groups"
            $Usersingroups = Invoke-Command -ComputerName $hostname -Credential $creds -ScriptBlock { $allgroups = (Get-LocalGroup).Name
                foreach ($eachgroup in $allgroups) { If ($null -eq (Get-LocalGroupMember -Group $eachgroup)) {}else { $eachgroup; Get-LocalGroupMember -group $eachgroup } } }
            $Usersingroups | Export-Excel -Append -WorkSheetName $auseringroups -Path $exportpath
            ################
            #Get Logged on Users
            ################
            try {
                Write-Host "Trying to gather Logged on users Via Invoke Command" -ForegroundColor Yellow
                $loggedonusers = Invoke-Command -ComputerName $hostname -Credential $creds -ScriptBlock { query user /server:$envm:computername } -ErrorAction SilentlyContinue
                if ($null -ne $loggedonusers) {
                    Write-Host "Attained Logged on Users Via Invoke Command" -ForegroundColor Green
                }
                if ($null -eq $loggedonusers) {
                    net start winrm
                    Set-Item WSMan:\localhost\client\TrustedHosts -Value $hostname
                    Write-Host "Failed attaining logged on users via Invoke Command, now trying via CIMInstance" -ForegroundColor Yellow
                    $s = New-CimSession -ComputerName $hostname -Credential $cred
                    $loggedonusers = Get-CimInstance CIM_ComputerSystem -CimSession $s -ErrorAction SilentlyContinue | Select-Object * -ErrorAction SilentlyContinue
                    Write-Host "Attained Logged on users Via CIM Instance" -ForegroundColor Green
                    net stop winrm
                }
            }
            catch { Write-Host "Failed to attain Logged on user information" -ForegroundColor Red }
            $aloggedonuser = "Logged On Users"
            $loggedonusers | Export-Excel -Append -WorkSheetName $aloggedonuser -Path $exportpath
            ################
            #Get Processes
            ################
            $aprocesses = "Processes"
            $processes = Invoke-Command -ComputerName $hostname -Credential $creds -ScriptBlock { Get-Process -IncludeUserName | Sort-Object -Property Id | Select-Object -Property Name, Id, Path, UserName }
            $processes | Export-Excel -Append -WorkSheetName $aprocesses -Path $exportpath
            ################
            #Get List of when a service was installed
            ################
            $aserviceswhen = "Services_Install_Date"
            $servicewhen = Invoke-Command -ComputerName $hostname -Credential $creds -ScriptBlock { Get-EventLog -LogName System | Where-Object { $_.EventID -eq '7045' } | Sort-Object -Property TimeGenerated -Descending | Select-Object -Property TimeGenerated, UserName, Message, MachineName, Index }
            $servicewhen | Export-Excel -Append -WorkSheetName $aserviceswhen -Path $exportpath
            ################
            #List of services
            ################
            $aservices = "Services"
            $services = Invoke-Command -ComputerName $hostname -Credential $creds -ScriptBlock { Get-CimInstance -ClassName Win32_Service | Select-Object -Property Name, StartName, ProcessId, PathName, Caption, Description, DisplayName, StartMode, Started, ErrorControl | Sort-Object -Property ProcessId -Descending }
            $services | Export-Excel -Append -WorkSheetName $aservices -Path $exportpath
            ################
            #IP Info
            ################
            $anetworkinfo = "IP INFO"
            $networkip = Invoke-Command -ComputerName $hostname -Credential $creds -ScriptBlock { Get-NetIPConfiguration | Select-Object InterfaceAlias, IPv4Address, IPv4DefaultGateway, DNSServer }
            $networkip | Export-Excel -Append -WorkSheetName $anetworkinfo -Path $exportpath
            ################
            #MAC Info
            ################
            $anetworkMAC = "MAC Info"
            $networkMAC = Invoke-Command -ComputerName $hostname -Credential $creds -ScriptBlock { Get-NetAdapter | Select-Object -Property Name, MacAddress, MediaConnectionState, Status, DriverInformation, ifDesc, ComponentID, DeviceWakeUpEnable, LinkLayerAddress | Sort-Object -Property Name }
            $networkMAC | Export-Excel -Append -WorkSheetName $anetworkMAC -Path $exportpath
            ################
            #Open UDP Connections
            ################
            $audpinfo = "UDP Connections Open"
            $udpinfo = Invoke-Command -ComputerName $hostname -Credential $creds -ScriptBlock { Get-NetUDPEndpoint | Sort-Object -Property OwningProcess | Select-Object -Property CreationTime, OwningProcess, LocalPort, LocalAddress, InstanceID, EnabledDefault, RequestedState }
            $udpinfo | Export-Excel -Append -WorkSheetName $audpinfo -Path $exportpath
            ################
            #Open TCP Connections
            ################
            $atcpconnection = "TCP Connections"
            $tcpconnection = Invoke-Command -ComputerName $hostname -Credential $creds -ScriptBlock { Get-NetTCPConnection | Sort-Object OwningProcess | Select-Object -Property OwningProcess, CreationTime, State, LocalPort, LocalAddress, RemoteAddress, RemotePort, OffloadState, InstanceID, EnabledDefault, EnabledState, TransitioningToState }
            $tcpconnection | Export-Excel -Append -WorkSheetName $atcpconnection -Path $exportpath
            ################
            #System Information
            ################
            $asysteminfo = "System Info"
            $systeminfo = Invoke-Command -ComputerName $hostname -Credential $creds -ScriptBlock { Get-CimInstance Win32_OperatingSystem | Select-Object -Property * -ExcludeProperty Description, OthertypeDescription, TotalSwapSpaceSize, CSDVersion, Organization, PAEEnabled, PlusProductID, PlusVersionNumber, CIMClass, CimInstanceProperties, CimSystemProperties, PSComputerName, LargeSystemCache }
            $systeminfo | Export-Excel -Append -WorkSheetName $asysteminfo -Path $exportpath
            ################
            #Drive Information
            ################
            $adrives = "Drive Information"
            $drives = Invoke-Command -ComputerName $hostname -Credential $creds -ScriptBlock { Get-PSDrive -PSProvider Filesystem | Select-Object -Property * }
            $drives | Export-Excel -Append -WorkSheetName $adrives -Path $exportpath
            ################
            #PnP Devices
            ################
            $apnpdevices = "PNP Devices"
            $pnpdevices = Invoke-Command -ComputerName $hostname -Credential $creds -ScriptBlock { Get-PnpDevice | Sort-Object -Property Class | Select-Object -Property * -ExcludeProperty ProblemDescription, InstallDate, Availability, ConfigManagerUserConfig, CreationClassName, ErrorDescription, LastErrorCode, StatusInfo, SystemCreationClassName, SystemName, PSComputerName, CIMClass, CimInstanceProperties, CimSystemProperties }
            $pnpdevices | Export-Excel -Append -WorkSheetName $apnpdevices -Path $exportpath
            ################
            #Shares
            ################
            $ashares = "Share Drives"
            $shares = Invoke-Command -ComputerName $hostname -Credential $creds -ScriptBlock { Get-CimInstance -ClassName Win32_Share | Select-Object Name, Path, Status, Caption, Description, Type, AllowMaximum }
            $shares | Export-Excel -Append -WorkSheetName $ashares -Path $exportpath
            ################
            #Scheduled Tasks
            ################
            $ascheduledtasks = "Scheduled Tasks"
            $scheduledtasks = Invoke-Command -ComputerName $hostname -Credential $creds -ScriptBlock { Get-ScheduledTask | Select-Object -Property TaskName, Author, Description, State, Actions, Triggers, Source, Date, Settings, TaskPath, URI, Version, SecurityDescriptor | Sort-Object -Property Author }
            $scheduledtasks | Export-Excel -Append -WorkSheetName $ascheduledtasks -Path $exportpath
        }
    }
}
until ($input -eq 'q')