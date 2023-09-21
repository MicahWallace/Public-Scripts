function Get-AllDomainControllers {

  # If $script:AllDCs exists, return it
  if ($script:AllDCs) {
    return $script:AllDCs
  }

  # Add all Domains and DCs
  $AllDCs = @()
  $AllDomains = Get-AllDomains
  foreach ($Domain in $AllDomains) {
    try {
      $dcs = Get-ADDomainController -Filter * -Server $Domain | ForEach-Object { $_.HostName.ToLower() }
      
      # Filter to only those DCs that are online
      $onlineDCs = $dcs | Where-Object {
        try {
          Test-Connection -ComputerName $_ -Count 1 -Quiet
        }
        catch {
          Write-LogAndAlert -content "Error testing connection to $_ : $($_.Exception.Message)" -ErrorLevel 2
          $false # Make sure to return $false to filter out the offline DC from the results
        }
      }
    

      $AllDCs += $onlineDCs
    }
    catch {
      #write-host "Error searching for DCs in domain $Domain" -ForegroundColor Red
      Write-LogAndAlert -content "Error searching for DCs in domain $Domain - $_" -ErrorLevel 2
    }
  }
  $script:AllDCs = $AllDCs | Sort-Object | Get-Unique
  Return $AllDCs
}
