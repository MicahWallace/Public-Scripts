function Get-ErrorCounter {
    param (
      [switch] $increase,
      [switch] $reset
    )
  
    if ($increase.IsPresent -and $reset.IsPresent){
      Write-LogAndAlert -content "Can not reset and increase Error Counter at the same time" -ErrorLevel 2
      Break
    }
  
    if ($increase.IsPresent){
      $global:errorCount ++
      Write-LogAndAlert -content "Error Counter increased.  Current Error Count: $errorCount" -ErrorLevel 2
    } elseif ($reset.IsPresent) {
      $global:errorCount = 0
      Write-LogAndAlert -content "Error Counter reset." -ErrorLevel 3 -quiet
    } else {
      return $errorCount
    }
    
  }