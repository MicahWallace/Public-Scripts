function Get-DomainOfGroup {
    param (
        [Parameter(Mandatory)]
        [string]$groupname
    )
    
    $AllDomains = Get-AllDomains
    $domain = @()
    Write-Host "Searching for domain group is in..."

    foreach ($d in $AllDomains){
        try {
            $domain += Get-ADGroup $groupname -Server $d -Properties CanonicalName | Select-Object @{N='Domain';E={($_.CanonicalName -split '/')[0]}} | Select-Object -ExpandProperty Domain
        }
        catch {
            continue
        }
    }
    If ($domain.count -gt 1){
        Write-Host "ERROR - Group ($groupname) found in more than one Domain"
        Write-Host $domain
        #TODO Build Dynamic picker
        pause
    } elseif (!$domain) {
        Write-Host "Unable to find group in Domains"
        Return $null
    } else {
        Write-Host "Group found in domain $($domain[0])"
        Return $domain[0]
    }
}