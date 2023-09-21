##################### Menu #####################
function Show-MainMenu {
  Write-Host -Object ""
  Write-Host -Object "                           ---- AD Manager ----"
  Write-Host -Object "                           ---- Main  Menu ----"
  Write-Host -Object ""                                                                 
  
  Write-Host " [ 1 ]: Press '1' for Search Menu"
  #Write-Host " [ 2 ]: Press '2' for Change Menu"
  Write-Host " [ 3 ]: Press '3' for Bulk Change Menu"
  Write-Host " [ 4 ]: Press '4' for Reports Menu"
  Write-Host " [ 5 ]: Press '5' to create a config file"
  Write-Host " [ M ]: Press 'M' for a list of all Commands in the Module"
  #Write-Host " [ H ]: Press 'H' for Help and about info."
  Write-Host ""
  Write-Host " [ Q ]: Press 'Q' to quit."
  Write-Host ""
}
  
function Show-ChangeMenu {
  Write-Host -Object ""
  Write-Host -Object "                           ---- AD Manager ----"
  Write-Host -Object "                          ---- Change  Menu ----"
  Write-Host -Object ""                                                                 
  
  Write-Host " [ 1 ]: Press '1' to "
  Write-Host " [ 2 ]: Press '2' to "
  Write-Host " [ 3 ]: Press '3' to "
  Write-Host " [ 4 ]: Press '4' to "
  Write-Host ""
  Write-Host " [ Q ]: Press 'Q' to go to Main Menu."
  Write-Host ""
}

function Show-BulkChangeMenu {
  Write-Host -Object ""
  Write-Host -Object "                           ---- AD Manager ----"
  Write-Host -Object "                        ---- Bulk Change Menu ----"
  Write-Host -Object ""                                                                 
  
  Write-Host " [ 1 ]: Press '1' to upload a list of users to disable"
  Write-Host " [ 2 ]: Press '2' to Upload extensionAttribute1 Data"
  Write-Host " [ 3 ]: Press '3' to Upload Description (Team / Owner) Data"
  Write-Host " [ 4 ]: Press '4' to bulk remove users and groups"
  Write-Host ""
  Write-Host " [ Q ]: Press 'Q' to go to Main Menu."
  Write-Host ""
}

function Show-SearchMenu {
  Write-Host -Object ""
  Write-Host -Object "                           ---- AD Manager ----"
  Write-Host -Object "                          ---- Search  Menu ----"
  Write-Host -Object ""                                                                 
  
  Write-Host " [ 1 ]: Press '1' to look up description data for a user"
  Write-Host " [ 2 ]: Press '2' to Search for Nested groups for a user"
  Write-Host " [ 3 ]: Press '3' to Search for Nested users/groups for a group"
  Write-Host " [ 4 ]: Press '4' to Search for Manager Direct Reports"
  Write-Host ""
  Write-Host " [ Q ]: Press 'Q' to go to Main Menu."
  Write-Host ""
}

function Show-ReportMenu {
  Write-Host -Object ""
  Write-Host -Object "                           ---- AD Manager ----"
  Write-Host -Object "                          ---- Report  Menu ----"
  Write-Host -Object ""                                                                 
  
  Write-Host " [ 1 ]: Press '1' to Run an AD All Users Report"
  Write-Host " [ 2 ]: Press '2' to convert an AD Audit+ User's Last Logon File to correct format"
  Write-Host " [ 3 ]: Press '3' to get a list of all users with no recient logins from AD All Users Report"
  Write-Host " [ 4 ]: Press '4' to Update Last Login Data in an AD All Users Report"
  Write-Host " [ 5 ]: Press '5' to Search for all objects (users/groups) that contain a value and export to csv"
  Write-Host ""
  Write-Host " [ Q ]: Press 'Q' to go to Main Menu."
  Write-Host ""
}
  
##################### Menu Manager #####################
function ADManagerMenu {
  Clear-Host
  Get-ADManagerConfigFile
  do {
    #Clear-Host
    Show-MainMenu
    $inputSelection = Read-Host " Please make a selection"
    switch ($inputSelection) {
      '1' {
        Clear-Host
        Get-SearchMenu
      } '2' {
        Clear-Host
        Get-ChangeMenu
      } '3' {
        Clear-Host
        Get-BulkChangeMenu
      } '4' {
        Clear-Host
        Get-ReportMenu
      } '5' {
        Clear-Host
        New-ConfigFile -Path "$env:USERPROFILE\Documents\ADManager\config.txt"
      } 'h' {
        Show-Help
      } 'm' {
        Get-command -module admanager | Sort-Object Name | Get-Help | Format-Table Name, Synopsis -Autosize
        pause
        Clear-Host
      } 'q' {
        Clear-Host
        return
      }
    }
  }
  until ($input -eq 'q')
}

function Get-ChangeMenu {
  do {
    #Clear-Host
    Show-ChangeMenu
    $inputSelection = Read-Host " Please make a selection"
    switch ($inputSelection) {
      '1' {
        Clear-Host
        
      } '2' {
        Clear-Host
        
      } '3' {
        Clear-Host
        
      } '4' {
        Clear-Host
        
      }
        'h' {
        Show-Help
      } 'q' {
        Clear-Host
        return
      }
    }
  }
  until ($input -eq 'q')
}

function Get-BulkChangeMenu {
  do {
    #Clear-Host
    Show-BulkChangeMenu
    $inputSelection = Read-Host " Please make a selection"
    switch ($inputSelection) {
      '1' {
        Clear-Host
        Write-Host " Bulk disable users"
        Get-BulkDisableAccounts
      } '2' {
        Clear-Host
        Write-Host " Upload extensionAttribute1 Data "
        Update-ExtensionAttribute1
      } '3' {
        Clear-Host
        Write-Host " Upload Team / Owner Data "
        Write-DescriptionData
      } '4' {
        Clear-Host
        Write-Host " Bulk remove users and groups "
        Remove-BulkUsersGroups
      }
        'h' {
        Show-Help
      } 'q' {
        Clear-Host
        return
      }
    }
  }
  until ($input -eq 'q')
}

function Get-SearchMenu {
  do {
    #Clear-Host
    Show-SearchMenu
    $inputSelection = Read-Host " Please make a selection"
    switch ($inputSelection) {
      '1' {
        Clear-Host
        Write-Host " Look up Description Data for User"
        Get-UserDescriptionData
      } '2' {
        Clear-Host
        Write-Host " Search for Nested groups for a user "
        Get-UserNestedGroup
      } '3' {
        Clear-Host
        Write-Host " Search for Nested groups for a group "
        Get-GroupNestedGroup
      } '4' {
        Clear-Host
        Write-Host " Search for Manager Direct Reports "
        Get-ManagerReports
      } 'q' {
        Clear-Host
        return
      }
    }
  }
  until ($input -eq 'q')
}

function Get-ReportMenu {
  do {
    #Clear-Host
    Show-ReportMenu
    $inputSelection = Read-Host " Please make a selection"
    switch ($inputSelection) {
      '1' {
        Clear-Host
        Write-Host " Running User Report "
        New-ADReport
      } '2' {
        Clear-Host
        Write-Host " Converting AD Audit+ File"                
        Convert-ADAuditReport
      } '3' {
        Clear-Host
        Write-Host " Look up user objects with no recient logins"
        Get-OldLogins
      } '4' {
        Clear-Host
        Write-Host " Update Last Login "
        Update-LastLogin
      } '5' {
        Clear-Host
        Write-Host " Search for Object in AD "
        Get-ObjectSearch
      } 'q' {
        Clear-Host
        return
      }
    }
  }
  until ($input -eq 'q')
}