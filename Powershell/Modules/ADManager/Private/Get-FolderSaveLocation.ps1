# Open a folder picker dialog box and return the selected path
function Get-FolderSaveLocation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [string]$InitialDirectory = "C:\",
        [Parameter(Mandatory=$false)]
        [string]$Title = "Select a folder"
    )
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
    $objForm = New-Object System.Windows.Forms.FolderBrowserDialog
    $objForm.Rootfolder = "MyComputer"
    $objForm.SelectedPath = $InitialDirectory
    $objForm.Description = $Title
    $Show = $objForm.ShowDialog()
    if ($Show -eq "OK") {
        return $objForm.SelectedPath
    } else {
        Write-Host "No folder selected"
        return $null
    }
}