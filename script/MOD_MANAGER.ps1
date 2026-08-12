<#
.SYNOPSIS
    Ferium Mod & Modpack Management Environment
.DESCRIPTION
    A resilient interactive CLI wrapper for managing Minecraft mods and modpacks using Ferium.
    Implements robust error handling, batch processing, state recovery, and folder scanning.
#>

# Set UTF-8 encoding for Windows Console compatibility
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# 1. Environment Setup & Validation
$script:FeriumDir = Join-Path -Path $env:LOCALAPPDATA -ChildPath "Ferium"
$script:FeriumExe = Join-Path -Path $script:FeriumDir -ChildPath "ferium.exe"

function Get-ScriptConfig {
    $script:ConfigPath = "config.json"
    if (-not [string]::IsNullOrWhiteSpace($PSScriptRoot)) {
        $candidate = Join-Path -Path $PSScriptRoot -ChildPath "config.json"
        if (Test-Path -Path $candidate) {
            $script:ConfigPath = $candidate
        } elseif (Test-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath "..\config.json")) {
            $script:ConfigPath = Join-Path -Path $PSScriptRoot -ChildPath "..\config.json"
        } else {
            $script:ConfigPath = $candidate
        }
    }
    
    if (-not (Test-Path -Path $script:ConfigPath)) {
        $defaultConfig = [ordered]@{
            active_profile = "server"
            profiles = [ordered]@{
                server = [ordered]@{
                    path = "D:\Games\minecraft-server\mods"
                    mc_version = "26.2"
                    mod_loader = "fabric"
                }
                main = [ordered]@{
                    path = "%APPDATA%\.minecraft\mods"
                    mc_version = "26.2"
                    mod_loader = "fabric"
                }
            }
        }
        $jsonStr = $defaultConfig | ConvertTo-Json -Depth 5
        Set-Content -Path $script:ConfigPath -Value $jsonStr -Force
    }
    
    try {
        $rawJson = Get-Content -Path $script:ConfigPath -Raw
        $script:ConfigObj = $rawJson | ConvertFrom-Json
        $script:ActiveProfile = $script:ConfigObj.active_profile
        
        $profileData = $script:ConfigObj.profiles.PSObject.Properties[$script:ActiveProfile].Value
        
        if ($profileData -is [string]) {
            # Legacy string path fallback
            $script:MinecraftMods = [System.Environment]::ExpandEnvironmentVariables($profileData)
            $script:ActiveMcVersion = "26.2"
            $script:ActiveModLoader = "fabric"
        } elseif ($null -ne $profileData) {
            $script:MinecraftMods = [System.Environment]::ExpandEnvironmentVariables($profileData.path)
            $script:ActiveMcVersion = if (-not [string]::IsNullOrWhiteSpace($profileData.mc_version)) { $profileData.mc_version } else { "26.2" }
            $script:ActiveModLoader = if (-not [string]::IsNullOrWhiteSpace($profileData.mod_loader)) { $profileData.mod_loader } else { "fabric" }
        } else {
            $script:MinecraftMods = "$env:APPDATA\.minecraft\mods"
            $script:ActiveMcVersion = "26.2"
            $script:ActiveModLoader = "fabric"
        }
    } catch {
        Write-Host "[WARNING] Failed to parse config.json. Using fallback defaults." -ForegroundColor Yellow
        $script:ActiveProfile = "main"
        $script:MinecraftMods = "$env:APPDATA\.minecraft\mods"
        $script:ActiveMcVersion = "26.2"
        $script:ActiveModLoader = "fabric"
    }
    
    Ensure-FeriumProfile
}

