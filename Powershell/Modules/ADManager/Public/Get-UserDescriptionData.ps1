function Get-UserDescriptionData {
  
  Clear-Host
  do {
    $inputSelection = Read-Host " Please enter username or press Q to quit"
    if ($inputSelection -eq "q") { return }
    #Clear-Host
    $userDataHash = @{}
    $user = $null
    [bool]$newDescriptionFormat = $false

    $domain = Get-DomainOfUser -username $inputSelection
    $dc = Get-ADDomainController -Discover -DomainName $domain | Select-Object -ExpandProperty Hostname

    if (!$domain) {
      Start-Sleep -Seconds 2
      Continue
    }


    $user = get-aduser -Server $dc -Identity $inputSelection -Properties *
    
    # Description Info
    $userDataDescription = $user.Description
    #Write-Host "User Description Field: $userDataDescription"
    
    if ($userDataDescription) {
      if ($userDataDescription.Contains(";")){
        $newDescriptionFormat = $true
        $userDataArray = $userDataDescription.split(";")
        foreach ($item in $userDataArray) {
          $userObject = $item.split(":", 2)
          $userDataHash += @{$userObject[0].Trim() = $userObject[1].Trim() }
        }
      } elseif ($userDataDescription.Contains("Notes:")) {
        $newDescriptionFormat = $true
        $userObject = $userDataDescription.split(":", 2)
        $userDataHash += @{$userObject[0].Trim() = $userObject[1].Trim() }
      } else {
        $newDescriptionFormat = $false
        $userDataHash += @{"Description" = $userDataDescription }
      }
    } else {
      $newDescriptionFormat = $false
      $userDataHash += @{"Description" = $userDataDescription }
    }

    Write-Host "User: $($User.SamAccountName) - Domain: $domain"
    $userDataHash.GetEnumerator() | Sort-Object key | Format-Table
    
    do {
      $detailInfo = Read-Host "User:$($User.SamAccountName) ($($user.GivenName) $($user.Surname)) - [A]ll Info, [U]pdate Description, [L]ast Login info, or [Q] to Exit and search another user? [U/A/L/Q]"
      if ($detailInfo -eq "A") { 
        $user | Format-UserDescriptionObject | Out-GridView 
      }
      if ($detailInfo -eq "U") { 
        Write-Host "Update Description"
        if ($newDescriptionFormat){
          do {
            Clear-Host
            Write-Host "Current Data"
            Write-Host "User: $($User.SamAccountName) - Domain: $domain"
            $userDataHash.GetEnumerator() | Sort-Object key | Format-Table
            Write-Host "    ========================================"
            $lineNumber = 1
            $userDataKeyArray = @()
            foreach ($h in $userDataHash.GetEnumerator() | Sort-Object key) {
              Write-Host "To Edit $($h.Name) press [$lineNumber]"
              $userDataKeyArray += $h.Name
              $lineNumber++
            }
            Write-Host "To Add a new Key/Value press [$lineNumber]"
            $updateItem = Read-Host "Enter number of item to update or [D] when DONE to exit and prompt for Save."
            if ($updateItem -eq "D") {
              continue
            } elseif ([int]$updateItem -le $lineNumber){
              if ([int]$updateItem -lt $lineNumber) {
                # Update a current Key/Value
                $key = $userDataKeyArray[([int]$updateItem -1)]
                $newValue = Read-Host "Enter new value for $key, or press [ENTER] to leave current value"
                if ($newValue){
                  $userDataHash.$key = $newValue
                }
              } elseif ([int]$updateItem -eq $lineNumber) {
                # Add a new Key/Value
                Write-Host "Making a new Key/Value"
                $newKey = Read-Host "Please Enter New Key"
                $newValue = Read-Host "Please Enter Value for $newKey"
                If ($newKey -and $newValue){
                  $userDataHash[$newKey] = $newValue
                } else {
                  Write-Host "New Key or New value not entered"
                  Start-Sleep -Seconds 2
                }
              }
            } elseif ([int]$updateItem -gt $lineNumber){
              Clear-Host
              Write-Host "Invalid Selection"
              Start-Sleep -Seconds 2
            }
          } until ($updateItem -eq "D")
          $saveChanges = Read-Host "Do you want to Save changes to Active Directory? [Y/N]"
          if ($saveChanges -eq "y"){
            Write-Host "Saving Changes"
  
            # Copy current user data hash into temp
            $tempUserDataHash = $userDataHash
  
            # Build Output Description
            if ($userDataHash.owner){
              $outputDescription = $outputDescription + "Owner:$($userDataHash.owner); "
              $tempUserDataHash.Remove("owner")
            }
      
            if ($userDataHash.team){
              $outputDescription = $outputDescription + "Team:$($userDataHash.team); "
              $tempUserDataHash.Remove("team")
            }
            
            if ($tempUserDataHash){
              foreach ($key in $tempUserDataHash.Keys | Sort-Object key){
                $outputDescription = $outputDescription + "$($Key):$($tempUserDataHash[$Key]); "
              }
            }
      
            if ($outputDescription){
              $outputDescription = $outputDescription.Trim(" ",";") # Remove space and trailing semicolon
            }
            try {
              Set-AdUser -Server $dc -Identity $user.SamAccountName -Description $outputDescription
              Write-Host "New Description: $outputDescription"
              Exit
            }
            catch {
              Write-Host "ERROR $_"
              Pause
            }
            #Set-AdUser -Server $dc -Identity $user.SamAccountName -Description $outputDescription
          } else {
            Write-Host "Changes abandoned"
            Start-Sleep -Seconds 2
          }
        } else {
          Write-Host "Description is in Native Format"
          $updateToNewFormat = Read-Host "Do you want to update Description to New Key/Value Format? [Y/N]"
          if ($updateToNewFormat -eq "Y"){
            $outputDescription = "Notes: $($user.Description)"
            try {
              Set-AdUser -Server $dc -Identity $user.SamAccountName -Description $outputDescription
              Write-Host "$($User.SamAccountName) Description changed to: $outputDescription"
              Start-Sleep -Seconds 2
            }
            catch {
              Write-Host "ERROR $_"
              Pause
            }
            #Set-AdUser -Server $dc -Identity $user.SamAccountName -Description $outputDescription
          } else {
            continue
          }
          Start-Sleep -Seconds 2
          #pause
        }
      }
      if ($detailInfo -eq "L"){
        # Get Last Login Info
        $lastLogin = Get-LastLogonDT -user $user -Domain $domain -allResults
        Write-Host "Last Login for $($User.SamAccountName) - $lastLogin"
      }
    } until (
      $detailInfo -eq "q"
    )
    
    Clear-Host
    
  } until ($inputSelection -eq "q")
  #Clear-Host
}