<#
  Name:           ESXI Config Backup Utility
  Organization:   Confused IT Ltd.
  Version:        1.1.0
  Author:         Michael Accavallo
  Creation Date:  7/16/2022
  Modified:       Multi-vCenter support - per-vCenter credentials
  Changes:
    - SetConfig  : them nhieu vCenter (Name + Address)
    - SetCreds   : nhap credential rieng cho tung vCenter
    - RunConfig  : tu dong loop qua tung vCenter, backup doc lap
    (Tat ca phan khac giu nguyen 100%)
#>

#Script Flags
Param(
    [switch]$Run,
    [switch]$RunConfig,
    [switch]$SetCreds,
    [switch]$SetConfig,
    [switch]$Enable,
    [switch]$Disable
)

#Console Colors
$Host.UI.RawUI.BackgroundColor = ($bckgrnd = 'Black')
$Host.UI.RawUI.ForegroundColor = 'Cyan'
$Host.PrivateData.ErrorForegroundColor = 'Red'
$Host.PrivateData.ErrorBackgroundColor = $bckgrnd
$Host.PrivateData.WarningForegroundColor = 'Magenta'
$Host.PrivateData.WarningBackgroundColor = $bckgrnd
$Host.PrivateData.DebugForegroundColor = 'Yellow'
$Host.PrivateData.DebugBackgroundColor = $bckgrnd
$Host.PrivateData.VerboseForegroundColor = 'Green'
$Host.PrivateData.VerboseBackgroundColor = $bckgrnd
$Host.PrivateData.ProgressForegroundColor = 'Cyan'
$Host.PrivateData.ProgressBackgroundColor = $bckgrnd
Clear-Host

#Checks if running as admin.
function CheckAdmin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
    $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

if ((CheckAdmin) -eq $false)  {
    Write-Host -ForegroundColor Red "Please run as admin."
    Return
}

#Global Variables
$ScriptDirectory = "C:\Scripts\"
$FolderName = "ESXI-Config-Backup-Utility"
$FullPath = $ScriptDirectory + $FolderName
$CredPath = "$FullPath\Credentials"

#Tries to create EventLog
New-EventLog -Source "ESXI-Config-Backup-Utility" -LogName Application -ErrorAction SilentlyContinue
Write-Host -ForegroundColor White "------" -NoNewline; Write-Host -ForegroundColor Cyan "ESXI " -NoNewline; Write-Host -ForegroundColor White "Config Backup" -NoNewline; Write-Host -ForegroundColor Green " Utility" -NoNewline; Write-Host -ForegroundColor White "------";
Write-Host -ForegroundColor Green "-----------------Welcome!---------------"
Write-Host
Write-Host -ForegroundColor White "             #### Setup ####            "
Write-Host "   ---Anything in " -NoNewline; Write-Host -ForegroundColor Yellow "Yellow" -NoNewline; Write-Host " is" -NoNewline; Write-Host -ForegroundColor Red  " Required!" -NoNewline; Write-Host "---"
Write-Host

# [CHANGED] Hien thi trang thai credential theo tung vCenter
if (Test-Path -Path "$FullPath\config.json") {
    try {
        $cfgCheck = Get-Content "$FullPath\config.json" -Raw | ConvertFrom-Json
        $allCredsOk = $true
        foreach ($vc in $cfgCheck.Resources) {
            $hasKey  = Test-Path "$CredPath\$($vc.Name).key"
            $hasUser = Test-Path "$CredPath\$($vc.Name)_user.txt"
            $hasPass = Test-Path "$CredPath\$($vc.Name)_pass.txt"
            if ($hasKey -and $hasUser -and $hasPass) {
                Write-Host "  [" -NoNewline; Write-Host -ForegroundColor Green "OK" -NoNewline; Write-Host "] $($vc.Name) ($($vc.Address)) - credential set"
            } else {
                Write-Host "  [" -NoNewline; Write-Host -ForegroundColor Red "!!" -NoNewline; Write-Host "] $($vc.Name) ($($vc.Address)) - credential missing"
                $allCredsOk = $false
            }
        }
        if ($allCredsOk) {
            Write-Host "Use " -NoNewline; Write-Host -ForegroundColor White "-SetCreds" -NoNewline; Write-Host " to update credentials." -NoNewline
            Write-Host -ForegroundColor Green " -All Completed!"
        } else {
            Write-Host -ForegroundColor Yellow "Use " -NoNewline; Write-Host -ForegroundColor White "-SetCreds" -NoNewline; Write-Host -ForegroundColor Yellow " to set credentials for each vCenter." -NoNewline
            Write-Host -ForegroundColor Red " -Not Yet Completed!"
        }
    } catch {
        Write-Host -ForegroundColor Yellow "Use " -NoNewline; Write-Host -ForegroundColor White "-SetCreds" -NoNewline; Write-Host -ForegroundColor Yellow " to set host/vCenter credentials." -NoNewline
        Write-Host -ForegroundColor Red " -Not Yet Completed!"
    }
} else {
    Write-Host -ForegroundColor Yellow "Use " -NoNewline; Write-Host -ForegroundColor White "-SetCreds" -NoNewline; Write-Host -ForegroundColor Yellow " to set host/vCenter credentials." -NoNewline
    Write-Host -ForegroundColor Red " -Not Yet Completed!"
}