function Set-InstanceSettings {
    Write-Host "`n[*] Configuring Instance Profile: [$script:ActiveProfile]" -ForegroundColor Cyan
    Write-Host "[*] Current Target Path: $script:MinecraftMods" -ForegroundColor Gray
    Write-Host "[*] Current MC Version : $script:ActiveMcVersion" -ForegroundColor Gray
    Write-Host "[*] Current Mod Loader : $script:ActiveModLoader" -ForegroundColor Gray
    
    $newVersion = (Read-Host "`nEnter Minecraft Version (press Enter to keep '$script:ActiveMcVersion')").Trim()
    if ([string]::IsNullOrWhiteSpace($newVersion)) {
        $newVersion = $script:ActiveMcVersion
    }
    
    $newLoader = (Read-Host "Enter Mod Loader [fabric/quilt/forge/neo-forge] (press Enter to keep '$script:ActiveModLoader')").Trim().ToLower()
    if ([string]::IsNullOrWhiteSpace($newLoader)) {
        $newLoader = $script:ActiveModLoader
    }
    
    $currentVal = $script:ConfigObj.profiles.PSObject.Properties[$script:ActiveProfile].Value
    if ($currentVal -is [string]) {
        $newObj = [ordered]@{
            path = $currentVal
            mc_version = $newVersion
            mod_loader = $newLoader
        }
        $script:ConfigObj.profiles.PSObject.Properties[$script:ActiveProfile].Value = $newObj
    } else {
        $currentVal.mc_version = $newVersion
        $currentVal.mod_loader = $newLoader
    }
    
    $jsonStr = $script:ConfigObj | ConvertTo-Json -Depth 5
    Set-Content -Path $script:ConfigPath -Value $jsonStr -Force
    
    Get-ScriptConfig
    Write-Host "`n[SUCCESS] Updated settings for profile [$script:ActiveProfile]!" -ForegroundColor Green
    Write-Host "[*] MC Version: $script:ActiveMcVersion | Mod Loader: $script:ActiveModLoader" -ForegroundColor Green
}

function Ensure-FeriumProfile {
    if (-not (Test-Path -Path $script:FeriumExe)) {
        return
    }
    
    if ([string]::IsNullOrWhiteSpace($script:ActiveProfile)) {
        $script:ActiveProfile = "main"
    }
    
    if ([string]::IsNullOrWhiteSpace($script:ActiveMcVersion)) {
        $script:ActiveMcVersion = "26.2"
    }
    
    if ([string]::IsNullOrWhiteSpace($script:ActiveModLoader)) {
        $script:ActiveModLoader = "fabric"
    }
    
    if (-not (Test-Path -Path $script:MinecraftMods)) {
        New-Item -ItemType Directory -Path $script:MinecraftMods -Force | Out-Null
    }
    
    $profilesOutput = & $script:FeriumExe profile list 2>&1 | Out-String
    $hasProfile = ($profilesOutput -match "(?m)^\s*$($script:ActiveProfile)\b") -or ($profilesOutput -match "(?m)^\s*$($script:ActiveProfile)\*")
    
    if (-not $hasProfile) {
        Write-Host "[*] Creating Ferium CLI profile '$script:ActiveProfile' (MC: $script:ActiveMcVersion | $script:ActiveModLoader)..." -ForegroundColor Cyan
        & $script:FeriumExe profile create --name $script:ActiveProfile --output-dir "$script:MinecraftMods" --mod-loader $script:ActiveModLoader --game-version $script:ActiveMcVersion | Out-Null
    } else {
        & $script:FeriumExe profile switch $script:ActiveProfile | Out-Null
    }
    
    & $script:FeriumExe profile configure --output-dir "$script:MinecraftMods" --mod-loader $script:ActiveModLoader --game-version $script:ActiveMcVersion | Out-Null
}

Get-ScriptConfig

# Configurable remote manifest URL (e.g. GitHub Gist raw URL)
$script:ManifestUrl = ""

# Set preference to Continue so PowerShell doesn't crash on standard CLI errors
$ErrorActionPreference = "Continue"

function Ensure-FeriumInstalled {
    if (-not (Test-Path -Path $script:FeriumExe)) {
        Write-Host "`n[*] Ferium executable not found. Auto-downloading ferium.exe..." -ForegroundColor Yellow
        if (-not (Test-Path -Path $script:FeriumDir)) {
            New-Item -ItemType Directory -Path $script:FeriumDir -Force | Out-Null
        }
        
        $zipUrl = "https://github.com/the-cursed-modpack/ferium/releases/latest/download/ferium-x86_64-pc-windows-msvc.zip"
        $zipPath = Join-Path -Path $script:FeriumDir -ChildPath "ferium.zip"
        
        try {
            Write-Host "[*] Downloading Ferium release from GitHub..." -ForegroundColor Cyan
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -UseBasicParsing
            
            Write-Host "[*] Extracting Ferium..." -ForegroundColor Cyan
            Expand-Archive -Path $zipPath -DestinationPath $script:FeriumDir -Force
            Remove-Item -Path $zipPath -Force -ErrorAction SilentlyContinue
            Write-Host "[SUCCESS] Ferium auto-installation complete!" -ForegroundColor Green
        } catch {
            Write-Host "[ERROR] Failed to auto-download Ferium: $_" -ForegroundColor Red
            Write-Host "Please ensure an active internet connection or manually place ferium.exe in $script:FeriumDir" -ForegroundColor Red
            Pause
            exit 1
        }
    }
}

Ensure-FeriumInstalled

