function Get-ADManagerConfigFile {
    param (
        [Parameter(Mandatory=$false)]
        [string]$Path
    )
    
    # default path
    $defualtPath = "$env:USERPROFILE\Documents\ADManager\config.txt"

    $config = @{}

    # check if $Path exists
    if ($Path) {
        Write-Host "Config file passed in ($Path).  Checking if file exists." -ForegroundColor Green
        if (Test-Path $Path) {
            Write-Host "Config file found at $Path.  Loading values." -ForegroundColor Green
        }
    } else {
        $Path = $defualtPath
    }

    # check if $defaultPath exists
    if (Test-Path $Path) {
        Write-Host "Config file found at $Path.  Loading values." -ForegroundColor Green
        Get-Content $Path | ForEach-Object {
            # Skip comments and empty lines
            if ($_ -notmatch '^\s*#' -and $_ -ne '') {
                $key, $value = $_ -split '=', 2
                $config[$key] = $value
            }
        }

        if ($config.Count -eq 0) {
            Write-Host "Config file is empty or no values are defined." -ForegroundColor Yellow
        }

        if ($config['MasterConfigPath']) {
            $Path = $config['MasterConfigPath']

            if (Test-Path $Path) {
                Write-Host "Master config file found at $Path.  Loading values." -ForegroundColor Green
                Write-Host "Any duplicate values will be overwritten with Master config values." -ForegroundColor Yellow
                Get-Content $Path | ForEach-Object {
                    # Skip comments and empty lines
                    if ($_ -notmatch '^\s*#' -and $_ -ne '') {
                        $key, $value = $_ -split '=', 2
                        $config[$key] = $value
                    }
                }
            }
        }
    } else {
        Write-Host "Config file not found at $Path.  Creating new config file." -ForegroundColor Yellow

        # create new config file
        New-ConfigFile -Path $defualtPath

        # load config file
        Get-ADManagerConfigFile -Path $defualtPath
    }
    $Script:Config = $config
}