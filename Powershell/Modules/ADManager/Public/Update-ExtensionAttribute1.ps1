function Update-ExtensionAttribute1 {
    # Do you need a sample file created
    $sampleFile = Read-Host "Do you need a sample file created? Y/N"
    if ($sampleFile -eq 'Y') {
      $filename = "extensionAttribute1_upload_sample.csv"
      $outputFile = Get-FileSaveLocation -name $filename -type ".csv"
  
      $ReportLine = [PSCustomObject] @{
        SamAccountName      = $null
        extensionAttribute1 = $null
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
  
    Write-LogAndAlert -content "Update-ExtensionAttribute1 Started" -quiet
    Write-LogAndAlert -content "File imported: $uploadFile" -quiet
    Get-ErrorCounter -reset
  
    $data = Import-Csv -Path $uploadFile
  
    $replaceValue = Read-Host "Do you want to replace currently set values? Default will only set currently unset values. [Y/N]"
    if ($replaceValue -eq "Y") {
      $replaceValue = $true
    }
    else {
      $replaceValue = $false
    }
    Write-LogAndAlert -content "Replace currently set values:$replaceValue"
  
    if ($replaceValue) {
      $confirmUpdate = Read-Host "Do you want to confirm any changes to currently set values? [Y/N]"
      if ($confirmUpdate -eq "Y") {
        $confirmUpdate = $true
      }
      else {
        $confirmUpdate = $false
      }
    }
    else {
      $confirmUpdate = $false
    }
    Write-LogAndAlert -content "Confirm changes set to $confirmUpdate"
  
    foreach ($user in $data) {
      #Write-Host $user.SAMAccountName
      #pause
      #Clear-Host
      #Write-Host $user.SamAccountName
  
      $dc = Get-ADDomainController -Discover -DomainName $user.domain
      $fullDc = -join ($dc, ".", $user.domain)
  
      try {
        $currentvalue = Get-ADUser -Server $fullDc -Identity $User.SamAccountName -Properties "extensionAttribute1"
        #Write-Host "Current Value: $($currentvalue.extensionAttribute1)"
        Write-LogAndAlert -content "User:$($user.SamAccountName) - Current Value: $($currentvalue.extensionAttribute1)"
      }
      catch {
        Write-LogAndAlert -content $_ -ErrorLevel 2
        Get-ErrorCounter -increase
      }
      
      
  
      if (!$currentvalue.extensionAttribute1) {
        # If no value is set then just set the value
        try {
          Set-AdUser -Server $fullDc -Identity $($user.SAMAccountName) -Add @{ExtensionAttribute1 = "$($user.extensionAttribute1)" }
          #Write-Host "Set to: $($user.extensionAttribute1)"
          Write-LogAndAlert -content "$($user.SamAccountName) - Set to: $($user.extensionAttribute1)"
        }
        catch {
          Write-LogAndAlert -content "Unable to set Extension Attribute 1 for $($user.SamAccountName)" -ErrorLevel 2
          Write-LogAndAlert -content $_ -ErrorLevel 2
          Get-ErrorCounter -increase
        }
        
      }
      else {
        if ($replaceValue) {
          if ($confirmUpdate) {
            # Replace the value but confirm first
            Write-Host "New Value will be: $($user.extensionAttribute1)"
            try {
              Set-AdUser -Server $fullDc -Identity $($user.SAMAccountName) -Replace @{ExtensionAttribute1 = "$($user.extensionAttribute1)" } -Confirm
              Write-LogAndAlert -content "User:$($user.SamAccountName) - Set to: $($user.extensionAttribute1)"
            }
            catch {
              Write-LogAndAlert -content "Unable to set Extension Attribute 1 for $($user.SamAccountName)" -ErrorLevel 2
              Write-LogAndAlert -content $_ -ErrorLevel 2
              Get-ErrorCounter -increase
            }
            #Set-AdUser -Server $fullDc -Identity $($user.SAMAccountName) -Replace @{ExtensionAttribute1 = "$($user.extensionAttribute1)" } -Confirm
          }
          else {
            # Replace the value without asking for confirmation
            try {
              Set-AdUser -Server $fullDc -Identity $($user.SAMAccountName) -Replace @{ExtensionAttribute1 = "$($user.extensionAttribute1)" }
              Write-LogAndAlert -content "User:$($user.SamAccountName) - Set to: $($user.extensionAttribute1)"
            }
            catch {
              Write-LogAndAlert -content "Unable to set Extension Attribute 1 for $($user.SamAccountName)" -ErrorLevel 2
              Write-LogAndAlert -content $_ -ErrorLevel 2
              Get-ErrorCounter -increase
            }
            #Set-AdUser -Server $fullDc -Identity $($user.SAMAccountName) -Replace @{ExtensionAttribute1 = "$($user.extensionAttribute1)" }
            #Write-Host "Set to: $($user.extensionAttribute1)"
          } 
        }
        else {
          #Write-Host "Value not updated since a value is already set"
          Write-LogAndAlert -content "Value not updated for $($user.SamAccountName) since a value is already set" -ErrorLevel 2
        }
      }
    }
    
    if ($errorCount -gt 0){
      Write-LogAndAlert -content "Script ran into $errorCount Error(s)." -ErrorLevel 2
      Get-ErrorCounter -reset
    }
    Write-LogAndAlert -content "Extension Attribute 1 Upload finished"
    #Write-Host "All Attributes have been updated"
    Open-ErrorLog
    
    Pause
    Clear-Host
  }