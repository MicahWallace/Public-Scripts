Function Write-LogAndAlert {
  param (
      [Parameter(Mandatory=$true)] [string] $content, 
      [Parameter(Mandatory=$false)] [string] $ErrorLevel,
      [Parameter(Mandatory=$false)] [string] $LogPath,
      [switch] $quiet
  )

  if (!$LogPath){
    # Default Log path if none is passed in.
    $LogPath = "C:\Windows\Temp\AD_Manager_Log.txt"
  }

  $dt = Get-date -Format g

  $e = @{
      1 = 'FATAL';
      2 = 'ERROR';
      3 = 'INFO '
  }

  if (!$ErrorLevel){
    $ErrorLevel = 3
  }

  $ErrorValue = $e.$ErrorLevel
  if (!$ErrorValue) {
      $ErrorValue = $e.3
  }

  if (!$quiet.IsPresent){
    # Dont output to the screen
    switch ($ErrorLevel) {
      '1' { Write-Host "$ErrorValue - $content" -ForegroundColor Black -BackgroundColor Red }
      '2' { Write-Host "$ErrorValue - $content" -ForegroundColor Black -BackgroundColor Yellow }
      '3' { Write-Host "$ErrorValue - $content" -ForegroundColor Green }
      #Default {}
    }
  }
  

  #funcMainLog ($dt + ' - ' + $ErrorValue + ' - ' + $content)
  $LogContent = $dt + ' - ' + $ErrorValue + ' - ' + $content
  Out-File -filePath $LogPath -inputobject $LogContent -Append -force
}