function Get-GroupNestedGroup {
    param (
        [Parameter(Mandatory = $false)]
        [string]$group,
        [Parameter(Mandatory = $false)]
        [bool]$silent = $false,
        [Parameter(Mandatory = $false)]
        [string]$outputFile = $null,
        [Parameter(Mandatory = $false)]
        [string]$domain = $null,
        [Parameter(Mandatory = $false)]
        [bool]$noEmptyReport = $false
    )
    
    # =========  Functions ==========
    function GetDomain {
        do {
            $confirm = Read-Host "Is $currentDomain the correct Domain to Search [Y/N]"
            If ($confirm -eq 'N') {
                do {
                    $currentDomain = Read-Host "Enter Domain to Search"
                    try {
                        $domaincheck = ([adsi]::Exists("LDAP://$currentDomain"))
                    }
                    catch {
                    
                    }
                    if (-not $domaincheck) {
                        Write-Host "Domain Entered does not Exsist!"
                    }
                }
                Until ($domaincheck -eq $True)
            }
        }
        Until ($confirm -eq 'Y')
        Return $currentDomain
    }
    function GetGroup ($DefaultDC) {
        do {
            $currentGroup = Read-Host "Enter group to Search"
            $groupcheck = ""
            try {
                $groupcheck = get-adgroup -Server $DefaultDC -Identity $currentGroup
            }
            catch {
            
            }
            if ($groupcheck -eq "") {
                Write-Host "Group Entered does not Exsist!"
            }
        }
        Until ($groupcheck -ne "")
        return $currentGroup
    }
    function Get-ADNestedGroupMembers { 
        <#  
        .SYNOPSIS
        Function is from TechNet.  Function has been edited by Micah Wallace to suit my needs.
        Author: Piotr Lewandowski
        Version: 1.01 (04.08.2015) - added displayname to the output, changed name to samaccountname in case of user objects.
        https://gallery.technet.microsoft.com/scriptcenter/Get-nested-group-15f725f2#content

        .DESCRIPTION
        Get nested group membership from a given group or a number of groups.

        Function enumerates members of a given AD group recursively along with nesting level and parent group information. 
        It also displays if each user account is enabled. 
        When used with an -indent switch, it will display only names, but in a more user-friendly way (sort of a tree view) 
                    
        .EXAMPLE             
        Get-ADNestedGroupMembers "MyGroup" -indent
        #>

        param ( 
            [Parameter(ValuefromPipeline = $true, mandatory = $true)][String] $GroupName, 
            [Parameter(ValuefromPipeline = $true, mandatory = $false)][String] $DefaultDC,
            [Parameter(ValuefromPipeline = $true, mandatory = $false)][String] $currentDomain,
            [int] $nesting = -1, 
            [int]$circular = $null, 
            [switch]$indent 
        ) 
        function indent { 
            Param($list) 
            foreach ($line in $list) { 
                $space = $null 
         
                for ($i = 0; $i -lt $line.nesting; $i++) { 
                    $space += "    " 
                } 
                $line.name = "$space" + "$($line.name)"
            } 
            return $List
        }
        function outputcontent ($content) {
            $output = $null
            $name = $content.name
            if ($content.displayname -ne "") { $displayname = " - " + $content.displayname }
            else { $displayname = "" }
            if ($content.type -eq "user") {
                if ($content.enabled) { $enabled = " - Enabled" }
                elseif (!$content.enabled) { $enabled = " - Disabled" }
                else { $enabled = "" }
            }
            $dn = $content.dn
            $output = $name + $displayname + $enabled + " - " + $dn
            Write-Host $output
            return $output
        }
        $modules = get-module | Select-Object -expand name
        if ($modules -contains "ActiveDirectory") { 
            $table = $null 
            $nestedmembers = $null 
            $adgroupname = $null     
            $nesting++
            ########################
            try {
                $ADGroupname = Get-ADGroup -Server $DefaultDC -Identity $GroupName -properties memberof, members
            }
            catch {
                try {
                    $DN = $nestedmember.distinguishedName
                    $pattern = '(?<=DC=)\w{1,}?\b'
                    $tempDomain = ([RegEx]::Matches($DN, $pattern) | ForEach-Object { $_.Value }) -join '.'
                    if ($tempDomain -eq $currentDomain) {
                        #$nestedADMember = get-aduser -Server $DefaultDC -Identity $nestedmember -properties enabled,displayname
                        $ADGroupname = Get-ADGroup -Server $DefaultDC -Identity $GroupName -properties memberof, members
                    }
                    elseif ($tempDomain -ne $currentDomain) {
                        # Get domain controller in that domain.
                        $server = ((Get-ADDomainController -Discover -DomainName $tempDomain).Hostname | out-string).Trim()
                        # Get AD Group info.
                        #$nestedADMember = Get-ADUser -Server $server -Identity $nestedmember -Properties enabled,displayname
                        $ADGroupname = Get-ADGroup -Server $server -Identity $GroupName -properties memberof, members
                        write-error "Unable to query Detailed LDAP info for $ADGroupname on $DefaultDC.  Queried $server instead for info." -ErrorAction:SilentlyContinue
                    }
                }
                catch {
                    Write-Output "ERROR: $PSItem"
                }
            }
            #############
            #$ADGroupname = get-adgroup -Server $DefaultDC -Identity $groupname -properties memberof,members 
            ##############
            $memberof = $adgroupname | Select-Object -expand memberof 
            write-verbose "Checking group: $($adgroupname.name)" 
            if ($adgroupname) {  
                if ($circular) { 
                    $nestedMembers = Get-ADGroupMember -Server $DefaultDC -Identity $GroupName -recursive 
                    $circular = $null 
                } 
                else { 
                    ###########################################
                    try {
                        $nestedMembers = Get-ADGroupMember -Server $DefaultDC -Identity $GroupName | Sort-Object objectclass -Descending
                    }
                    catch {
                        try {
                            $DN = $nestedmember.distinguishedName
                            $pattern = '(?<=DC=)\w{1,}?\b'
                            $tempDomain = ([RegEx]::Matches($DN, $pattern) | ForEach-Object { $_.Value }) -join '.'
                            if ($tempDomain -eq $currentDomain) {
                                #$nestedADMember = get-aduser -Server $DefaultDC -Identity $nestedmember -properties enabled,displayname
                                $nestedMembers = Get-ADGroupMember -Server $DefaultDC -Identity $GroupName | Sort-Object objectclass -Descending
                            }
                            elseif ($tempDomain -ne $currentDomain) {
                                # Get domain controller in that domain.
                                $server = ((Get-ADDomainController -Discover -DomainName $tempDomain).Hostname | out-string).Trim()
                                # Get AD Group info.
                                #$nestedADMember = Get-ADUser -Server $server -Identity $nestedmember -Properties enabled,displayname
                                $nestedMembers = Get-ADGroupMember -Server $server -Identity $GroupName | Sort-Object objectclass -Descending
                                write-error "Unable to query Detailed LDAP info for $Groupname on $DefaultDC.  Queried $server instead for info." -ErrorAction:SilentlyContinue
                            }
                        }
                        catch {
                            #Look here at server error info
                            #Write-Output "ERROR: $PSItem"
                        }
                    }
                    ###########################################
                    #$nestedMembers = Get-ADGroupMember -Server $DefaultDC -Identity $GroupName | sort objectclass -Descending
                    ##################
                    if (!($nestedmembers)) {
                        $unknown = $ADGroupname | Select-Object -expand members
                        if ($unknown) {
                            $nestedmembers = @()
                            foreach ($member in $unknown) {
                                ###############
                                try {
                                    $nestedmembers += get-adobject -Server $DefaultDC -Identity $member
                                    #a referral was returned from the server?
                                }
                                catch {
                                    try {
                                        $DN = $member
                                        #$DN = $nestedmember.distinguishedName
                                        $pattern = '(?<=DC=)\w{1,}?\b'
                                        $tempDomain = ([RegEx]::Matches($DN, $pattern) | ForEach-Object { $_.Value }) -join '.'
                                        if ($tempDomain -eq $currentDomain) {
                                            #$nestedADMember = get-aduser -Server $DefaultDC -Identity $nestedmember -properties enabled,displayname
                                            $nestedmembers += get-adobject -Server $DefaultDC -Identity $member
                                        }
                                        elseif ($tempDomain -ne $currentDomain) {
                                            # Get domain controller in that domain.
                                            $server = ((Get-ADDomainController -Discover -DomainName $tempDomain).Hostname | out-string).Trim()
                                            # Get AD Group info.
                                            #$nestedADMember = Get-ADUser -Server $server -Identity $nestedmember -Properties enabled,displayname
                                            $nestedmembers += get-adobject -Server $server -Identity $member
                                            write-error "Unable to query Detailed LDAP info for $member on $DefaultDC.  Queried $server instead for info." -ErrorAction:SilentlyContinue
                                        }
                                    }
                                    catch {
                                        Write-Output "ERROR: $PSItem"
                                    }
                                }
                                ##############
                                #$nestedmembers += get-adobject -Server $DefaultDC -Identity $member
                                #############
                            }
                        }
                    }
                } 
 
                foreach ($nestedmember in $nestedmembers) { 
                    $Props = @{Type = $nestedmember.objectclass; Name = $nestedmember.name; DisplayName = ""; ParentGroup = $ADgroupname.name; Enabled = ""; Nesting = $nesting; DN = $nestedmember.distinguishedname; Comment = "" } 
                 
                    if ($nestedmember.objectclass -eq "user") { 
                        try {
                            $DN = $nestedmember.distinguishedName
                            $pattern = '(?<=DC=)\w{1,}?\b'
                            $tempDomain = ([RegEx]::Matches($DN, $pattern) | ForEach-Object { $_.Value }) -join '.'
                            if ($tempDomain -eq $currentDomain) {
                                $nestedADMember = get-aduser -Server $DefaultDC -Identity $nestedmember -properties enabled, displayname
                            }
                            elseif ($tempDomain -ne $currentDomain) {
                                # Get domain controller in that domain.
                                $server = ((Get-ADDomainController -Discover -DomainName $tempDomain).Hostname | out-string).Trim()
                                # Get AD User info.
                                $nestedADMember = Get-ADUser -Server $server -Identity $nestedmember -Properties enabled, displayname
                                write-error "Unable to query Detailed LDAP info for $nestedmember on $DefaultDC.  Queried $server instead for info." -ErrorAction:SilentlyContinue
                            }
                        }
                        catch {
                            Write-Output "ERROR: $PSItem"
                        }
                        $table = new-object psobject -property $props 
                        $table.enabled = $nestedadmember.enabled
                        $table.name = $nestedadmember.samaccountname
                        $table.displayname = $nestedadmember.displayname
                        if ($indent) { 
                            indent $table | Select-Object name, displayname | ForEach-Object {
                                outputcontent ($table | Select-Object type, name, displayname, parentgroup, nesting, enabled, dn, comment)
                            }
                        } 
                        else { 
                            outputcontent ($table | Select-Object type, name, displayname, parentgroup, nesting, enabled, dn, comment) # This outputs a Users info to the output content function
                        } 
                    } 
                    elseif ($nestedmember.objectclass -eq "group") {  
                        $table = new-object psobject -Property $props 
                     
                        if ($memberof -contains $nestedmember.distinguishedname) { 
                            $table.comment = "Circular Membership" 
                            $circular = 1 
                        } 
                        if ($indent) { 
                            indent $table | Select-Object name, comment | ForEach-Object {
						
                                if ($_.comment -eq "Circular Membership") {
                                    $table.name = "(Circular Membership) $($_.name)"
                                    outputcontent ($table | Select-Object type, name, displayname, parentgroup, nesting, enabled, dn, comment)
                                    #write-output "$($_.name) (Circular Membership)"
                                }
                                else {
                                    outputcontent ($table | Select-Object type, name, displayname, parentgroup, nesting, enabled, dn, comment)
                                    #write-output "$($_.name)"
                                }
                            }
                        }
                        else { 
                            #$table | select type,name,displayname,parentgroup,nesting,enabled,dn,comment #This Exports Group Data!
                            outputcontent ($table | Select-Object type, name, displayname, parentgroup, nesting, enabled, dn, comment) #Send Group Data to Output content function
                        } 
                        if ($indent) { 
                            Get-ADNestedGroupMembers -GroupName $nestedmember.distinguishedName -nesting $nesting -circular $circular -indent 
                        } 
                        else { 
                            Get-ADNestedGroupMembers -GroupName $nestedmember.distinguishedName -nesting $nesting -circular $circular 
                        } 
              	                  
                    } 
                    else { 
                    
                        if ($nestedmember) {
                            $table = new-object psobject -property $props
                            if ($indent) { 
                                indent $table | Select-Object name | ForEach-Object {
                                    outputcontent ($table | Select-Object type, name, displayname, parentgroup, nesting, enabled, dn, comment)
                                }
                            } 
                            else { 
                                $table | Select-Object type, name, displayname, parentgroup, nesting, enabled, dn, comment    
                                outputcontent ($table | Select-Object type, name, displayname, parentgroup, nesting, enabled, dn, comment)
                            } 
                        }
                    } 
              
                } 
            } 
        } 
        else { Write-Warning "Active Directory module is not loaded.  Please run from a computer that has Remote Server Admin Tools or a Server with the Powershell Active Directroy Module." }        
    }


    ########## MAIN ##########
    #Clear-Host
    $error.clear()
    if ($quiet -eq $false) {
        Write-Host "AD Nested Groups Report Builder"
    }
    Import-Module activedirectory
    $DateTime = Get-Date
    $Hostname = Hostname
    $user = whoami
    $currentDomain = $null
    $DefaultDC = $null
    $emptyReport = $true

    # Get Group to search and confirm it exists.
    if ($group) {
        $searchGroup = $group
        try {
            if ($domain) {
                $DC = Get-ADDomainController -Discover -Domain $domain | Select-Object -ExpandProperty hostname
            }
            else {
                $domain = Get-DomainOfGroup -GroupName $searchGroup
                $DC = Get-ADDomainController -Discover -Domain $domain | Select-Object -ExpandProperty hostname
            }
            #$domain = Get-DomainOfGroup -GroupName $searchGroup
            #$DC = Get-ADDomainController -Discover -Domain $domain | Select-Object -ExpandProperty hostname
            $groupCheck = Get-ADGroup $searchGroup -Server $DC -properties members
            $members = $groupCheck | Select-Object -expand members
            if ($members) {
                $emptyReport = $false
            }
            else {
                $emptyReport = $true
            }
            $currentDomain = $domain
            $DefaultDC = $DC
            if ($silent -eq $false) {
                Write-Host "Valid Group"
            }
        }
        catch {
            Write-Host "Group Entered does not Exsist!"
            continue
        }
    }
    else {
        do {
            $searchGroup = Read-Host "Enter Group to Search"
            $groupCheck = ""
            try {
                $domain = Get-DomainOfGroup -Groupname $searchGroup
                $DC = Get-ADDomainController -Discover -Domain $domain | Select-Object -ExpandProperty hostname
                $GroupCheck = Get-ADGroup $searchGroup -Server $DC
                $currentDomain = $domain
                $DefaultDC = $DC
                Write-Host "Valid Group"
            }
            catch {
                Continue
            }
            if ($GroupCheck -eq "") {
                Write-Host "Group Entered does not Exsist!"
            }
        }
        Until ($groupCheck -ne "")
    }

    
    if ($outputFile) {
        $outputFile = $outputFile
    }
    else {
        Write-Host "Opening File Save Dialog Box..."

        # Set Save Location
        $fileDate = (Get-Date).ToString("yyyyMMdd_HHmmss")
        $filename = "ADNestedGroupMembers_" + $searchGroup + "_" + $currentDomain + "_$fileDate" # Default file name
        $outputFile = Get-FileSaveLocation -name $filename -type ".txt"
    }
    

    # Clear out any errors before building report
    $error.clear()

    # Header Information
    $Header = @()
    $Header += " AD Nested Group Members Report"
    $Header += " "
    $Header += "Report run by $user"
    $Header += "Report run from $Hostname"
    $Header += "Report run at $DateTime"
    $Header += "Queried AD Group: $searchGroup"
    $Header += "Queried Domain: $currentDomain"
    $Header += "Queried Domain Controller: $DefaultDC"
    $Header += " "

    $Header = $Header | Out-String

    # Body
    $Body = @()
    $Body += " ================================ "
    $Body += " "
    $Body += "Users are displayed in the following format"
    $Body += "Username - Display Name - Enabled (or disabled) - Domain Path"
    $Body += ""
    $Body += Get-ADNestedGroupMembers $SearchGroup $DefaultDC $currentDomain -indent
    $Body += " "

    # Error Information
    $errorinfo = @()
    $errorinfo += "======================================================================="
    $errorinfo += "Script Encountered $($error.count) Exceptions"
    $errorinfo += " ================================ "
    $errorinfo += $error.Exception
    $errorinfo += ""

    # Footer Infomation (Written by Micah Wallace)
    $footer = @()
    $footer += "======================================================================="
    $footer += "Automation Script written by Micah Wallace. ADManager Module"

    $footer = $footer | Out-String

    $Report = @()
    $Report += $Header
    $Report += $Body
    $Report += $errorinfo
    $Report += $footer

    # Output Report to File
    if ($noEmptyReport -eq $true -and $emptyReport -eq $true) {
        Write-Host "No users or gropus found for $searchGroup"
        continue
    }
    else {
        $Report | Out-File $outputFile
    }
    
    if ($silent -eq $false) {
        Clear-Host
        # Ask if user wants to open saved file
        Write-Host "Report Generated and Saved to $outputFile"
        $openfile = Read-Host "Do you want to open the file? [Y/N]"
        if ($openfile -eq "Y") {
            Invoke-item -path $outputFile
        }
    }
}