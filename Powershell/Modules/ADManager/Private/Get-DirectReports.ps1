function Get-DirectReports {
    param (
        [Parameter(Mandatory)][string]$manager,
        [Parameter(Mandatory=$false)][string]$dc
    )
    
    Write-Host "Searching User: $manager"

    try {
        $reports = Get-ADUser -Server $dc -Identity $manager -Properties directreports | select-object -ExpandProperty DirectReports 
    }
    catch {
        $domain = Get-DomainOfUser -username $manager
        $dc = Get-ADDomainController -Discover -DomainName $domain | Select-Object -ExpandProperty Hostname

        $reports = Get-ADUser -Server $dc -Identity $manager -Properties directreports | select-object -ExpandProperty DirectReports 
    }

    foreach ($user in $reports) {  
        Write-Host $user.samaccountname
        Get-DirectReports $user $dc
    }  
    if ($reports) {
        return $reports  
    }  
}