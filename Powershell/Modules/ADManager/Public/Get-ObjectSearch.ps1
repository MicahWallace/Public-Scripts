function Get-ObjectSearch () {
    Clear-Host
    $searchName = Read-Host "Enter Object Name to search"
    

    $date = (Get-Date).ToString("yyyyMMdd_HHmmss")
    $filename = "ObjectSearch_" + $searchName + "_" + $date + ".csv"
    Write-Host "Opening File Save Dialog..."
    $outputFile = Get-FileSaveLocation -name $filename -type ".csv"
    $outputData = $false
    
    Write-LogAndAlert -content "Object search started for $searchName"

    Write-Host("Starting Object Search for $searchName")
    
    # Add wild card on ether side for search
    $searchName = "*$searchName*"
    
    $domains = Get-AllDomains
   
    Foreach ($domain in $domains) {
        $users = $null
        $groups = $null
        # Loop through all domains and pull data
        Write-Host("Searching Domain: $domain")
        
        Write-Host(" Starting User Search ")
        # Get Users Data
        #$users = $null
        try {
            $users = Get-ADUser -Filter "samaccountname -like '$searchName' -or name -like '$searchName'" -Server $domain -Properties * | Select-Object samAccountName,name,description,DistinguishedName,CononicalName,ProtectedFromAccidentalDeletion
        } catch {
            Write-Host("Error searching users")
            Write-Host $_
        }
        

        $userCount = $users.count
        Write-Host("Number of users found: $userCount")
        foreach ($user in $users) {
            Write-Host (" - " + $user.samAccountName)
            #TODO output to csv
            $ReportLine = [PSCustomObject] @{
                Type                 = "user"
                SamAccountName       = $user.SamAccountName
                Name                 = $User.Name
                Description          = $user.description
                #DistinguishedName    = [regex]::match($($user.DistinguishedName), '(?=OU)(.*\n?)(?<=.)').Value
                DistinguishedName    = $user.DistinguishedName
                #CanonicalName        = $user.CanonicalName
                ProtectedFromAccidentalDeletion = $user.ProtectedFromAccidentalDeletion
                Domain               = $domain
              }
                  
              $ReportLine | Export-CSV -NoTypeInformation -Encoding UTF8 $outputFile -Append
              $outputData = $True
        }

        Write-Host(" Starting Group Search ")

        # Get Group Data
        #$groups = $null

        Try {
            $groups = Get-ADGroup -Filter "samaccountname -like '$searchName' -or name -like '$searchName'" -Server $domain -Properties * | Select-Object samAccountName,name,description,DistinguishedName,CononicalName,ProtectedFromAccidentalDeletion
        } catch {
            Write-Host("Error searching groups")
            Write-Host $_
        }
        

        $groupCount = $groups.count
        Write-Host("Number of Groups found: $groupCount")
        
        foreach ($group in $groups) {
            Write-Host (" - " + $group.SamAccountName)
            #TODO output to csv

            $ReportLine = [PSCustomObject] @{
                Type                 = "group"
                SamAccountName       = $group.SamAccountName
                Name                 = $group.Name
                Description          = $group.description
                #DistinguishedName    = [regex]::match($($group.DistinguishedName), '(?=OU)(.*\n?)(?<=.)').Value
                DistinguishedName    = $group.DistinguishedName
                #CanonicalName        = $group.CanonicalName
                ProtectedFromAccidentalDeletion = $group.ProtectedFromAccidentalDeletion
                Domain               = $domain
              }
                  
              $ReportLine | Export-CSV -NoTypeInformation -Encoding UTF8 $outputFile -Append
              $outputData = $true
        }
        
    }

    if ($outputData){
        #Write-Host "Report Generated and Saved to $outputFile"
        Write-LogAndAlert -content "Report Generated and Saved to $outputFile"
        $openfile = Read-Host "Do you want to open the file? [Y/N]"
        if ($openfile -eq "Y") {
        Invoke-item -path $outputFile
        }
    } else {
        #Write-Host("No objects found for $searchName")
        Write-LogAndAlert -content "No objects found for $searchName" -errorlevel 2
        Pause
    }
}