if (Test-Path -Path "$FullPath\config.json") {
    Write-Host "Use " -NoNewline; Write-Host -ForegroundColor White "-SetConfig" -NoNewline; Write-Host " to set the backup configuration." -NoNewline
    Write-Host -ForegroundColor Green " -Completed!"
    # Hien thi danh sach vCenter da cau hinh
    try {
        $cfgShow = Get-Content "$FullPath\config.json" -Raw | ConvertFrom-Json
        foreach ($vc in $cfgShow.Resources) {
            Write-Host -ForegroundColor Gray "   -> $($vc.Name)  $($vc.Address)"
        }
    } catch {}
} else {
    Write-Host -ForegroundColor Yellow "Use " -NoNewline; Write-Host -ForegroundColor White "-SetConfig" -NoNewline; Write-Host -ForegroundColor Yellow " to set the backup configuration." -NoNewline
    Write-Host -ForegroundColor Red " -Not Yet Completed!"
}

if (Get-ScheduledTask -TaskName "ESXI-Config-Backup-Utility" -ErrorAction SilentlyContinue) {
    Write-Host "Use " -NoNewline; Write-Host -ForegroundColor White "-Enable" -NoNewline; Write-Host " to turn the script on." -NoNewline
    Write-Host -ForegroundColor Green " -Currently Enabled!"
} else {
    Write-Host -ForegroundColor Yellow "Use " -NoNewline; Write-Host -ForegroundColor White "-Enable" -NoNewline; Write-Host -ForegroundColor Yellow " to turn the script on." -NoNewline
    Write-Host -ForegroundColor Red " -Not Enabled!"
}

Write-Host
Write-Host -ForegroundColor White "          #### Manual Flags ####         "
Write-Host "Use " -NoNewline; Write-Host -ForegroundColor White "-Run" -NoNewline; Write-Host " to manually have the script take backups (no config)."
Write-Host "Use " -NoNewline; Write-Host -ForegroundColor White "-RunConfig" -NoNewline; Write-Host " to manually have the script take backups (using config)."
Write-Host "Use " -NoNewline; Write-Host -ForegroundColor White "-Disable" -NoNewline; Write-Host " to turn off the script."
Write-Host "Please wait..."
Start-Sleep -s 4

#Installs PowerCLI Module
if (!(Get-InstalledModule VMware.PowerCLI -ErrorAction SilentlyContinue)) {
    try {
        Write-Host -ForegroundColor Yellow "Attempting install of PowerCLI module."
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
        Install-Module VMware.PowerCLI -AllowClobber -Force -SkipPublisherCheck
    } catch {
        Write-Host -ForegroundColor Red "VMware PowerCLI Module Install Failed."
        Write-EventLog -LogName "Application" -Source "ESXI-Config-Backup-Utility" -EventID 7 -EntryType Error -Message "VMware.PowerCLI module failed to install."
        Return
    }
}

#Ignoring Cert Errors
Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP $false -confirm:$false
Set-PowerCLIConfiguration -InvalidCertificateAction ignore -confirm:$false
Clear-Host

