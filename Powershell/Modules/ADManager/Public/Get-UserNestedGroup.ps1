function Get-UserNestedGroup {
    param (
        [Parameter(Mandatory=$true)]
        [string]$username,

        [Parameter(Mandatory=$false)]
        [bool]$silent = $false,

        [Parameter(Mandatory=$false)]
        [string]$outputFile = $null,

        [Parameter(Mandatory=$false)]
        [string]$domain = $null,
        
        [Parameter(Mandatory=$false)]
        [bool]$noEmptyReport = $false
    )
    <#
    .SYNOPSIS
        Gets all groups and nested groups a user is in.
    .DESCRIPTION
        Looks up the domain the user is in and then finds all groups the member is a memberOf as well as all sub groups and exports to a text document.
        Function can be used on its own and can be automated by passing in the -username attribute.
    .NOTES
        None
    .LINK
        None
    .EXAMPLE
        Get-UserNestedGroup
        This function will ask you to enter a username and then open a window asking where to save the exported text report.
    #>
    
    
    function GetUser ($DefaultDC) {
        do {
            $currentUser = Read-Host "Enter username to Search"
            $usercheck = ""
            try {
                $usercheck = get-adUser -Filter "samAccountName -eq '$currentUser'"
            } catch {
                
            }
            if ($usercheck -eq "") {
                Write-Host "Username Entered does not Exsist!"
            }
        }
        Until ($usercheck -ne "")
        return $currentUser
    }
    function GetADGroup ($group) {
        try {
            $DN = $Group
            $pattern = '(?<=DC=)\w{1,}?\b'
            $tempDomain = ([RegEx]::Matches($DN, $pattern) | ForEach-Object { $_.Value }) -join '.'
            if ($tempDomain -eq $currentDomain) {
                $ADGroupname = get-adgroup -Server $DefaultDC -Identity $group -properties memberof,members
            } elseif ($tempDomain -ne $currentDomain) {
                # Get domain controller in that domain.
                $server = ((Get-ADDomainController -Discover -DomainName $tempDomain).Hostname | out-string).Trim()
                # Get AD User info.
                $ADGroupname = get-adgroup -Server $server -Identity $group -properties memberof,members
            }
        }
        catch {
            Write-Output "ERROR: $PSItem"
        }
        return $ADGroupname
    }
    function Get-ADNestedGroupMembers { 
    param ( 
        [Parameter(ValuefromPipeline=$true,mandatory=$true)][String] $GroupName, 
        [int] $nesting = -1, 
        [int]$circular = $null, 
        [switch]$indent 
    ) 
        function indent  
        { 
        Param($list) 
            foreach($line in $list) 
            { 
            $space = $null 
             
                for ($i=0;$i -lt $line.nesting;$i++) 
                { 
                $space += "    " 
                } 
                $line.name = "$space" + "$($line.name)"
            } 
          return $List
        }
        function outputcontent ($content){
            $output = $null
            $name = $content.name
            if ($content.displayname -ne ""){$displayname = " <-> " + $content.displayname}
                else {$displayname = ""}
            if ($content.enabled){$enabled = " <-> Enabled"}
                else {$enabled = ""}
            $dn = $content.dn
            $output = $name + $displayname + $enabled + " <-> " + $dn
            Write-Host $output
            return $output
        }
    $modules = get-module | Select-Object -expand name
        if ($modules -contains "ActiveDirectory") 
        { 
            $table = $null 
            $nestedmembers = $null 
            $adgroupname = $null     
            $nesting++
            $ADGroupname = GetADGroup ($groupname)
    
            $members = $adgroupname | Select-Object -expand Members
            write-verbose "Checking group: $($adgroupname.name)" 
            #Write-Host "Checking group: $($adgroupname.name)"
            if ($adgroupname) 
            {  
                if ($circular) 
                { 
                    $nestedMembers = Get-ADGroupMember -Server $DefaultDC -Identity $GroupName -recursive 
                    $circular = $null 
                } 
                else 
                { 
                    $nestedMemberOfName = (GetADGroup ($groupname)).memberof
                    $nestedMembers = @()
                    foreach ($member in $nestedMemberOfName) {
                        $nestedMembers += (GetADGroup ($member))
                    }
    
                    $nestedMembers = $nestedmembers | sort-object
                    if (!($nestedmembers))
                    {
                        
                    }
                } 
     
                foreach ($nestedmember in $nestedmembers) 
                { 
                    $Props = @{Type=$nestedmember.objectclass;Name=$nestedmember.name;DisplayName="";ParentGroup=$ADgroupname.name;Enabled="";Nesting=$nesting;DN=$nestedmember.distinguishedname;Comment=""} 
                     
                    if ($nestedmember.objectclass -eq "user") 
                    { 
                        
                    } 
                    elseif ($nestedmember.objectclass -eq "group") 
                    {  
                        $table = new-object psobject -Property $props 
                         
                        # if ($memberof -contains $nestedmember.distinguishedname) 
                        if ($members -contains $nestedmember.distinguishedname)
                        { 
                            $table.comment ="Circular Membership" 
                            $circular = 1 
                        } 
                        if ($indent) 
                        { 
                        indent $table | Select-Object name,comment | ForEach-Object {
                            
                            if ($_.comment -eq "Circular Membership")
                            {
                            $table.name = "(Circular Membership) $($_.name)"
                            outputcontent ($table | Select-Object type,name,displayname,parentgroup,nesting,enabled,dn,comment)
                            #write-output "$($_.name) (Circular Membership)"
                            }
                            else
                            {
                            outputcontent ($table | Select-Object type,name,displayname,parentgroup,nesting,enabled,dn,comment)
                            #write-output "$($_.name)"
                            }
                        }
                        }
                        else 
                        {
                        outputcontent ($table | Select-Object type,name,displayname,parentgroup,nesting,enabled,dn,comment) #Send Group Data to Output content function
                        } 
                        if ($indent) 
                        { 
                           Get-ADNestedGroupMembers -GroupName $nestedmember.distinguishedName -nesting $nesting -circular $circular -indent 
                        } 
                        else  
                        { 
                           Get-ADNestedGroupMembers -GroupName $nestedmember.distinguishedName -nesting $nesting -circular $circular 
                        } 
                                        
                   } 
                    else 
                    { 
                        
                        if ($nestedmember)
                        {
                            $table = new-object psobject -property $props
                            if ($indent) 
                            { 
                                indent $table | Select-Object name | ForEach-Object{
                            outputcontent ($table | Select-Object type,name,displayname,parentgroup,nesting,enabled,dn,comment)
                            }
                            } 
                            else 
                            { 
                            $table | Select-Object type,name,displayname,parentgroup,nesting,enabled,dn,comment    
                            outputcontent ($table | Select-Object type,name,displayname,parentgroup,nesting,enabled,dn,comment)
                            } 
                         }
                    } 
                  
                } 
             } 
        } 
        else {Write-Warning "Active Directory module is not loaded"}        
    }
    
    
    ########## MAIN ##########
    #Clear-Host
    $error.clear()

    if ($silent -eq $false) {
        Write-Host "AD Nested User Membership Report Builder"
    }

    Import-Module activedirectory
    $DateTime = Get-Date
    $Hostname = Hostname
    $user = whoami
    $currentDomain = $null
    $DefaultDC = $null
    $searchUserMembersOf = $null
    $emptyReport = $true

    # Get User to search and confirm it exists.
    if ($username){
        #Write-Host "Username passed in: $username"
        $searchUser = $username
        try {
            if ($domain) {
                #SWrite-Host "Domain passed in: $domain"
                try {
                    $DC = Get-ADDomainController -Discover -Domain $domain | Select-Object -ExpandProperty hostname
                } catch {
                    Write-Host "Domain passed in is not valid, searching for domain of user"
                    $domain = Get-DomainOfUser -Username $searchUser
                    $DC = Get-ADDomainController -Discover -Domain $domain | Select-Object -ExpandProperty hostname
                    Write-Host "Using Domain Controller: $DC"
                }
                #$DC = Get-ADDomainController -Discover -Domain $domain | Select-Object -ExpandProperty hostname
                #Write-Host "Using Domain Controller: $DC"
            } else {
                Write-Host "No Domain passed in, searching for domain of user"
                $domain = Get-DomainOfUser -Username $searchUser
                $DC = Get-ADDomainController -Discover -Domain $domain | Select-Object -ExpandProperty hostname
                Write-Host "Using Domain Controller: $DC"
            }
            #$domain = Get-DomainOfUser -Username $searchUser
            #$DC = Get-ADDomainController -Discover -Domain $domain | Select-Object -ExpandProperty hostname
            
            $usercheck = Get-ADUser $searchUser -Server $DC -properties MemberOf
            $memberof = $userCheck | Select-Object -expand MemberOf
            
            if ($memberof){
                $emptyReport = $false
            } else {
                $emptyReport = $true
            }
            $currentDomain = $domain
            $DefaultDC = $DC
            Write-Host "Valid User"
        } catch {
            Write-Host "Username ($searchUser) Entered was not found in $domain!"
            continue
        }
    } else {
        do {
            $searchUser = Read-Host "Enter username to Search"
            $usercheck = ""
            try {
                $domain = Get-DomainOfUser -Username $searchUser
                $DC = Get-ADDomainController -Discover -Domain $domain | Select-Object -ExpandProperty hostname
                $usercheck = Get-ADUser $searchUser -Server $DC
                $currentDomain = $domain
                $DefaultDC = $DC
                Write-Host "Valid User"
            } catch {
                Continue
            }
            if ($usercheck -eq "") {
                Write-Host "Username Entered does not Exsist!"
            }
        }
        Until ($usercheck -ne "")
    }

    if($outputFile){
        $outputFile = $outputFile
    } else {
        Write-Host "Opening File Save Dialog Box..."
    
        # Set Save Location
        $fileDate = (Get-Date).ToString("yyyyMMdd_HHmmss")
        $filename = "ADNestedUserMembership_" + $searchUser + "_$fileDate" # Default file name
        $outputFile = Get-FileSaveLocation -name $filename -type ".txt"
    }
    
    
    
    # Clear out any errors before building report
    $error.clear()

    # Header Information
    $Header = @()
    $Header += " AD Nested User Membership Report"
    $Header += " "
    $Header += "Report run by $user"
    $Header += "Report run from $Hostname"
    $Header += "Report run at $DateTime"
    $Header += "Queried AD User: $searchUser"
    $Header += "Queried Domain: $currentDomain"
    $Header += "Queried Domain Controller: $DefaultDC"
    $Header += " "
    $Header += " ================================ "
    
    $Header = $Header | Out-String
    
    # Body
    $Body = @()
    $Body += ""
    $Body += " Groups with a # in front are in the MembersOf the searched user."
    $Body += " Group Name <-> Group DN"
    $Body += ""
    $searchUserMembersOf = (get-adUser -Identity $searchUser -Properties MemberOf -Server $DefaultDC).MemberOf
    $searchUserMembersOf = $searchUserMembersOf | Sort-Object
    foreach ($group in $searchUserMembersOf) {
        #  Add this group as base level
        $nestedmember = (GetADGroup ($group))
        $Props = @{Type=$nestedmember.objectclass;Name=$nestedmember.name;DisplayName="";ParentGroup=$ADgroupname.name;Enabled="";Nesting=$nesting;DN=$nestedmember.distinguishedname;Comment=""} 
        $table = new-object psobject -property $props
        $table.name = $nestedmember.name
        $table.dn = $nestedmember.distinguishedName
        $Body += "#" + $table.name + " <-> " + $table.dn
        Write-Host "# " $table.name " <-> " $table.dn
    
        #  Loop through all members of
        $Body += Get-ADNestedGroupMembers $group -indent -nesting '0'
    }
    
    # Error Information
    $errorinfo = @()
    $errorinfo += "======================================================================="
    $errorinfo += "Script Encountered $($error.count) Exceptions"
    $errorinfo += " ================================ "
    $errorinfo += $error
    
    # Footer Infomation (Written by Micah Wallace)
    $footer =@()
    $footer += "======================================================================="
    $footer += "Automation Script written by Micah Wallace"
    
    $footer = $footer | Out-String
    
    $Report = @()
    $Report += $Header
    $Report += $Body
    $Report += $errorinfo
    $Report += $footer
    
    if ($emptyReport -eq $true -and $noEmptyReport -eq $true) {
        Write-Host "No Groups Found"
        continue
    } else{
        $Report | Out-File $outputFile
    }
    

    if ($silent -eq $false) {
        Clear-Host
        Write-Host "Report Generated and Saved to $outputFile"
        $openfile = Read-Host "Do you want to open the file? [Y/N]"
        if ($openfile -eq "Y") {
            Invoke-item -path $outputFile
        }
    }
}