function Get-DomainOfUser {
    param (
        [Parameter(Mandatory)]
        [string]$username,
        [Parameter(Mandatory=$false)]
        [bool]$silent = $false
    )

    $AllDomains = Get-AllDomains
    #Write-Host $AllDomains
    $domain = @()
    Write-Host "Searching for domain $username is member of..."

    foreach ($d in $AllDomains){
        #$dc = Get-ADDomainController -Discover -DomainName $d | Select-Object -ExpandProperty Hostname
        try {
            try {
                $dc = Get-ADDomainController -Discover -DomainName $d | Select-Object -ExpandProperty Hostname
            } catch {
                Write-Host "Unable to find DC for $d"
                continue
            }
            #write-host "Username:$username - DC:$dc"
            $domain += Get-ADUser $username -Server $dc -Properties CanonicalName | Select-Object @{N='Domain';E={($_.CanonicalName -split '/')[0]}} | Select-Object -ExpandProperty Domain
        }
        catch {
            continue
        }
    }
    if ($silent = $false) {
        If ($domain.count -gt 1){
            $domainNumber = 1
            Write-Host "ERROR - User ($username) found in more than one Domain"
            Write-Host "    ========================================"
            foreach ($d in $domain){
                Write-Host "[$domainNumber] - $d"
                $domainNumber++
            }
            $selectedDomain = Read-Host "Enter number of Domain to use"
            if ($selectedDomain -le $domain.count){
                $domainNumber = $selectedDomain - 1
                $selectedDomain = $domain[$domainNumber]
                Write-Host "Selected domain: $selectedDomain"
                Return $selectedDomain
            } else {
                Write-Host "Invalid selection"
            }
            Return $null
        } elseif (!$domain) {
            Write-Host "Unable to find user in any domain"
            Return $null
        } else {
            Write-Host "User found in domain $($domain[0])"
            Return $domain[0]
        }
    } else {
        if ($domain) {
            Return $domain
        } else {
            Write-Host "Unable to find user in any domain"
        }
    }
    
}