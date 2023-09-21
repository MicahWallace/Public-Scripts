function Remove-BulkUsersGroups {

  # True will make changes.  False will just write to screen.
  $makeChanges = $true

  $sampleFile = Read-Host "Do you need a sample file created? Y/N"
  if ($sampleFile -eq 'Y') {
    $filename = "bulkObjectRemove_sample.csv"
    $outputFile = Get-FileSaveLocation -name $filename -type ".csv"

    $ReportLine = [PSCustomObject] @{
      Type           = $null
      SamAccountName = $null
      domain         = $null
    }
  
    $ReportLine | Export-CSV -NoTypeInformation -Encoding UTF8 $outputFile -Append
  }
  
  Write-Host "Select folder to save output files..."
  $folderSaveLocation = Get-FolderSaveLocation
  if ($null -eq $folderSaveLocation) {
      Write-Host("No folder selected")
      Break
  }
  
  Write-Host "Select source file..."
  $uploadFile = Get-FileOpenLocation -type ".csv" -location "C:\Temp"
  if ($null -eq $uploadFile) {
      Write-Host("No file selected")
      Break
  }

  $logFilename = "BulkRemoveUserGroup_" + (Get-Date).ToString("yyyyMMdd_HHmmss") + ".log"
  $logFilePath = $folderSaveLocation + "\" + $logFilename

  Clear-Host
  Write-LogAndAlert -LogPath $logFilePath -content "Bulk Remove User/Group Objects Started"
  Write-LogAndAlert -LogPath $logFilePath -content "Upload File: $uploadFile"
  Get-ErrorCounter -reset
  
  # Get ticket number
  $TicketNumber = Read-Host -Prompt "Please Enter Ticket number or press ENTER for testing."
  if (!$TicketNumber) {
    $TicketNumber = $null
  } else {
      Write-LogAndAlert -LogPath $logFilePath -content "Ticket Number: $TicketNumber"
  }
  
  # Set Danger Mode.  If Enabled, this will make changes.
  $dangerMode = $false

  if ($null -ne $TicketNumber) {
    $dangerEnable = Read-Host -Prompt "DANGER - Do you want script to make change in AD to DELETE user/group objects? If you DO, enter ticket number a second time."
    if ($TicketNumber -ceq $dangerEnable) {
      #Write-Host "Danger Mode Activated.  Changes will be made."
      $dangerMode = $true
      Write-LogAndAlert -LogPath $logFilePath -content "Danger Mode Activated.  Changes will be made."
    }
    else {
      #Write-Host "Ticket Numbers did not match (case sensitive). Running in What If mode."
      Write-LogAndAlert -LogPath $logFilePath -content "Ticket Numbers did not match (case sensitive). Running in What If mode." -ErrorLevel 2
    }
  }

  if ($dangerMode) {
    $confirmUpdate = Read-Host "Do you want to confirm each account to DELETE? If NO, only 10 accounts will be changed in a run. Yes raises limit to 150 [Y/N]"
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
  Write-LogAndAlert -LogPath $logFilePath -content "Make Changes: $makeChanges"
  Write-LogAndAlert -LogPath $logFilePath -content "Danger Mode: $dangerMode"
  Write-LogAndAlert -LogPath $logFilePath -content "Confirm Update: $confirmUpdate"

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

  if ($dangerMode) {
    Write-LogAndAlert -LogPath $logFilePath -content "Change Limit: $changeLimit"
  }

  # Loop through CSV figure out if its a user or group and then delete
  foreach ($line in $csvFile) {
      #$count++
      if ($dangerMode) {
        if ($count -gt $changeLimit) {
            Write-LogAndAlert -LogPath $logFilePath -content "Change Limit of $changeLimit reached.  Exiting."
            break
        }
      }
      $samAccountName = $line.SamAccountName
      $domain = $line.domain
      $type = $line.Type

      if ($null -eq $samAccountName) {
          Write-LogAndAlert -LogPath $logFilePath -content "No SamAccountName found.  Skipping."
          continue
      }
      if ($null -eq $domain) {
          Write-LogAndAlert -LogPath $logFilePath -content "No domain found.  Skipping."
          continue
      }
      if ($null -eq $type) {
          Write-LogAndAlert -LogPath $logFilePath -content "No type found.  Skipping."
          continue
      }

      if ($type -eq "user") {
          try {
            Get-ADUser -Identity $samAccountName -Server $domain -Properties UserPrincipalName | Out-Null
          }
          catch {
            Write-LogAndAlert -LogPath $logFilePath -content "Error finding user object ($samAccountName).  Skipping."
            Write-LogAndAlert -LogPath $logFilePath -content $_ -ErrorLevel 2
            continue
          }
          Write-LogAndAlert -LogPath $logFilePath -content "User Object found - $samAccountName - ($domain)"
          Write-Host "Getting Last Login info..."
          Get-LastLogonDT -user $samAccountName -Domain $domain -allResults -LogPath $logFilePath | Out-Null
          Write-LogAndAlert -LogPath $logFilePath -content "Generating User Membership report"
          
          try {
            $fileDate = (Get-Date).ToString("yyyyMMdd_HHmmss")
            $filename = "ADNestedUserMembership_" + $samAccountName + "_" + $domain + "_$fileDate" + ".txt"
            $outputFile = $folderSaveLocation + "\" + $filename 
            if ($dangerMode) {
              Get-UserNestedGroup -username $samAccountName -outputfile $outputFile -silent $true -domain $domain -noEmptyReport $false
            } else {
              Get-UserNestedGroup -username $samAccountName -outputfile $outputFile -silent $true -domain $domain -noEmptyReport $true
            }
            
          }
          catch {
            Write-LogAndAlert -LogPath $logFilePath -content "Error generating User Membership report for $samAccountName" -ErrorLevel 2
          }

          if ($dangerMode) {
              Write-LogAndAlert -LogPath $logFilePath -content "Danger Mode Enabled.  Deleting User Object. - $samAccountName"

              # Check if user is protected from accidental deletion
              $preventDelete = get-aduser $samAccountName -server $domain -Properties ProtectedFromAccidentalDeletion | Select-Object -ExpandProperty ProtectedFromAccidentalDeletion
              if ($preventDelete) {
                Write-LogAndAlert -LogPath $logFilePath -content "User Object ($samAccountName) is Protected from Accidental Deletion."
                try {
                  if ($makeChanges) {
                    set-aduser $samAccountName -ProtectedFromAccidentalDeletion $false -server $domain -confirm:$true
                  } else {
                    Write-Host "set-aduser $samAccountName -ProtectedFromAccidentalDeletion $false -server $domain -confirm:$true"
                  }
                  Write-LogAndAlert -LogPath $logFilePath -content "Protection from accidental deletion removed for User Object ($samAccountName)."
                }
                catch {
                  Write-LogAndAlert -LogPath $logFilePath -content "Error removing protection from accidental deletion for User Object ($samAccountName).)"
                  Write-LogAndAlert -LogPath $logFilePath -content $_ -ErrorLevel 2
                  Get-ErrorCounter -increment
                }
              }

              if ($confirmUpdate){
                try {
                  if ($makeChanges) {
                    Remove-ADUser -Identity $samAccountName -Server $domain -Confirm:$true
                    $count++
                  } else {
                    Write-Host "Remove-ADUser -Identity $samAccountName -Server $domain -Confirm:$true"
                  }
                  Write-LogAndAlert -LogPath $logFilePath -content "User Object ($samAccountName) Deleted from $domain."
                }
                catch {
                  Write-LogAndAlert -LogPath $logFilePath -content "Error Deleting User Object ($samAccountName).)"
                  Write-LogAndAlert -LogPath $logFilePath -content $_ -ErrorLevel 2
                  Get-ErrorCounter -increment
                }
              } else {
                try {
                  if ($makeChanges) {
                    Remove-ADUser -Identity $samAccountName -Server $domain -Confirm:$false
                    $count++
                  } else {
                    Write-Host "Remove-ADUser -Identity $samAccountName -Server $domain -Confirm:$false"
                  }
                  
                  Write-LogAndAlert -LogPath $logFilePath -content "User Object ($samAccountName) Deleted from $domain."
                } catch {
                  Write-LogAndAlert -LogPath $logFilePath -content "Error Deleting User Object. - $samAccountName"
                  Write-LogAndAlert -LogPath $logFilePath -content $_ -ErrorLevel 2
                  Get-ErrorCounter -increment
                }
            }
          }
          else {
            try {
              Remove-ADUser -Identity $samAccountName -Server $domain -WhatIf
            }
            catch {
              Write-Host "Error finding user object ($samAccountName).  Skipping."
              Write-Host $_
            }
          }
      }
      elseif ($type -eq "group") {
          try {
            Get-ADGroup -Identity $samAccountName -Server $domain -Properties UserPrincipalName | Out-Null
          }
          catch {
            Write-LogAndAlert -LogPath $logFilePath -content "Error finding group object ($samAccountName).  Skipping."
            Write-LogAndAlert -LogPath $logFilePath -content $_ -ErrorLevel 2
            continue
          }
        # Delete AD Groups
          Write-LogAndAlert -LogPath $logFilePath -content "Group Object found - $samAccountName"
          Write-LogAndAlert -LogPath $logFilePath -content "Generating Group Membership report"
          
          try {
            $fileDate = (Get-Date).ToString("yyyyMMdd_HHmmss")
            $filename = "ADNestedGroupMembership_" + $samAccountName + "_" + $domain + "_$fileDate" + ".txt"
            $outputFile = $folderSaveLocation + "\" + $filename
            if ($dangerMode) {
              Get-GroupNestedGroup -group $samAccountName -outputfile $outputFile -silent $true -domain $domain -noEmptyReport $false
            } else {
              Get-GroupNestedGroup -group $samAccountName -outputfile $outputFile -silent $true -domain $domain -noEmptyReport $true
            }
          }
          catch {
            Write-LogAndAlert -LogPath $logFilePath -content "Error generating User Membership report for $samAccountName" -ErrorLevel 2
          }
          if ($dangerMode) {
              Write-LogAndAlert -LogPath $logFilePath -content "Danger Mode Enabled.  Deleting Group Object - $samAccountName"

              # Check if group is protected from accidental deletion
              $preventDelete = get-adgroup $samAccountName -server $domain -Properties ProtectedFromAccidentalDeletion | Select-Object -ExpandProperty ProtectedFromAccidentalDeletion
              if ($preventDelete) {
                Write-LogAndAlert -LogPath $logFilePath -content "Group Object ($samAccountName) is Protected from Accidental Deletion." -quiet $true
                try {
                  Write-Host "Group Object ($samAccountName) is Protected from Accidental Deletion. Do you want to remove protection? Y/N"

                  if ($makeChanges) {
                    set-adgroup $samAccountName -ProtectedFromAccidentalDeletion $false -server $domain -confirm:$true
                  } else {
                    Write-Host "set-adgroup $samAccountName -ProtectedFromAccidentalDeletion $false -server $domain -confirm:$true"
                  }
                  
                  Write-LogAndAlert -LogPath $logFilePath -content "Protection from accidental deletion removed for Group Object ($samAccountName)."
                }
                catch {
                  Write-LogAndAlert -LogPath $logFilePath -content "Error removing protection from accidental deletion for Group Object ($samAccountName).)"
                  Write-LogAndAlert -LogPath $logFilePath -content $_ -ErrorLevel 2
                  Get-ErrorCounter -increment
                }
              }
              if ($confirmUpdate){
                try {
                  if ($makeChanges) {
                    Remove-ADGroup -Identity $samAccountName -Server $domain -Confirm:$true
                    $count++
                  } else {
                    Write-Host "Remove-ADGroup -Identity $samAccountName -Server $domain -Confirm:$true"
                  }
                 
                  Write-LogAndAlert -LogPath $logFilePath -content "Group Object ($samAccountName) Deleted from $domain."
                }
                catch {
                  Write-LogAndAlert -LogPath $logFilePath -content "Error Deleting Group Object ($samAccountName)."
                  Write-LogAndAlert -LogPath $logFilePath -content $_ -ErrorLevel 2
                  Get-ErrorCounter -increment
                }
              } else {
                try {
                  if ($makeChanges) {
                    Remove-ADGroup -Identity $samAccountName -Server $domain -Confirm:$false
                    $count++
                  } else {
                    Write-Host "Remove-ADGroup -Identity $samAccountName -Server $domain -Confirm:$false"
                  }
                  Write-LogAndAlert -LogPath $logFilePath -content "Group Object ($samAccountName) Deleted from $domain."
                } catch {
                    Write-LogAndAlert -LogPath $logFilePath -content "Error Deleting Group Object. - $samAccountName"
                    Write-LogAndAlert -LogPath $logFilePath -content $_ -ErrorLevel 2
                    Get-ErrorCounter -increment
                }
            }
          }
          else {
            try {
              Remove-ADGroup -Identity $samAccountName -Server $domain -WhatIf
            }
            catch {
              Write-Host "Error finding group object ($samAccountName).  Skipping."
              Write-Host $_
            }
          }
      }
      else {
          Write-LogAndAlert -LogPath $logFilePath -content "Type not recognized.  Skipping."
          continue
      }
      Write-Host "Safety Count: $count of $changeLimit changes made."
  }

  Write-LogAndAlert -LogPath $logFilePath -content "Bulk Delete user/group objects finished"
  Open-ErrorLog $logFilePath
  Clear-Host
}