function Get-AllDomains {
    if ($script:domains) {
        return $script:domains
    }

    # Ensure the $script:config variable exists and contains the 'Domains' key
    if ($null -eq $script:config -or -not $script:config.ContainsKey('Domains')) {
        Write-Host "Config file is empty or no Domain values are defined." -ForegroundColor Yellow
    }

    # Get all domains in the current Forest
    $AllDomains = (Get-ADForest).Domains | ForEach-Object { $_.ToLower() }

    Write-Host "Found $($AllDomains.Count) domains in the current Forest." -ForegroundColor Green

    # Write host each domain found
    $AllDomains | ForEach-Object { Write-Host $_ }

    if ($script:config.ContainsKey('Domains')) {
        Write-Host "Found $($script:config['Domains'].Split(',').Count) domains in the config file." -ForegroundColor Green

        # Write host each domain found
        $script:config['Domains'].Split(',') | ForEach-Object { Write-Host $_.Trim() }

        # Add domains from the $script:config variable
        $additionalDomains = $script:config['Domains'].Split(",") | ForEach-Object { $_.Trim().ToLower() }
        $AllDomains += $additionalDomains

        # Get unique domains
        $AllDomains = $AllDomains | Sort-Object | Get-Unique
        
        Write-Host "Found $($AllDomains.Count) unique domains in the current Forest and config file." -ForegroundColor Green
        Write-Host "Unique domains found:"
        $AllDomains | ForEach-Object { Write-Host $_ }
    }

    # Return unique domains
    $script:domains = $AllDomains | Sort-Object | Get-Unique
    Write-Host "Saved $($script:domains.Count) unique domains to the script variable 'domains'." -ForegroundColor Green
    return $AllDomains
}
