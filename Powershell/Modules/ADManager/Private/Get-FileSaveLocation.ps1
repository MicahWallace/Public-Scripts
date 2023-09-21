function Get-FileSaveLocation ($name, $type) {
    $fileTypeExtended = @{
      '.txt' = 'Text documents (.txt)|*.txt'
      '.csv' = 'CSV UTF-8 (Comma delimited) (*.csv)|*.csv'
    }
  
    # Set Save Location
    [void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.forms")
    $dlg = New-Object System.Windows.Forms.SaveFileDialog
    if ($name) {
      $dlg.FileName = $name # Default file name
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
  
    # Show save file dialog box
    $result = $dlg.ShowDialog()
  
    # Process save file dialog box results
    if ($result) {
      # Save document
      $filepath = $dlg.FileName
    }
    else {
      Write-Host "ERROR: No file set!"
    }
  
    return $filepath
  }