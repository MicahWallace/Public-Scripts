function Get-LastLogonDT {
    [CmdletBinding()]
    param (
        [Parameter()]
        [String] $user,
        
        [Parameter()]
        [String] $Domain,
        
        [Parameter()]
        $AllDCs,

        # Shows all DC Results
        [Parameter()]
        [switch]
        $allResults,

        # do not show any output (used with reports)
        [Parameter()]
        [switch]
        $quiet,

        # log file location
        [Parameter(Mandatory=$false)]
        [string] $logPath = $null
    )

    # Convert User Object to Username which is SamAccountName
    $username = $user.SamAccountName
  
    # If Username is Null, a user vs a user object was passed so set to the user.
    if (!$username){$username = $user}

    # If no Domain was passed in, get domain of user.
    If (!$Domain){
      $Domain = Get-DomainOfUser -username $username
    }
  
    # //Must search aganst all DC's in domain to get true last logon date
    if (!$AllDCs) {
      # Add all Domains and DCs
      $AllDCs = Get-AllDomainControllers
    }
    
    $time = 0
    $timeFromDC = $null
    foreach ($dc in $AllDCs) {
      $currentDomain = $dc.Split(".", 2)
      if ($currentDomain[1] -like $Domain) {
        # Only check DCs in users forest if we know what Domain they are in
        try {
          $u = Get-ADUser $username -Server $dc | Get-ADObject -Server $dc -Properties lastLogon
          $tempDT = [DateTime]::FromFileTime($u.LastLogon)
          if ($allResults){
            write-Host ("$username - $dc - $tempDT")
          }
        }
        catch {
          if ($logPath) {
            Write-LogAndAlert -content "$dc - $_" -ErrorLevel 2 -LogPath $logPath
          } else {
            Write-LogAndAlert -content "$dc - $_" -ErrorLevel 2
          }
        }
        
        if ($u.LastLogon -gt $time) {
          $time = $u.LastLogon
          $timeFromDC = $dc
        }
        
      }
    }
    $dt = [DateTime]::FromFileTime($time)
    if ($quiet){
      if ($logPath) {
        Write-LogAndAlert -content "Last Login for $username from $timeFromDC - $dt" -quiet -LogPath $logPath
      } else {
        Write-LogAndAlert -content "Last Login for $username from $timeFromDC - $dt" -quiet
      }
    } else {
      if ($logPath) {
        Write-LogAndAlert -content "Last Login for $username from $timeFromDC - $dt" -LogPath $logPath
      } else {
        Write-LogAndAlert -content "Last Login for $username from $timeFromDC - $dt"
      }
      #Write-LogAndAlert -content "Last Login for $username from $timeFromDC - $dt"
    }
    Return $dt 
  }