function Open-ErrorLog ($LogPath){
  if (!$LogPath){
    # Default Log path if none is passed in.
    $LogPath = "C:\Windows\Temp\AD_Manager_Log.txt"
  }
  # Ask if user wants to open saved file
  Write-Host "Log file Saved to $LogPath"
  $openfile = Read-Host "Do you want to open the log file? [Y/N]"
  if ($openfile -eq "Y") {
    Invoke-item -path $LogPath
  }
}