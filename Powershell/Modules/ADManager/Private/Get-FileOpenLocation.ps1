function Get-FileOpenLocation ($location, $type) {
    $fileTypeExtended = @{
      '.txt' = 'Text documents (.txt)|*.txt'
      '.csv' = 'CSV UTF-8 (Comma delimited) (*.csv)|*.csv'
    }
  
    # Set file open Location
    [void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.forms")
    $dlg = New-Object System.Windows.Forms.OpenFileDialog
    
    if ($location) {
      $dlg.InitialDirectory = $location
    }
    else {
      $dlg.InitialDirectory = [Environment]::GetFolderPath('Desktop')
    }
  
    if ($type) {
      $dlg.DefaultExt = $type # file extension
      if ($fileTypeExtended.ContainsKey($type)) {
        $dlg.Filter = $fileTypeExtended[$type] # Filter files by extension
      }
      else {
        $dlg.Filter = "All Files (*.*)|*"
      }
    }
  
    # Show open file dialog box
    $result = $dlg.ShowDialog()
  
    # Process save file dialog box results
    if ($result) {
      # Save document
      $filepath = $dlg.FileName
    }
    else {
      Write-Host "ERROR: No file selected!"
    }
  
    return $filepath
  }