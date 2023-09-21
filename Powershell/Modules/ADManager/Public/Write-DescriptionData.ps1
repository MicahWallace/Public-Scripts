function Write-DescriptionData {
    # Do you need a sample file created
    $sampleFile = Read-Host "Do you need a sample file created? Y/N"
    if ($sampleFile -eq 'Y') {
      $filename = "AD_Team_Owner_upload_sample.csv"
      $outputFile = Get-FileSaveLocation -name $filename -type ".csv"
  
      $ReportLine = [PSCustomObject] @{
        SamAccountName      = $null
        Owner               = $null
        Team                = $null
        domain              = $null
      }
    
      $ReportLine | Export-CSV -NoTypeInformation -Encoding UTF8 $outputFile -Append
    }
  
    # Select upload file
    Write-Host "Select File to upload..."
    $uploadFile = Get-FileOpenLocation -type ".csv" -location "C:\Temp"
    
    if (!$uploadFile) {
      Write-Host "No upload file selected, returning to main menu."
      return
    }
  
    # Import CSV File
    Write-Host "Importing Data... Please Wait"
    $data = Import-Csv -Path $uploadFile
    Write-Host "Data Loaded... Starting to process"
  
    $replaceValue = Read-Host "Do you want to replace currently set values? Default will only set currently unset values. [Y/N]"
    if ($replaceValue -eq "Y") {
      $replaceValue = $true
    }
    else {
      $replaceValue = $false
    }
  
    $confirmUpdate = Read-Host "Do you want to confirm any changes to AD? [Y/N]"
    if ($confirmUpdate -eq "Y") {
      $confirmUpdate = $true
    }
    else {
      $confirmUpdate = $false
    }
    
    foreach ($user in $data){
      #Write-Host $user.SamAccountName
      $currentOwner = $false
      $currentTeam = $false
      $userDataHash = @{}
      $outputDataHash = @{}
      $outputDescription = $null
  
      $domain = Get-DomainOfUser -username $user.SamAccountName
      $dc = Get-ADDomainController -Discover -DomainName $domain | Select-Object -ExpandProperty Hostname
  
      $userData = Get-ADUser -Server $dc -Identity $User.SamAccountName -Properties *
  
      # Current Description Info
      #Write-Host "Current Description Value: $($userData.description)"
      $userDataDescription = $userData.Description
      
      if ($userDataDescription){ # Check if Description is blank
        if ($userDataDescription.Contains(";")) {
          $userDataArray = $userDataDescription.split(";")
          foreach ($item in $userDataArray) {
            $userObject = $item.split(":", 2)
            $userDataHash += @{$userObject[0].Trim() = $userObject[1].Trim() }
          }
        }
        else {
          $userDataHash += @{"Notes" = $userDataDescription }
        }
      }
  
      # Check for current Owner
      if ($userDataHash.keys -contains "owner"){$currentOwner = $true}
  
      # Check for current Team
      if ($userDataHash.keys -contains "team"){$currentTeam = $true}
  
      
      # Compare Team value
      if (!$currentTeam){
        # If no Team is set then just set it
        if ($user.team){
          $outputDataHash += @{"Team" = $user.team}
        }
      } else {
        if ($replaceValue){
          # Replace Value
          if ($user.team){ # Make sure we dont replace with blank value
            $outputDataHash += @{"Team" = $user.team}
          } else {
            # If blank then put in current value
            $outputDataHash["Team"] = $userDataHash.Team
          }
        } else {
          # If replace value is set to no, than copy current into output
          #$outputDataHash += $userDataHash.team
          $outputDataHash["Team"] = $userDataHash.Team
        }
      }
  
      # Copy current user data hash into temp
      $tempUserDataHash = $userDataHash
  
      # Compare Owner value
      if (!$currentOwner){
        # If no Owner is set then just set it
        if ($user.owner){
          $outputDataHash += @{"Owner" = $user.owner}
        }
      } else {
        if ($replaceValue){
          # Replace Value
          if ($user.owner){ # Make sure we dont replace with blank value
            $outputDataHash += @{"Owner" = $user.owner}
          } else {
            # If its blank then put in current value
            $outputDataHash["Owner"] = $userDataHash.Owner
          }
        } else {
          # If replace value is set to no, than copy current into output
          #$outputDataHash += $userDataHash.owner
          $outputDataHash["Owner"] = $userDataHash.Owner
        }
      }
  
      # Check if we have output
      if ($outputDataHash.count -gt 0) {
        # We have data to write
  
        # Get any other data from current description and add to output
        # Remove new data keys from current data
        foreach ($key in $outputDataHash.Keys){
          $tempUserDataHash.Remove($key)
        }
  
        # Add remaining keys to output
        foreach ($key in $tempUserDataHash.Keys){
          $outputDataHash[$key] = $($tempUserDataHash[$key])
        }
  
        # Build Output Description
        if ($outputDataHash.owner){
          $outputDescription = $outputDescription + "Owner:$($outputDataHash.owner); "
        }
  
        if ($outputDataHash.team){
          $outputDescription = $outputDescription + "Team:$($outputDataHash.team); "
        }
        
        if ($tempUserDataHash){
          foreach ($key in $tempUserDataHash.Keys){
            $outputDescription = $outputDescription + "$($Key):$($tempUserDataHash[$Key]); "
          }
        }
  
        if ($outputDescription){
          $outputDescription = $outputDescription.Trim(" ",";") # Remove space and trailing semicolon
        }
  
        #Write-Host "New Description: $outputDescription"
  
        # Push back to AD
        if ($confirmUpdate){
          Clear-Host
          Write-Host "Username:$($User.SamAccountName)"
          Write-Host "Current Description Value: $($userData.description)"
          Write-Host "New Description: $outputDescription"
          try {
            Set-AdUser -Server $dc -Identity $User.SamAccountName -Description $outputDescription -Confirm
            Write-Host "$($User.SamAccountName) Description to: $outputDescription"
          }
          catch {
            Write-Host "Error changing description for $($User.SamAccountName)"
            Write-Host $_
          }
          
        } else {
          # No confirmatino Required
          Set-AdUser -Server $dc -Identity $User.SamAccountName -Description $outputDescription
          Write-Host "$($User.SamAccountName) Description to: $outputDescription"
        }
  
      } else {
        # We have no new data to write
        Write-Host "$($User.SamAccountName) - We have no data to write to Description"
      }
  
    }
    Write-Host ""
    Write-Host " - Team / Owner Info upload is done - "
    pause
  }