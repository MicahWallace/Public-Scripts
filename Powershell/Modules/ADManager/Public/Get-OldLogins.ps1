function Get-OldLogins {

    $monthsOld = 6
    $excludeAccountTypes = @(
      "Employee",
      "Contractor"
    )
  
    $date = (Get-Date).ToString("yyyyMMdd_HHmmss")
    
    Write-Host "Select AD User Object Report File to upload..."
    $uploadFile = Get-FileOpenLocation -type ".csv" -location "C:\Temp"
  
    
    $filename = "Old_AD_User_Login_Report_" + $date + ".csv"
  
    $outputFile = Get-FileSaveLocation -name $filename -type ".csv"
  
    if (!$outputFile) {
      Write-Host "Error: No Filepath set"
      break
    }
  
    $setMonthsOld = Read-Host "Include accounts older than how many months? [press ENTER for Default of 6]"
    if ($setMonthsOld){
      $setMonthsOld = [int]$setMonthsOld
      if ($setMonthsOld -is [int]){
        $monthsOld = $setMonthsOld
      }
    }
    $monthsOldDate = (Get-Date).AddMonths(-$monthsOld)
  
    $noLogon = Read-Host "Should accounts with no last logon be included? Y/N"
    if ($noLogon -eq "Y"){
      $noLogon = $true
    } else {
      $noLogon = $false
    }
  
    $includeDisabled = Read-Host "Should disabled accounts be included? Y/N"
    if ($includeDisabled -eq "Y"){
      $includeDisabled = $true
    } else {
      $includeDisabled = $false
    }
  
    Write-Host "Looking for accounts older than $monthsOldDate"
  
    # Import CSV File
    Write-Host "Importing Data... Please Wait"
    $rawdata = Get-Content -Path $uploadFile | ConvertFrom-Csv
    Write-Host "Data Loaded... Starting to process"
  
    foreach ($line in $rawdata) {
      if ($excludeAccountTypes -contains $line.extensionAttribute1){
        # Account type is on the list to exclude
        #Write-Host "$($line.UserPrincipalName) - $($line.LastLogon) - TYPE EXCLUDE"
        continue
      }
  
      $lastLogon = [DateTime]$line.LastLogon
      if ($lastLogon -ge $monthsOldDate){
        # Last Login is less than cutoff date
        #Write-Host "$($line.UserPrincipalName) - $($line.LastLogon) - DATE EXCLUDE"
        continue
      }
      if ($lastLogon -eq [DateTime]"12/31/1600 6:00:00 PM"){
        # Account has never been logged in
        if (!$noLogon){
          # Exclude no login accounts
          continue
        }
      }
  
      if ($line.enabled -eq $false){
        if (!$includeDisabled){
          # Exclude disabled
          continue
        }
      }
      
  
      
      #Write-Host "$($line.extensionAttribute1) - $($line.SamAccountName) - $($line.LastLogon)"
      $line | Export-CSV -NoTypeInformation -Encoding UTF8 $outputFile -Append
      #Write-Host $line
      #Pause
    }
  
    # Ask if user wants to open saved file
    Write-Host "Report Generated and Saved to $outputFile"
    $openfile = Read-Host "Do you want to open the file? [Y/N]"
    if ($openfile -eq "Y") {
      Invoke-item -path $outputFile
    }
  }