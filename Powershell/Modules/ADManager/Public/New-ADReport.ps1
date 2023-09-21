function New-ADReport {
    Write-LogAndAlert -content "Run Report Started"
    $StartTime = get-date
    $date = (Get-Date).ToString("yyyyMMdd_HHmmss")
    $filename = "AD_User_Object_Export_" + $date + ".csv"
  
    Write-Host "Opening File Save Dialog..."
    $outputFile = Get-FileSaveLocation -name $filename -type ".csv"
  
    if (!$outputFile) {
      Write-Host "Error: No Filepath set"
      break
    }
  
    
    # Should we search all Domains?
    $searchDomains = @()

    $allDomains = Get-AllDomains
    Write-Host "Found $($allDomains.Count) domains." -ForegroundColor Green
    $allDomains | ForEach-Object { Write-Host $_ }

    # Ask if all domains should be searched and if yes, add all domains to the searchDomains array
    $searchAllDomains = Read-Host "Should all domains be searched? Y/N"
    if ($searchAllDomains -eq "Y") {
      $searchDomains = $allDomains
    }
    else {
      # for each domain in allDomains, ask if it should be searched and if yes, add it to the searchDomains array
      foreach ($domain in $allDomains) {
        $searchDomain = Read-Host "Should $domain be searched? Y/N"
        if ($searchDomain -eq "Y") {
          $searchDomains += $domain
        }
      }
    }

    # If no domains were selected, exit the script
    if ($searchDomains.Count -eq 0) {
      Write-Host "No domains selected. Exiting script."
      break
    }
  
    # Ask if we want to get last logon info from Domain Controllers
    $logonInfo = Read-Host "Do you want to search Domain Controllers for last logon info for each user? CAUTION: This takes a long time!! [Y/N]"
    if ($logonInfo -eq 'Y') {
      $logonInfo = $True
    }
    else {
      $logonInfo = $false
    }
  
    # Ask if we want to get last logon info from a saved file
    if (!$logonInfo) {
      $savedlogonInfo = Read-Host "Do you want to import last logon info from a previous file? [Y/N]"
      if ($savedlogonInfo -eq 'Y') {
        $savedlogonInfo = $True
        $uploadFile = Get-FileOpenLocation -type ".csv" -location "C:\Temp"
        $importLogonData = Import-Csv -Path $uploadFile
      }
      else {
        $savedlogonInfo = $false
      }
    }
    else {
      $savedlogonInfo = $false
    }
  
    # Ask if we want to get last logon info from a second saved file
    if (!$logonInfo -and $savedlogonInfo) {
      $savedlogonInfo2 = Read-Host "Do you want to import last logon info from a backup previous file? [Y/N]"
      if ($savedlogonInfo2 -eq 'Y') {
        $savedlogonInfo2 = $True
        $uploadFile2 = Get-FileOpenLocation -type ".csv" -location "C:\Temp"
        $importLogonData2 = Import-Csv -Path $uploadFile2
      }
      else {
        $savedlogonInfo2 = $false
      }
    }
    else {
      $savedlogonInfo2 = $false
    }
  
    # Ask if we want to get last logon info from Domain Controllers for any users that are not in the saved file
    if ($savedlogonInfo) {
      $missingLogonInfo = Read-Host "Do you want to search Domain Controllers for last logon info not in the saved file? [Y/N]"
      if ($missingLogonInfo -eq 'Y') {
        $missingLogonInfo = $True
      }
      else {
        $missingLogonInfo = $false
      }
    }
    
    
    
    Write-Host ">>>>>>> Starting to build Report..."
  
    $AllDCs = @()
    if ($logonInfo -or $missingLogonInfo) {
      # Get all Domain Controllers list if we answered yes to Search all or missing
      Write-Host "Getting list of Domain Controllers..."
      $AllDCs = @()
      $AllDCs = Get-AllDomainControllers
    }
    
  
    #$data = {}
    foreach ($domain in $searchDomains) {
      Write-Host "Searching Domain: $domain"
      $dc = Get-ADDomainController -Discover -DomainName $domain
      $fullDc = -join ($dc, ".", $domain)
      Write-Host "Getting Users From DC: $fullDc"
      if ($dc) {
        # Only get the Properties we need. Faster but must set all needed.
        $users = Get-ADUser -Server $fullDc -Filter * -Properties Name, userPrincipalName, employeeType, extensionAttribute1, office, Department, Manager, enabled, employeeNumber, employeeID, passwordlastset, passwordneverexpires, whenCreated, whenChanged, description, DistinguishedName, mail, msDS-UserPasswordExpiryTimeComputed, physicalDeliveryOfficeName, AccountExpirationDate, accountExpires
        # Below gets all properties but is slower than above
        #$users = Get-ADUser -Server $fullDc -Filter * -Properties *
      }
      else {
        break
      }
        
      $numUsers = ($users).count
      $currentUser = 0
      foreach ($user in $users) {
        $ReportLine = [PSCustomObject] @{}
        $userDataHash = @{}
        $Lastlogon = $null
        $passwordExpiryDate = $null
        $accountExpiryDate = $null
        $currentUser += 1
        Write-Host $currentUser " of " $numUsers " in " $domain " - " $user.name
  
        if ($logonInfo) {
          #Get last logon info
          $Lastlogon = Get-LastLogonDT $user $domain $AllDCs -quiet
        }
        else {
          if ($savedlogoninfo) {
            # Import Last Logon from a previous file
            $Lastlogon = $importLogonData | Where-Object { $_.domain -eq $domain } | Where-Object { $($user.SamAccountName) -eq $_.SamAccountName } | Select-Object $_.LastLogon -ExpandProperty LastLogon
            if ($Lastlogon) {
              try {
                $Lastlogon = [datetime]$Lastlogon
              }
              catch {
                $Lastlogon = $null
              }
            }
            # Get Last Logon from secondary Import file
            if (!$Lastlogon) {
              if ($savedlogonInfo2) {
                $Lastlogon = $importLogonData2 | Where-Object { $_.domain -eq $domain } | Where-Object { $($user.SamAccountName) -eq $_.SamAccountName } | Select-Object $_.LastLogon -ExpandProperty LastLogon
                if ($Lastlogon) {
                  try {
                    $Lastlogon = [datetime]$Lastlogon
                  }
                  catch {
                    $Lastlogon = $null
                  }
                }
              }
            }
            if (!$LastLogon) {
              if ($missingLogonInfo) {
                $Lastlogon = Get-LastLogonDT $user $domain $AllDCs -quiet
              }
              else {
                $Lastlogon = "Not Queried"
              }
                  
            }
          }
          else {
            $Lastlogon = "Not Queried"
          }
        }
  
        if (!$user.passwordneverexpires){
          $passwordDateRaw = $user."msDS-UserPasswordExpiryTimeComputed"
          try {
            $passwordExpiryDate = [datetime]::FromFileTime($passwordDateRaw)
          } catch {
            $passwordExpiryDate = "Invalid Date"
          }
          
        }

        # Account Experation Info
        if ($user.accountExpires -gt 0 -and $user.accountExpires -ne 9223372036854775807){
          $accountExpiryDate = $user.AccountExpirationDate
        } else {
          $accountExpiryDate = "Never Expires"
        }
  
        # Description Info to Team Owner
        $userDataDescription = $user.Description
        $owner = $null
        $team = $null
        
        if ($userDataDescription){
          if ($userDataDescription.Contains(";")) {
            $userDataArray = $userDataDescription.split(";")
            foreach ($item in $userDataArray) {
              if ($item.Contains(":")){
                $userObject = $item.split(":", 2)
                $userDataHash += @{$userObject[0].Trim() = $userObject[1].Trim() }
              } else {
                try {
                  $userDataHash += @{"Notes" = $item.Trim()}
                } catch {
                  Write-Host "Unknown Item: $item"
                }
              }
            }
            if ($userDataHash.Keys -contains "Owner"){
              $owner = $userDataHash.owner
            }
            if ($userDataHash.Keys -contains "Team"){
              $team = $userDataHash.team
            }
          }
        }
  
        #Write-Host $user
        $ReportLine = [PSCustomObject] @{
          SamAccountName       = $user.SamAccountName
          UserPrincipalName    = $User.UserPrincipalName
          Email                = $User.mail
          Name                 = $User.Name
          EmployeeType         = $User.employeeType
          extensionAttribute1  = $User.extensionAttribute1
          Enabled              = $user.Enabled
          Description          = $user.description
          Owner                = $owner
          Team                 = $team
          LastLogon            = $Lastlogon
          PasswordLastSet      = $user.passwordlastset
          PasswordNeverExpires = $user.passwordneverexpires
          PasswordExpiry       = $passwordExpiryDate
          AccountExpiry        = $accountExpiryDate
          WhenCreated          = $user.whenCreated
          WhenChanged          = $user.whenChanged
          EmployeeID           = $user.EmployeeID
          EmployeeNumber       = $user.EmployeeNumber
          PhysicalDeliveryOffice = $user.physicalDeliveryOfficeName
          Office               = $User.Office
          Department           = $User.Department
          Manager              = $User.manager
          DistinguishedName    = [regex]::match($($user.DistinguishedName), '(?=OU)(.*\n?)(?<=.)').Value
          Domain               = $domain
        }
            
        $ReportLine | Export-CSV -NoTypeInformation -Encoding UTF8 $outputFile -Append
      }
        
    }
  
    Write-LogAndAlert -content "Run Report Finished"
    $RunTime = New-TimeSpan -Start $StartTime -End (get-date)
    $RunTimeOutput = "Execution time was {0} hours, {1} minutes, {2} seconds" -f $RunTime.Hours,  $RunTime.Minutes,  $RunTime.Seconds
    write-host $RunTimeOutput
    Write-LogAndAlert -content $RunTimeOutput
  
    # Ask if user wants to open saved file
    Write-Host "Report Generated and Saved to $outputFile"
    $openfile = Read-Host "Do you want to open the file? [Y/N]"
    if ($openfile -eq "Y") {
      Invoke-item -path $outputFile
    }
  }
  