function Convert-ADAuditReport {
    Write-Host "Select File to upload..."
    $uploadFile = Get-FileOpenLocation -type ".csv" -location "C:\Temp"
    
    #$rawdata = Import-Csv -Path $uploadFile
    # Skip 8 rows that are junk data
    $rawdata = Get-Content -Path $uploadFile | Select-Object -Skip 8 | ConvertFrom-Csv
  
    $rawdata = $rawdata | Select-Object -Property @{label = "SamAccountName"; expression = { $($_."User Name") } }, @{label = "LastLogon"; expression = { $($_."Logon Time") } }, @{label = "Domain"; expression = { $($_."Domain Controller".split(".", 2)[1]) } }
    #select -Property @{label="SamAccountName";expression={$($_."User Name")}},@{label="LastLogon";expression={$($_."Logon Time")}}
    
    $date = (Get-Date).ToString("yyyyMMdd_HHmmss")
    $filename = "converted_ADAudit+Logon_Data_" + $date + ".csv"
    $outputFile = Get-FileSaveLocation -name $filename -type ".csv"
    $rawdata | Export-CSV -NoTypeInformation -Encoding UTF8 $outputFile -Append
    
  }