function Update-LastLogin {
    Write-Host "Select source file..."
    $uploadFile = Get-FileOpenLocation -type ".csv" -location "C:\Temp"
  
    Clear-Host
  
    if (!$uploadFile) {
      Write-Host "No File Selected...Exiting"
      Break
    }
  
    Write-LogAndAlert -content "Update Last Login Started"
    Write-LogAndAlert -content "Upload File: $uploadFile"
    Get-ErrorCounter -reset
  
    # Import CSV
    $csvFile = import-csv -Path $uploadFile
  
    # Get all Domain Controllers
    $AllDCs = @()
    $AllDCs = Get-AllDomainControllers
  
    foreach ($record in $csvFile) {
      $DCInfo = Get-ADDomainController -Discover -Domain $record.Domain
      $DC = $DCInfo.Name + "." + $DCInfo.Domain
      $currentLastLogon = [DateTime]$record.LastLogon
  
      Write-LogAndAlert -content "Checking $($record.SamAccountName)"
  
      # Check if Account exists
      if (!(Get-ADUser -Filter "sAMAccountName -eq '$($record.sAMAccountName)'" -Server $DC)) {
        #Write-Host "$account - User does not exist."
        Write-LogAndAlert -content "$($record.sAMAccountName) - User does not exist."
        continue
      }
  
      # Get Last Login data
      $Lastlogon = Get-LastLogonDT $record.SamAccountName $record.domain $AllDCs
  
      $userRow = [array]::IndexOf($csvFile.SamAccountName, $record.SamAccountName)
      
      # Check if user was not found in csv
      if ($userRow -eq "-1"){
        continue
      }
  
      if ($Lastlogon -gt $currentLastLogon){
        $csvFile[$userRow].LastLogon = $Lastlogon
        Write-LogAndAlert -content "Updated Last Login for $($record.SamAccountName) from $currentLastLogon to $LastLogon"
      } 
    }
    # Export CSV File
    $csvFile | Export-csv -Path $uploadFile
    
  }