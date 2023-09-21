function New-ConfigFile {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Path
    )

    # Default config text
    $defaultConfigText = @'
# This is the default config file for ADManager.  You can change the values below to your liking.
# If you want to use a master config file, you can specify the path to the master config file below.
# Any duplicate values will be overwritten with Master config values.
# All lines that start with a # are comments and will be ignored.
#
# Example:
#MasterConfigPath=C:\Users\username\Documents\ADManager\masterconfig.txt
#
# If you want to use a different config file, you can specify the path to the config file below.
# If you do not specify a path, the default path will be used.
#
# Example:
#ConfigPath=C:\Users\username\Documents\ADManager\config.txt
#
# If you have additional Domain that are not in the current Forest, you can specify them below.
# Separate each Domain with a comma.
#Domains=domain1.local,domain2.local,domain3.local
#
# If you want to use a different log file, you can specify the path to the log file below.
# If you do not specify a path, the default path will be used.
#
# Example:
#LogPath=C:\Users\username\Documents\ADManager\log.txt
#
'@

    Write-Host "Creating new config file at $Path" -ForegroundColor Green

    # Check if the directory path exists
    $directory = [System.IO.Path]::GetDirectoryName($Path)
    if (-not (Test-Path $directory)) {
        New-Item -Path $directory -ItemType Directory
        Write-Host "Created directory: $directory" -ForegroundColor Yellow
    }

    try {
        # Create the file
        # Write the default config text to the file
        $defaultConfigText | Out-File $Path -Encoding ascii

        # Open the file in notepad
        notepad $Path

        Write-Host "New config file created at $Path" -ForegroundColor Green
    } catch {
        Write-Host "Error creating file: $Path" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        pause
        return
    } 
    pause
}