#Create Folder
if(!(Test-Path -Path $FullPath)) {
    New-Item -Name $FolderName -Path $ScriptDirectory -ItemType Directory | Out-Null
}
if(!(Test-Path -Path $CredPath)) {
    New-Item -Path $CredPath -ItemType Directory | Out-Null
}

# ================================================================
# [CHANGED] Set-Creds - Nhap credential rieng cho tung vCenter
# File luu: Credentials\{VCName}.key / {VCName}_user.txt / {VCName}_pass.txt
# ================================================================
function Set-Creds {
    if (!(Test-Path -Path "$FullPath\config.json")) {
        Write-Host -ForegroundColor Red "No config found. Please run -SetConfig first to add vCenters."
        Return
    }
    $config = Get-Content "$FullPath\config.json" -Raw | ConvertFrom-Json
    Write-Host
    Write-Host -ForegroundColor Cyan "Setting credentials for each vCenter..."
    Write-Host -ForegroundColor Gray "(Account can co quyen: read-only vCenter + Host.Config.Firmware)"
    Write-Host

    foreach ($vc in $config.Resources) {
        Write-Host -ForegroundColor Yellow "--- $($vc.Name)  ($($vc.Address)) ---"

        # Xoa file cu
        Remove-Item "$CredPath\$($vc.Name).key"      -Force -ErrorAction SilentlyContinue
        Remove-Item "$CredPath\$($vc.Name)_user.txt" -Force -ErrorAction SilentlyContinue
        Remove-Item "$CredPath\$($vc.Name)_pass.txt" -Force -ErrorAction SilentlyContinue

        # Tao AES key moi
        $Key = New-Object Byte[] 32
        [Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($Key)
        $Key | Out-File "$CredPath\$($vc.Name).key"

        Read-Host "  Username" | Set-Content "$CredPath\$($vc.Name)_user.txt"
        Read-Host "  Password" -AsSecureString |
            ConvertFrom-SecureString -Key (Get-Content "$CredPath\$($vc.Name).key") |
            Set-Content "$CredPath\$($vc.Name)_pass.txt"

        Write-Host -ForegroundColor Green "  Saved OK."
        Write-Host
    }
}

# ================================================================
# [CHANGED] Set-Configuration - Them nhieu vCenter (Name + Address)
# JSON luu: Resources:[{Name, Address},...], Settings:{...}
# ================================================================
function Set-Configuration {
    #Tests if config exists and warns user.
    do {
        if (Test-Path -Path "$FullPath\config.json") {
            Write-Host -ForegroundColor Red "A config file already exists!"
            $areSure = Read-Host "Are you sure you want to continue? [Yes/No]"
        } else {
            $areSure = "Yes"
        }
        if ($areSure -match "No") { Return }
    } while ($areSure -notmatch "Yes")

    # Thu thap danh sach vCenter
    $vcList = [System.Collections.Generic.List[hashtable]]::new()
    do {
        Write-Host
        Write-Host -ForegroundColor Cyan "--- vCenter #$($vcList.Count + 1) ---"
        $vcName    = Read-Host "  Name (e.g. VCENTER-P25)"
        $vcAddress = Read-Host "  IP or Hostname (e.g. 10.4.155.18)"
        $vcList.Add(@{ Name = $vcName; Address = $vcAddress })
        Write-Host -ForegroundColor Green "  Added: $vcName ($vcAddress)"
        $addMore = Read-Host "Add another vCenter? [Yes/No]"
    } while ($addMore -match "Yes")

    # Cai dat lich backup (dung chung cho tat ca vCenter)
    Write-Host
    $FrequencyInput = Read-Host "Backup Frequency - Enter 1 for Weekly or 2 for Daily"
    $Day = "N/A"
    if ($FrequencyInput -eq "1") {
        $DayInput = Read-Host "What day of the week? - 1=Monday 2=Tuesday 3=Wednesday 4=Thursday 5=Friday 6=Saturday 7=Sunday"
    }
    $Time      = Read-Host "What time of day? (Format = 3am / 9:30pm)"
    $Retention = Read-Host "Backup Retention - Enter 0 to keep all or the number of backups to keep per vCenter"

    switch ($FrequencyInput) {
        1 { $Frequency = 'Weekly' }
        2 { $Frequency = 'Daily'  }
        default { $Frequency = 'Error' }
    }
    switch ($DayInput) {
        1 { $Day = 'Monday'    } 2 { $Day = 'Tuesday'   }
        3 { $Day = 'Wednesday' } 4 { $Day = 'Thursday'  }
        5 { $Day = 'Friday'    } 6 { $Day = 'Saturday'  }
        7 { $Day = 'Sunday'    } default { $Day = 'N/A' }
    }

    Clear-Host
    Write-Host "vCenters:"
    foreach ($vc in $vcList) { Write-Host "  $($vc.Name)  ->  $($vc.Address)" }
    Write-Host "Frequency  = $Frequency"
    Write-Host "Day        = $Day"
    Write-Host "Time       = $Time"
    Write-Host "Retention  = $Retention backups per vCenter"
    $areSure = Read-Host "Are you Sure [Yes/No]"
    Clear-Host
    if ($areSure -notmatch "Yes") { Return }

    #Backs up existing config file.
    if (Test-Path -Path "$FullPath\config.json") {
        if (!(Test-Path -Path "$FullPath\ConfigBackup\")) {
            New-Item -Path $FullPath -Name "ConfigBackup" -ItemType Directory | Out-Null
        }
        Copy-Item -Path "$FullPath\config.json" -Destination "$FullPath\ConfigBackup\config.json-$(Get-Date -Format yyy-MM-dd-hh-mm-ss)"
    }

    # Build JSON Resources array
    $resourcesJson = ($vcList | ForEach-Object {
        "        { `"Name`": `"$($_.Name)`", `"Address`": `"$($_.Address)`" }"
    }) -join ",`n"

    $configData = @"
    {
        "Resources": [
$resourcesJson
        ],
        "Settings": {
            "Frequency": "$Frequency",
            "Day": "$Day",
            "Time": "$Time",
            "Retention": "$Retention"
        }
    }
"@

    #Tries to create the JSON config file.
    try {
        $configData | Set-Content "$FullPath\config.json" -Force -ErrorAction Stop
        Write-Host -ForegroundColor Green "Config Set Successfully ($($vcList.Count) vCenter(s))"
    } catch {
        Write-Host -ForegroundColor Red "Config Failed to Set"
    }
}

# ================================================================
# [CHANGED] Start-Backups - Loop qua tung vCenter, backup doc lap
# Logic ben trong moi vCenter giu nguyen nhu ban goc
# ================================================================
function Start-Backups($RunConfig) {
    if ($RunConfig) {
        #Trys to pull script configuration
        try {
            $config = Get-Content -Path "$FullPath\config.json" -Raw | ConvertFrom-Json -ErrorAction Stop
        } catch {
            Write-EventLog -LogName "Application" -Source "ESXI-Config-Backup-Utility" -EventID 4 -EntryType Error -Message "Failed to get configuration."
            Return
        }
        $Retention = $config.Settings.Retention

        # Loop qua tung vCenter
        foreach ($vc in $config.Resources) {
            $vcName    = $vc.Name
            $vcAddress = $vc.Address
            $vcBackupDir = "$FullPath\ESXI-Backups\$vcName"

            Write-Host
            Write-Host -ForegroundColor Cyan "########################"
            Write-Host -ForegroundColor Cyan "  $vcName  ($vcAddress)"
            Write-Host -ForegroundColor Cyan "########################"

            # Retention ap dung rieng cho tung vCenter
            if ($Retention -ne "0") {
                if (Test-Path -Path $vcBackupDir) {
                    $dirCount = (Get-ChildItem -Path $vcBackupDir -Directory -Force).Count
                    if ($dirCount -ge $Retention) {
                        $qtyToDelete = $dirCount - $Retention
                        Get-ChildItem $vcBackupDir | Sort-Object -Descending -Property CreationTime | Select-Object -Last $qtyToDelete | Remove-Item -Recurse -confirm:$false -Force
                    }
                }
            }

            # Load credential cua vCenter nay
            try {
                $Username   = Get-Content "$CredPath\$($vcName)_user.txt"
                $Pass       = Get-Content "$CredPath\$($vcName)_pass.txt" | ConvertTo-SecureString -Key (Get-Content "$CredPath\$($vcName).key")
                $credential = New-Object System.Management.Automation.PSCredential($Username, $Pass)
            } catch {
                Write-Host -ForegroundColor Red "  Failed to load credentials for $vcName. Run -SetCreds first."
                Write-EventLog -LogName "Application" -Source "ESXI-Config-Backup-Utility" -EventID 5 -EntryType Error -Message "Failed to get login information for $vcName."
                continue
            }

            # Ket noi va backup (logic giu nguyen nhu ban goc)
            try {
                Connect-VIServer $vcAddress -Credential $credential -ea "SilentlyContinue"

                Write-Host "######################## Creating Backup Directory ########################"
                if (!(Test-Path -Path $vcBackupDir)) {
                    New-Item -Path $vcBackupDir -ItemType Directory | Out-Null
                }

                Write-Host "######################## Getting ESXI Backups ########################"
                $Hosts = Get-VMHost
                Get-VMHostFirmware -vmhost $Hosts -BackupConfiguration -DestinationPath "$vcBackupDir\"

                if ((Get-VMHost).count -ne (Get-ChildItem -Path "$vcBackupDir\configBundle*.tgz").count) {
                    Write-Host -ForegroundColor Red "Backup failed for $vcName"
                } else {
                    Write-Host -ForegroundColor Green "Backups Successful for $vcName, config backup is located in $vcBackupDir\"
                }

                New-Item -Path $vcBackupDir -Name "Backups" -ItemType Directory | Out-Null
                Move-Item -Path "$vcBackupDir\configBundle*.tgz" -Destination "$vcBackupDir\Backups" | Out-Null
                Rename-Item -Path "$vcBackupDir\Backups" -NewName "Backups-$(Get-Date -Format yyy-MM-dd-hh-mm-ss)" | Out-Null

                Disconnect-VIServer * -Confirm:$false
            } catch {
                Write-Host -ForegroundColor Red "Failed to connect to $vcName ($vcAddress), this may indicate an issue with the network, credentials, or PowerCLI."
                Write-EventLog -LogName "Application" -Source "ESXI-Config-Backup-Utility" -EventID 2 -EntryType Warning -Message "Failed to connect to $vcName ($vcAddress)."
            }
        }

    } else {
        # -Run: thu cong, hoi tung thong tin nhu ban goc
        do {
            $Hostname = Read-Host "Enter IP or Hostname of ESXI host/vCenter "
            $areSure = Read-Host "Are you sure?" "[Y / N]"
            Clear-Host
        } while ($areSure -ne 'y')
        Clear-Host
        Write-Host "You will be prompted for credentials (If errors immediately follow, IP or Login may be incorrect)"

        try {
            Connect-VIServer $Hostname -ea "SilentlyContinue"

            Write-Host "######################## Creating Backup Directory ########################"
            if (!(Test-Path -Path "$FullPath\ESXI-Backups\")) {
                New-Item -Path "$FullPath\ESXI-Backups" -ItemType Directory
            }
            Write-Host "######################## Getting ESXI Backups ########################"
            $Hosts = Get-VMHost; Get-VMHostFirmware -vmhost $Hosts -BackupConfiguration -DestinationPath "$FullPath\ESXI-Backups\"

            if ((Get-VMHost).count -ne (Get-ChildItem -Path "$FullPath\ESXI-Backups\configBundle*.tgz").count) {
                Write-Host -ForegroundColor Red "Backup failed"
            } else {
                Write-Host -ForegroundColor Green "Backups Successful, config backup is located in $FullPath\ESXI-Backups\"
            }

            New-Item -Path "$FullPath\ESXI-Backups" -Name "Backups" -ItemType Directory | Out-Null
            Move-Item -Path "$FullPath\ESXI-Backups\configBundle*.tgz" -Destination "$FullPath\ESXI-Backups\Backups" | Out-Null
            Rename-Item -Path "$FullPath\ESXI-Backups\Backups" -NewName Backups-$(Get-Date -Format yyy-MM-dd-hh-mm-ss) | Out-Null
            Disconnect-VIServer * -Confirm:$false
        } catch {
            Write-Host -ForegroundColor Red "Failed to connect to vCenter, this may indicate an issue with the network, credentials, or PowerCLI."
            Write-EventLog -LogName "Application" -Source "ESXI-Config-Backup-Utility" -EventID 2 -EntryType Warning -Message "Failed to connect to vCenter, this may indicate an issue with the network, credentials, or PowerCLI."
        }
    }
}

#Runs Set-Creds Function
if ($SetCreds) {
    Set-Creds
}

#Runs Update-AzureDNs Function
if ($Run) {
    Start-Backups($false)
}

if ($RunConfig) {
    Start-Backups($true)
}

#Runs Set-Configuration Function
if ($SetConfig) {
    Set-Configuration
}

#Creates Scheduled Task (giu nguyen nhu ban goc)
if ($Enable) {
    try {
        $config = Get-Content -Path "$FullPath\config.json" -Raw | ConvertFrom-Json -ErrorAction Stop
    } catch {
        Write-EventLog -LogName "Application" -Source "ESXI-Config-Backup-Utility" -EventID 4 -EntryType Error -Message "Failed to get configuration."
        Return
    }

    $Frequency = $config.Settings.Frequency
    $Day       = $config.Settings.Day
    $Time      = $config.Settings.Time

    Copy-Item -Path $PSCommandPath -Destination "$FullPath\ESXI-Config-Backup-Utility.ps1" -ErrorAction SilentlyContinue
    if (!(Test-Path -Path "$FullPath\ESXI-Config-Backup-Utility.ps1")) {
        Write-Host -ForegroundColor Red "Script doesn't exist in $FullPath\ESXI-Config-Backup-Utility.ps1!"
        Return
    }
    if (!(Get-ScheduledTask -TaskName "ESXI-Config-Backup-Utility" -ErrorAction SilentlyContinue)) {
        # Kiem tra credential cua it nhat 1 vCenter
        $credsOk = $false
        foreach ($vc in $config.Resources) {
            if ((Test-Path "$CredPath\$($vc.Name).key") -and
                (Test-Path "$CredPath\$($vc.Name)_user.txt") -and
                (Test-Path "$CredPath\$($vc.Name)_pass.txt")) {
                $credsOk = $true; break
            }
        }
        if ($credsOk -and (Test-Path -Path "$FullPath\config.json")) {
            try {
                $executable = "powershell"
                $taskName   = "ESXI-Config-Backup-Utility"
                $Description = "ESXI Config Backup Utility by Confused IT Ltd."
                $action = New-ScheduledTaskAction -execute $executable -Argument "-NoProfile -ExecutionPolicy Unrestricted -File .\ESXI-Config-Backup-Utility.ps1 -RunConfig" -WorkingDirectory $FullPath
                if ($Frequency -eq 'Daily') {
                    $trigger = New-ScheduledTaskTrigger -Daily -At $Time
                } elseif ($Frequency -eq 'Weekly') {
                    $trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek $Day -At $Time
                }
                $settings = New-ScheduledTaskSettingsSet -StartWhenAvailable
                Register-ScheduledTask -TaskName $taskName -Trigger $trigger -Action $action -Setting $settings -description $description -User "NT AUTHORITY\SYSTEM" -RunLevel 1
                Write-Host -ForegroundColor Green "Script enabled."
            } catch {
                Write-Host -ForegroundColor Red "Failed to create task."
            }
        } else {
            Write-Host -ForegroundColor Red "Some setup steps have not been taken."
            Write-Host -ForegroundColor Red "Ensure host/vCenter Creds, Config, and PowerCLI Powershell Module exists."
            Return
        }
    } else {
        Write-Host -ForegroundColor Yellow "Script already enabled"
    }
}

#Removes Scheduled Task (giu nguyen nhu ban goc)
if ($Disable) {
    if (Get-ScheduledTask -TaskName "ESXI-Config-Backup-Utility" -ErrorAction SilentlyContinue) {
        try {
            Unregister-ScheduledTask "ESXI-Config-Backup-Utility" -Confirm:$false
            Write-Host -ForegroundColor Green "Script disabled"
        } catch {
            Write-Host -ForegroundColor Red "Failed to remove task."
        }
    } else {
        Write-Host -ForegroundColor Yellow "Script not enabled."
    }
}