function Get-ModManifest {
    param (
        [string]$FileName = "server-mods.txt"
    )
    
    $content = ""
    if (-not [string]::IsNullOrWhiteSpace($script:ManifestUrl) -and $FileName -eq "server-mods.txt") {
        try {
            Write-Host "[*] Fetching remote server mod manifest from URL..." -ForegroundColor Cyan
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            $content = Invoke-RestMethod -Uri $script:ManifestUrl -UseBasicParsing
        } catch {
            Write-Host "[WARNING] Failed to fetch remote manifest from $script:ManifestUrl : $_" -ForegroundColor Yellow
        }
    }
    
    if ([string]::IsNullOrWhiteSpace($content)) {
        $candidates = @()
        if (-not [string]::IsNullOrWhiteSpace($PSScriptRoot)) {
            $candidates += Join-Path -Path $PSScriptRoot -ChildPath $FileName
            $candidates += Join-Path -Path $PSScriptRoot -ChildPath "..\script\$FileName"
        }
        $candidates += "script\$FileName"
        $candidates += $FileName
        
        $localManifest = $null
        foreach ($path in $candidates) {
            if (Test-Path -Path $path) {
                $localManifest = $path
                break
            }
        }
        
        if ($localManifest) {
            Write-Host "[*] Reading local manifest from $localManifest..." -ForegroundColor Cyan
            $content = Get-Content -Path $localManifest -Raw
        } else {
            if ($FileName -ne "server-only-mods.txt") {
                Write-Host "[ERROR] No remote URL configured and local $FileName not found!" -ForegroundColor Red
            }
            return @()
        }
    }
    
    $mods = $content -split '[\r\n]+' | ForEach-Object { 
        $clean = ($_ -split '#')[0].Trim()
        if (-not [string]::IsNullOrWhiteSpace($clean)) {
            $clean
        }
    }
    return $mods
}

function Sync-ServerMods {
    Ensure-FeriumProfile
    
    Write-Host "`n[*] Starting Server Mod Synchronization..." -ForegroundColor Cyan
    Write-Host "[*] Target Profile: [$script:ActiveProfile]" -ForegroundColor Cyan
    Write-Host "[*] Target Mods Directory: $script:MinecraftMods" -ForegroundColor Gray
    
    if (-not (Test-Path -Path $script:MinecraftMods)) {
        New-Item -ItemType Directory -Path $script:MinecraftMods -Force | Out-Null
    }
    
    $mods = @()
    $mods += Get-ModManifest -FileName "server-mods.txt"
    
    if ($script:ActiveProfile -eq "server" -or $script:ActiveProfile -like "*server*" -or $script:MinecraftMods -like "*minecraft-server*") {
        Write-Host "[*] Server profile active: Including server-only mods..." -ForegroundColor Yellow
        $mods += Get-ModManifest -FileName "server-only-mods.txt"
    }
    
    if ($mods.Count -eq 0) {
        Write-Host "[WARNING] No mods found in manifest to sync." -ForegroundColor Yellow
        return
    }
    
    Write-Host "[*] Registering $($mods.Count) mods into Ferium profile..." -ForegroundColor Cyan
    $profileList = & $script:FeriumExe list 2>&1 | Out-String
    foreach ($mod in $mods) {
        if ($mod -match '^\d+$') {
            if ($mod -eq "308702" -and $profileList -match "MR\s+\w+\s+Mod Menu") {
                & $script:FeriumExe remove mOgUt4GM 2>&1 | Out-Null
            } elseif ($mod -eq "60089" -and $profileList -match "MR\s+\w+\s+Mouse Tweaks") {
                & $script:FeriumExe remove aC3cM3Vq 2>&1 | Out-Null
            } elseif ($mod -eq "324717" -and $profileList -match "MR\s+\w+\s+Jade") {
                & $script:FeriumExe remove nvQzSEkH 2>&1 | Out-Null
            }
        }
    }
    
    # Batch register all mods in a single process execution
    & $script:FeriumExe add $mods 2>&1 | Out-Null
    
    Write-Host "`n[*] Pulling mod binaries to $script:MinecraftMods..." -ForegroundColor Cyan
    & $script:FeriumExe upgrade
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`n[SUCCESS] Server mods successfully synchronized to $script:MinecraftMods!" -ForegroundColor Green
    } else {
        Write-Host "`n[ERROR] Mod upgrade completed with warnings or non-zero exit code: $LASTEXITCODE" -ForegroundColor Yellow
    }
}

