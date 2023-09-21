function Get-ManagerReports () {
    #Start Quering#  
    $manager = Read-Host "Enter samaccountname"

    $date = (Get-Date).ToString("yyyyMMdd_HHmmss")
    $filename = "Direct_Reports_" + $manager + "_" + $date + ".csv"
    $outputFile = Get-FileSaveLocation -name $filename -type ".csv"

    $domain = Get-DomainOfUser -username $manager
    $dc = Get-ADDomainController -Discover -DomainName $domain | Select-Object -ExpandProperty Hostname

    $DirectReports = Get-DirectReports $manager $dc | ForEach-Object -Process {
            $user = $_
            Write-Host "User: $user"
            try {
                Get-ADUser -Server $dc -identity $user -Properties * | Select-Object samAccountName,userprincipalname,extensionAttribute1,DistinguishedName
            }
            catch {
                $domain = Get-DomainOfUser -username $user
                $dc = Get-ADDomainController -Discover -DomainName $domain | Select-Object -ExpandProperty Hostname
            
                Get-ADUser -Server $dc -identity $user -Properties * | Select-Object samAccountName,userprincipalname,extensionAttribute1,DistinguishedName
            }
        }
    
    #Output#
    $DirectReports | Export-csv -Path $outputFile -NoTypeInformation -Encoding UTF8
    
    # Ask if user wants to open saved file
    Write-Host "Report Generated and Saved to $outputFile"
    $openfile = Read-Host "Do you want to open the file? [Y/N]"
    if ($openfile -eq "Y") {
      Invoke-item -path $outputFile
    }
}