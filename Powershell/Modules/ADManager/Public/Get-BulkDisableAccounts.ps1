function Get-BulkDisableAccounts {
    # Do you need a sample file created
    $sampleFile = Read-Host "Do you need a sample file created? Y/N"
    if ($sampleFile -eq 'Y') {
      $filename = "bulkDisableAccounts_upload_sample.csv"
      $outputFile = Get-FileSaveLocation -name $filename -type ".csv"
  
      $ReportLine = [PSCustomObject] @{
        SamAccountName = $null
        domain         = $null
      }
    
      $ReportLine | Export-CSV -NoTypeInformation -Encoding UTF8 $outputFile -Append
    }
  
  
    Write-Host "Select source file..."
    $uploadFile = Get-FileOpenLocation -type ".csv" -location "C:\Temp"
  
    $date = Get-Date -Format "yyyy-MM-dd"
  
    Clear-Host
  
    if (!$uploadFile) {
      Write-Host "No File Selected...Exiting"
      Break
    }
  
    Write-LogAndAlert -content "Bulk Disable Accounts Started"
    Write-LogAndAlert -content "Upload File: $uploadFile"
    Get-ErrorCounter -reset
  
    # Get ticket number
    $TicketNumber = Read-Host -Prompt "Please Enter Ticket number or press ENTER for testing."
    if (!$TicketNumber) {
      $TicketNumber = "Change####"
    }
    Write-LogAndAlert -content "Ticket Number: $TicketNumber"
  
    # Set Danger Mode.  If Enabled, this will make changes.
    $dangerMode = $false
  
    if ($TicketNumber -ne "Change####") {
      $dangerEnable = Read-Host -Prompt "DANGER - Do you want script to make change in AD to disable accounts? If you DO, enter ticket number a second time."
      if ($TicketNumber -ceq $dangerEnable) {
        #Write-Host "Danger Mode Activated.  Changes will be made."
        $dangerMode = $true
        Write-LogAndAlert -content "Danger Mode Activated.  Changes will be made."
      }
      else {
        #Write-Host "Ticket Numbers did not match (case sensitive). Running in What If mode."
        Write-LogAndAlert -content "Ticket Numbers did not match (case sensitive). Running in What If mode." -ErrorLevel 2
      }
    }
  
    if ($dangerMode) {
      $confirmUpdate = Read-Host "Do you want to confirm each account to disable? If NO, only 10 accounts will be changed in a run. Yes raises limit to 150 [Y/N]"
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
    Write-LogAndAlert -content "Confirm Update: $confirmUpdate"
  
    $count = 0
    $changeLimit = 0
  
    # Import CSV
    $csvFile = import-csv -Path $uploadFile
  
    if ($confirmUpdate) {
      $changeLimit = 150
    }
    else {
      $changeLimit = 10
    }
    Write-LogAndAlert -content "Change Limit: $changeLimit"
  
    foreach ($record in $csvFile) {
  
      # Safety Stop
      if ($count -gt $changeLimit) {
        #Write-Host "Reached change limit of $changeLimit. Please run again to change more accounts."
        Write-LogAndAlert -content "Reached change limit of $changeLimit. Please run again to change more accounts." -ErrorLevel 2
        Exit
      }
  
      $account = $record.SamAccountName
      Write-LogAndAlert -content $account
      #Write-Output $account
  
      $DCInfo = Get-ADDomainController -Discover -Domain $record.Domain
      $DC = $DCInfo.Name + "." + $DCInfo.Domain
  
      if (!(Get-ADUser -Filter "sAMAccountName -eq '$($account)'" -Server $DC)) {
        #Write-Host "$account - User does not exist."
        Write-LogAndAlert -content "$account - User does not exist."
        continue
      }
  
      # Get user info
      $UserInfo = Get-ADUser -Identity $account -Properties "Description" -Server $DC
  
      if (!$UserInfo.Enabled) {
        #Write-Host "$account is already disabled.  Skipping account."
        Write-LogAndAlert -content "$account is already disabled.  Skipping account."
        continue
      }
  
      # Take current description and append info on it.
      $currentDescription = $UserInfo.Description
      if ($currentDescription) {
        $newDescription = "Disabled:$date; Ticket:$TicketNumber; $currentDescription"
      }
      else {
        $newDescription = "Disabled:$date; Ticket:$TicketNumber"
      }
    
  
      # Disable user account and update Description
      Write-Host "Current user: $account"
      if ($dangerMode) {
        if ($confirmUpdate) {
          # Make changes with confirm
          try {
            Disable-ADAccount -Identity $account -Server $DC -Confirm
            #Write-Host "$account disabled"
            Write-LogAndAlert -content "$account disabled"
          }
          catch {
            Write-LogAndAlert -content "Unable to disable $account" -ErrorLevel 2
            Get-ErrorCounter -increase
          }
          
  
          # Check if disabled
          $UserEnabled = (Get-ADUser -Identity $account -Properties enabled -Server $DC).Enabled
  
          # Make changes to Description if disabled
          if (!$UserEnabled) {
            try {
              Set-ADUser -Server $DC -Identity $account -Description $newDescription
              #Write-Host "$account Description changed: $newDescription"
              Write-LogAndAlert -content "$account Description changed: $newDescription"
            }
            catch {
              Write-LogAndAlert -content "Unable to change description for $account" -ErrorLevel 2
              Get-ErrorCounter -increase
            }
            
          }
          
        }
        else {
          # Make changes
          try {
            Disable-ADAccount -Identity $account -Server $DC
            #Write-Host "$account disabled"
            Write-LogAndAlert -content "$account disabled"
          }
          catch {
            Write-LogAndAlert -content "Unable to disable $account" -ErrorLevel 2
            Get-ErrorCounter -increase
          }
          
          # Check if disabled
          $UserEnabled = (Get-ADUser -Identity $account -Properties enabled -Server $DC).Enabled
  
          # Make changes to Description if disabled
          if (!$UserEnabled) {
            try {
              Set-ADUser -Server $DC -Identity $account -Description $newDescription
              #Write-Host "$account Description changed: $newDescription"
              Write-LogAndAlert -content "$account Description changed: $newDescription"
            }
            catch {
              Write-LogAndAlert -content "Unable to change description for $account" -ErrorLevel 2
              Get-ErrorCounter -increase
            }
          }
  
          <# # Make changes to Description
          Set-ADUser -Server $DC -Identity $account -Description $newDescription
          Write-Host "$account Description changed: $newDescription" #>
        }
  
      }
      else {
        # Dont make changes (What If mode)
        Disable-ADAccount -Identity $account -Server $DC -WhatIf
        # Dont make changes (What If mode)
        Set-ADUser -Server $DC -Identity $account -Description $newDescription -WhatIf
      }
   
      $count++
      #Exit
    }
  
    if ($errorCount -gt 0){
      Write-LogAndAlert -content "Script ran into $errorCount Error(s)." -ErrorLevel 2
      Get-ErrorCounter -reset
    }
  
    Write-LogAndAlert -content "Bulk Disable Accounts finished"
    Open-ErrorLog
  }