function Switch-ActiveProfile {
    Write-Host "`n[*] Current Active Profile: [$script:ActiveProfile]" -ForegroundColor Cyan
    Write-Host "[*] Current Target Path: $script:MinecraftMods" -ForegroundColor Gray
    
    $profiles = @($script:ConfigObj.profiles.PSObject.Properties.Name)
    if ($profiles.Count -le 1) {
        Write-Host "[*] Adding secondary 'main' profile to configuration..." -ForegroundColor Yellow
        $script:ConfigObj.profiles | Add-Member -MemberType NoteProperty -Name "main" -Value "%APPDATA%\.minecraft\mods" -Force
        $profiles = @($script:ConfigObj.profiles.PSObject.Properties.Name)
    }
    
    $currentIndex = [array]::IndexOf($profiles, $script:ActiveProfile)
    $nextIndex = ($currentIndex + 1) % $profiles.Count
    $newProfile = $profiles[$nextIndex]
    
    $script:ConfigObj.active_profile = $newProfile
    $jsonStr = $script:ConfigObj | ConvertTo-Json -Depth 5
    Set-Content -Path $script:ConfigPath -Value $jsonStr -Force
    
    Get-ScriptConfig
    Write-Host "`n[SUCCESS] Switched active profile to: [$script:ActiveProfile]" -ForegroundColor Green
    Write-Host "[*] New Target Path: $script:MinecraftMods" -ForegroundColor Green
}

Set-Location -Path $script:FeriumDir

# 2. Main Execution Loop
while ($true) {
    Clear-Host
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "         Ferium Minecraft Mod Manager" -ForegroundColor Cyan
    Write-Host "   Target: [$script:ActiveProfile] (MC: $script:ActiveMcVersion | $script:ActiveModLoader)" -ForegroundColor DarkCyan
    Write-Host "   Path  : $script:MinecraftMods" -ForegroundColor Gray
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "  1. [SYNC] 1-Click Server Mod Sync (Auto-Fetch & Upgrade)" -ForegroundColor Green
    Write-Host "  2. [SWITCH] Switch Target Instance Profile [$script:ActiveProfile]" -ForegroundColor Cyan
    Write-Host "  3. Upgrade / Sync Existing Mods" -ForegroundColor Yellow
    Write-Host "  4. Add New Mod(s) [Batch Supported]" -ForegroundColor Yellow
    Write-Host "  5. Add New Mod(s) AND Upgrade All" -ForegroundColor Yellow
    Write-Host "  6. List Currently Tracked Mods" -ForegroundColor Yellow
    Write-Host "  7. Remove a Tracked Mod" -ForegroundColor Red
    Write-Host "  8. Add / Configure & Upgrade a Modpack" -ForegroundColor Magenta
    Write-Host "  9. Scan Folder for Untracked Mods" -ForegroundColor Green
    Write-Host " 10. [CONFIG] Configure Active Instance Settings [MC Version / Loader]" -ForegroundColor DarkYellow
    Write-Host " 11. Exit" -ForegroundColor Gray
    Write-Host "==========================================" -ForegroundColor Cyan

    $choice = Read-Host "`nSelect an option (1-11)"

    switch ($choice) {
        "1" {
            Sync-ServerMods
        }
        "2" {
            Switch-ActiveProfile
        }
        "3" {
            Write-Host "`n[*] Checking for mod updates for profile [$script:ActiveProfile]..." -ForegroundColor Cyan
            & $script:FeriumExe upgrade
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "`n[SUCCESS] Mods synchronized successfully to $script:MinecraftMods!" -ForegroundColor Green
            } else {
                Write-Host "`n[ERROR] Upgrade failed with Exit Code: $LASTEXITCODE. Review the Ferium output above." -ForegroundColor Red
            }
        }
        "4" {
            $inputString = (Read-Host "`nEnter Modrinth slugs or CF IDs (separate by space or comma)").Trim()
            if (-not [string]::IsNullOrWhiteSpace($inputString)) {
                $mods = $inputString -split '[\s,]+' | Where-Object { $_ -match '\S' }
                
                foreach ($mod in $mods) {
                    Write-Host "`n[*] Injecting '$mod' into profile..." -ForegroundColor Cyan
                    & $script:FeriumExe add $mod
                    
                    if ($LASTEXITCODE -eq 0) {
                        Write-Host "[SUCCESS] Added '$mod'." -ForegroundColor Green
                    } else {
                        Write-Host "[ERROR] Failed to add '$mod'. Verify the slug or ID." -ForegroundColor Red
                    }
                }
                Write-Host "`n[*] Batch operation complete. Run Option 1 or 3 to pull the binaries." -ForegroundColor Yellow
            } else {
                Write-Host "`n[WARNING] Empty input detected. Operation cancelled." -ForegroundColor Yellow
            }
        }
        "5" {
            $inputString = (Read-Host "`nEnter Modrinth slugs or CF IDs (separate by space or comma)").Trim()
            if (-not [string]::IsNullOrWhiteSpace($inputString)) {
                $mods = $inputString -split '[\s,]+' | Where-Object { $_ -match '\S' }
                
                $successCount = 0
                foreach ($mod in $mods) {
                    Write-Host "`n[*] Injecting '$mod' into profile..." -ForegroundColor Cyan
                    & $script:FeriumExe add $mod
                    
                    if ($LASTEXITCODE -eq 0) {
                        Write-Host "[SUCCESS] Added '$mod'." -ForegroundColor Green
                        $successCount++
                    } else {
                        Write-Host "[ERROR] Failed to add '$mod'." -ForegroundColor Red
                    }
                }
                
                if ($successCount -gt 0) {
                    Write-Host "`n[*] Upgrading repository..." -ForegroundColor Cyan
                    & $script:FeriumExe upgrade --output-dir "$script:MinecraftMods"
                    Write-Host "`n[SUCCESS] Profile synchronized to $script:MinecraftMods!" -ForegroundColor Green
                } else {
                    Write-Host "`n[ERROR] No mods were successfully added. Aborting upgrade sequence." -ForegroundColor Red
                }
            } else {
                Write-Host "`n[WARNING] Empty input detected. Operation cancelled." -ForegroundColor Yellow
            }
        }
        "6" {
            Write-Host "`n[*] Active Mod Profile:" -ForegroundColor Cyan
            & $script:FeriumExe list
        }
        "7" {
            Write-Host "`n[*] Active Mod Profile:" -ForegroundColor Cyan
            & $script:FeriumExe list
            
            $removeMod = (Read-Host "`nEnter the exact name or slug of the mod to REMOVE").Trim()
            if (-not [string]::IsNullOrWhiteSpace($removeMod)) {
                & $script:FeriumExe remove $removeMod
                
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "`n[SUCCESS] Untracked '$removeMod' from the Ferium profile." -ForegroundColor Green
                    Write-Host "Note: Ferium does not always delete the local binary. Verify your mods folder." -ForegroundColor Yellow
                } else {
                    Write-Host "`n[ERROR] Failed to remove mod. Ensure you typed the identifier exactly as listed." -ForegroundColor Red
                }
            } else {
                Write-Host "`n[WARNING] Empty input detected. Operation cancelled." -ForegroundColor Yellow
            }
        }
        "8" {
            $packSlug = (Read-Host "`nEnter Modrinth slug or CurseForge ID for the MODPACK").Trim()
            if (-not [string]::IsNullOrWhiteSpace($packSlug)) {
                Write-Host "`n[*] Processing Modpack: '$packSlug'..." -ForegroundColor Cyan
                
                & $script:FeriumExe modpack add $packSlug --output-dir $script:MinecraftRoot
                
                if ($LASTEXITCODE -ne 0) {
                    Write-Host "`n[*] Modpack may already be tracked. Enforcing directory configuration to '$script:MinecraftRoot'..." -ForegroundColor Yellow
                    & $script:FeriumExe modpack configure --output-dir $script:MinecraftRoot
                }

                Write-Host "`n[*] Pulling modpack components..." -ForegroundColor Cyan
                & $script:FeriumExe modpack upgrade
                
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "`n[SUCCESS] Modpack successfully configured and installed directly to root!" -ForegroundColor Green
                } else {
                    Write-Host "`n[ERROR] Modpack upgrade encountered a critical failure. Review the console trace." -ForegroundColor Red
                }
            } else {
                Write-Host "`n[WARNING] Empty input detected. Operation cancelled." -ForegroundColor Yellow
            }
        }
        "9" {
            Write-Host "`n[*] Scanning the mods directory for untracked .jar files..." -ForegroundColor Cyan
            & $script:FeriumExe scan
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "`n[SUCCESS] Untracked mods successfully identified and added to the Ferium profile!" -ForegroundColor Green
                Write-Host "Run Option 1 or 3 (Upgrade) to verify and sync them moving forward." -ForegroundColor Yellow
            } else {
                Write-Host "`n[ERROR] The scan encountered an issue. Review the console trace." -ForegroundColor Red
            }
        }
        "10" {
            Set-InstanceSettings
        }
        "11" {
            Write-Host "`nTerminating session..." -ForegroundColor Gray
            break
        }
        Default {
            Write-Host "`n[ERROR] Invalid selection. Awaiting input between 1 and 11." -ForegroundColor Red
        }
    }
    
    Write-Host ""
    Pause
}