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
function Get-FeriumExePath {
    $candidates = @()
    if (-not [string]::IsNullOrWhiteSpace($PSScriptRoot)) {
        $candidates += Join-Path -Path $PSScriptRoot -ChildPath "..\ferium.exe"
        $candidates += Join-Path -Path $PSScriptRoot -ChildPath "ferium.exe"
    }
    $candidates += Join-Path -Path (Get-Location).Path -ChildPath "ferium.exe"
    $candidates += Join-Path -Path $env:LOCALAPPDATA -ChildPath "Ferium\ferium.exe"

    foreach ($c in $candidates) {
        if (Test-Path -Path $c) {
            return (Resolve-Path -Path $c).Path
        }
    }
    
    return Join-Path -Path $env:LOCALAPPDATA -ChildPath "Ferium\ferium.exe"
}

$script:FeriumDir = Join-Path -Path $env:LOCALAPPDATA -ChildPath "Ferium"
$script:FeriumExe = Get-FeriumExePath

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
            active_profile = "main"
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
            $script:ActiveMcVersion = "26.2"
            if (-not [string]::IsNullOrWhiteSpace($profileData.mc_version)) {
                $script:ActiveMcVersion = $profileData.mc_version
            }
            $script:ActiveModLoader = "fabric"
            if (-not [string]::IsNullOrWhiteSpace($profileData.mod_loader)) {
                $script:ActiveModLoader = $profileData.mod_loader
            }
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
    
    Initialize-FeriumProfile
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

function Initialize-FeriumProfile {
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
    
    # Auto-purge unauthenticated CurseForge entries that cause Ferium upgrade socket hangs
    $listOutput = & $script:FeriumExe list 2>&1 | Out-String
    $cfMatches = [regex]::Matches($listOutput, '(?m)^\s*CF\s+(\d+)\s+')
    if ($cfMatches.Count -gt 0) {
        Write-Host "[*] Cleaning $($cfMatches.Count) unauthenticated CurseForge entries to prevent API hangs..." -ForegroundColor Yellow
        foreach ($match in $cfMatches) {
            $cfId = $match.Groups[1].Value
            & $script:FeriumExe remove $cfId 2>&1 | Out-Null
        }
    }
}

# Set preference to Continue so PowerShell doesn't crash on standard CLI errors
$ErrorActionPreference = "Continue"

function Initialize-FeriumInstalled {
    $script:FeriumExe = Get-FeriumExePath
    if (Test-Path -Path $script:FeriumExe) {
        Write-Host "[*] Using Ferium executable: $script:FeriumExe" -ForegroundColor Gray
        return
    }
    
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
        $script:FeriumExe = Get-FeriumExePath
        Write-Host "[SUCCESS] Ferium auto-installation complete!" -ForegroundColor Green
    } catch {
        Write-Host "[ERROR] Failed to auto-download Ferium: $_" -ForegroundColor Red
        Write-Host "Please ensure an active internet connection or manually place ferium.exe in repository root or $script:FeriumDir" -ForegroundColor Red
        Pause
        exit 1
    }
}

# Ensure Ferium binary is downloaded and ready BEFORE configuring profiles
Initialize-FeriumInstalled
Get-ScriptConfig

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

function Protect-SodiumCompatibility {
    if (-not (Test-Path -Path $script:MinecraftMods)) {
        return
    }

    # Remove sodium from Ferium auto-upgrade to prevent downloading broken 0.9.2-alpha builds
    & $script:FeriumExe remove sodium 2>&1 | Out-Null
    & $script:FeriumExe remove AANobbMI 2>&1 | Out-Null

    # Post-sync Iris-Sodium compatibility guard:
    # Iris 1.11.2 requires stable Sodium 0.9.1+mc26.2 (0.9.2-alpha is incompatible with Iris 1.11.2)
    Get-ChildItem -Path $script:MinecraftMods -Filter "sodium-fabric-0.9.2-alpha*.jar" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
    $stableTarget = Join-Path -Path $script:MinecraftMods -ChildPath "sodium-fabric-0.9.1+mc26.2.jar"
    if (-not (Test-Path -Path $stableTarget)) {
        $cachedSodium = "D:\Games\minecraft-server\mods\sodium-fabric-0.9.1+mc26.2.jar"
        if (Test-Path -Path $cachedSodium) {
            Copy-Item -Path $cachedSodium -Destination $stableTarget -Force
            Write-Host "[*] Pinned stable Sodium 0.9.1+mc26.2 from local cache for Iris compatibility." -ForegroundColor Green
        } else {
            Write-Host "[*] Pinning Sodium to stable version 0.9.1+mc26.2 for Iris compatibility..." -ForegroundColor Yellow
            try {
                [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
                Invoke-WebRequest -Uri "https://cdn.modrinth.com/data/AANobbMI/versions/2Yom1N68/sodium-fabric-0.9.1%2Bmc26.2.jar" -OutFile $stableTarget
                Write-Host "[SUCCESS] Downloaded stable Sodium 0.9.1+mc26.2!" -ForegroundColor Green
            } catch {
                Write-Host "[WARNING] Could not download Sodium 0.9.1+mc26.2: $_" -ForegroundColor Yellow
            }
        }
    }
}

function Sync-ServerMods {
    Initialize-FeriumProfile
    
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
    
    # Fast local cache sync from server mods directory if available
    $serverModsDir = "D:\Games\minecraft-server\mods"
    if ((Test-Path -Path $serverModsDir) -and ($serverModsDir -ne $script:MinecraftMods)) {
        Write-Host "[*] Fast-syncing cached mod jars from $serverModsDir to $script:MinecraftMods..." -ForegroundColor Yellow
        $serverOnlyList = Get-ModManifest -FileName "server-only-mods.txt"
        $isServer = ($script:ActiveProfile -eq "server" -or $script:ActiveProfile -like "*server*" -or $script:MinecraftMods -like "*minecraft-server*")
        
        $jars = Get-ChildItem -Path $serverModsDir -Filter "*.jar" -File
        $copiedCount = 0
        foreach ($jar in $jars) {
            $isServerOnly = $false
            if (-not $isServer) {
                foreach ($soMod in $serverOnlyList) {
                    if ($jar.Name -like "*$soMod*") {
                        $isServerOnly = $true
                        break
                    }
                }
            }
            if (-not $isServerOnly) {
                $dest = Join-Path -Path $script:MinecraftMods -ChildPath $jar.Name
                if (-not (Test-Path -Path $dest)) {
                    Copy-Item -Path $jar.FullName -Destination $dest -Force
                    $copiedCount++
                }
            }
        }
        if ($copiedCount -gt 0) {
            Write-Host "[FAST-SYNC] Instantly mirrored $copiedCount mod jar files to $script:MinecraftMods!" -ForegroundColor Green
        }
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
    
    Protect-SodiumCompatibility
    
    # Filter $mods to only register mods that are not already tracked in the Ferium profile
    $untrackedModsToAdd = @()
    $normProfile = ($profileList -replace '[\s\-/_()]+', '').ToLower()
    foreach ($mod in $mods) {
        $normMod = ($mod -replace '[\s\-/_()]+', '').ToLower()
        if (-not ($profileList -match "(?i)\b$mod\b" -or ($normMod.Length -gt 3 -and $normProfile.Contains($normMod)))) {
            $untrackedModsToAdd += $mod
        }
    }
    
    if ($untrackedModsToAdd.Count -gt 0) {
        Write-Host "[*] Registering $($untrackedModsToAdd.Count) new mod(s) into Ferium profile..." -ForegroundColor Cyan
        & $script:FeriumExe add $untrackedModsToAdd 2>&1 | Out-Null
    } else {
        Write-Host "[*] All $($mods.Count) manifest mods are already registered in Ferium profile!" -ForegroundColor Green
    }
    
    # Check if all required mod binaries are already present in target directory
    $existingJars = Get-ChildItem -Path $script:MinecraftMods -Filter "*.jar" -File | Select-Object -ExpandProperty Name
    $missingMods = @()
    foreach ($m in $mods) {
        $found = $false
        $normM = ($m -replace '[\s\-/_()]+', '').ToLower()
        foreach ($j in $existingJars) {
            $normJ = ($j -replace '[\s\-/_()]+', '').ToLower()
            if ($normJ.Contains($normM) -or $j -like "*$m*") {
                $found = $true
                break
            }
        }
        if (-not $found) {
            $missingMods += $m
        }
    }

    if ($missingMods.Count -gt 0) {
        Write-Host "`n[*] Missing $($missingMods.Count) mod binary files. Pulling via Ferium network API..." -ForegroundColor Cyan
        & $script:FeriumExe upgrade
    } else {
        Write-Host "`n[FAST-SYNC] All $($mods.Count) mod binaries are verified present in $script:MinecraftMods!" -ForegroundColor Green
        Write-Host "[*] Skipping slow network API check. (Use Option 3 if you wish to check online updates)" -ForegroundColor Gray
    }
    
    Protect-SodiumCompatibility

    Write-Host "`n[SUCCESS] Server mods successfully synchronized to $script:MinecraftMods!" -ForegroundColor Green
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
    Write-Host " 11. [SERVER-CONFIG] Apply Server & World Configuration (CONFIGURE_SERVER.ps1)" -ForegroundColor DarkYellow
    Write-Host " 12. Exit" -ForegroundColor Gray
    Write-Host "==========================================" -ForegroundColor Cyan

    $choice = Read-Host "`nSelect an option (1-12)"

    switch ($choice) {
        "1" {
            Sync-ServerMods
        }
        "2" {
            Switch-ActiveProfile
        }
        "3" {
            Write-Host "`n[*] Checking for mod updates for profile [$script:ActiveProfile]..." -ForegroundColor Cyan
            Protect-SodiumCompatibility
            & $script:FeriumExe upgrade
            Protect-SodiumCompatibility
            
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
                
                foreach ($mod in $mods) {
                    Write-Host "`n[*] Injecting '$mod' into profile..." -ForegroundColor Cyan
                    & $script:FeriumExe add $mod
                }
                Write-Host "`n[*] Triggering upgrade cycle to pull binaries..." -ForegroundColor Cyan
                Protect-SodiumCompatibility
                & $script:FeriumExe upgrade
                Protect-SodiumCompatibility
                
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "`n[SUCCESS] Added and downloaded binaries for '$inputString'." -ForegroundColor Green
                } else {
                    Write-Host "`n[ERROR] Upgrade failed during batch add. Review the output." -ForegroundColor Red
                }
            } else {
                Write-Host "`n[WARNING] Empty input detected. Operation cancelled." -ForegroundColor Yellow
            }
        }
        "6" {
            Write-Host "`n[*] Fetching tracked mods for profile [$script:ActiveProfile]..." -ForegroundColor Cyan
            & $script:FeriumExe list
        }
        "7" {
            $modName = (Read-Host "`nEnter mod name or ID to remove").Trim()
            if (-not [string]::IsNullOrWhiteSpace($modName)) {
                Write-Host "`n[*] Removing '$modName' from profile..." -ForegroundColor Cyan
                & $script:FeriumExe remove $modName
                
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "`n[SUCCESS] Removed '$modName'." -ForegroundColor Green
                } else {
                    Write-Host "`n[ERROR] Failed to remove '$modName'. Ensure exact name/ID matches." -ForegroundColor Red
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
                Protect-SodiumCompatibility
                & $script:FeriumExe modpack upgrade
                Protect-SodiumCompatibility
                
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
            Write-Host "`n[*] Scanning '$script:MinecraftMods' for untracked .jar files..." -ForegroundColor Cyan
            
            # Attempt native Ferium scan first
            $feriumScan = & $script:FeriumExe scan 2>&1 | Out-String
            if ($LASTEXITCODE -eq 0 -and $feriumScan -notmatch "error decoding response body") {
                Write-Host $feriumScan
                Write-Host "`n[SUCCESS] Untracked mods identified by Ferium!" -ForegroundColor Green
            } else {
                Write-Host "[*] Falling back to PowerShell Resilient Mod Scanner..." -ForegroundColor Yellow
                Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue
                
                $aliasMap = @{
                    "voicechat" = "simple-voice-chat"
                    "roughlyenoughitems" = "rei"
                    "easyshulkerboxes" = "easy-shulker-boxes"
                    "inventoryprofilesnext" = "inventory-profiles-next"
                    "yet_another_config_lib_v3" = "yacl"
                    "lambdynlights" = "lambdynamiclights"
                    "bridgingmod" = "bridging-mod"
                    "do_a_barrel_roll" = "do-a-barrel-roll"
                    "graves" = "universal-graves"
                    "slotcycler" = "slot-cycler"
                    "puzzleslib" = "puzzles-lib"
                    "forgeconfigapiport" = "forge-config-api-port"
                    "elytratrims" = "elytra-trims"
                    "entity_model_features" = "entity-model-features"
                    "entity_texture_features" = "entitytexturefeatures"
                    "buildguide" = "build-guide"
                    "horsestatsmod" = "horse-stats-mod"
                    "horseexpert" = "horse-expert"
                    "seethroughlava" = "see-through-water-lava"
                    "autoreconnectrf" = "autoreconnect-fabric"
                    "elytra-chestplate-swapper" = "elytra-chestplate-swapper"
                    "infinitetrading" = "infinite-trading"
                    "justzoom" = "just-zoom"
                    "spear_boost" = "spear-boost"
                    "betteranimationscollection" = "better-animations-collection"
                    "invsearch_storage_indexer" = "invsearch"
                    "customskinloader-bootstrap" = "customskinloader"
                    "cyclepaintings" = "c85whkNB"
                    "autoclicker" = "auto-clicker"
                    "punchy" = "punchy"
                }
                
                $manifestMods = @()
                $manifestMods += Get-ModManifest -FileName "server-mods.txt"
                $manifestMods += Get-ModManifest -FileName "server-only-mods.txt"
                
                $profileList = & $script:FeriumExe list 2>&1 | Out-String
                $normProfileText = ($profileList -replace '[\s\-/_()]+', '').ToLower()
                
                if (-not (Test-Path -Path $script:MinecraftMods)) {
                    Write-Host "[ERROR] Target mods directory does not exist: $script:MinecraftMods" -ForegroundColor Red
                } else {
                    $jars = Get-ChildItem -Path $script:MinecraftMods -Filter "*.jar" -File
                    $untrackedJars = @()
                    
                    foreach ($jar in $jars) {
                        $modId = $null
                        $modName = $null
                        try {
                            $zip = [System.IO.Compression.ZipFile]::OpenRead($jar.FullName)
                            $entry = $zip.Entries | Where-Object { $_.FullName -eq "fabric.mod.json" }
                            if ($entry) {
                                $stream = $entry.Open()
                                $reader = New-Object System.IO.StreamReader($stream)
                                $jsonText = $reader.ReadToEnd()
                                $reader.Close()
                                $stream.Close()
                                $modJson = $jsonText | ConvertFrom-Json
                                $modId = $modJson.id
                                $modName = $modJson.name
                            }
                            $zip.Dispose()
                        } catch {}
                        
                        $slug = $null
                        if ($modId) {
                            if ($aliasMap.ContainsKey($modId)) {
                                $slug = $aliasMap[$modId]
                            } else {
                                $slug = $modId.Replace('_', '-')
                            }
                        }
                        
                        $isTracked = $false
                        $checkTerms = @($modId, $slug, $modName, $jar.BaseName) | Where-Object { $_ }
                        
                        # 1. Check against manifest lists (server-mods.txt / server-only-mods.txt)
                        foreach ($tm in $manifestMods) {
                            foreach ($term in $checkTerms) {
                                if ($term -eq $tm -or $jar.Name -like "*$tm*") {
                                    $isTracked = $true
                                    break
                                }
                            }
                            if ($isTracked) { break }
                        }
                        
                        # 2. Check against Ferium active profile list (with fuzzy normalized string matching)
                        if (-not $isTracked) {
                            foreach ($term in $checkTerms) {
                                $escaped = [regex]::Escape($term)
                                $normTerm = ($term -replace '[\s\-/_()]+', '').ToLower()
                                if (($profileList -match "(?i)$escaped") -or ($normTerm.Length -gt 3 -and $normProfileText.Contains($normTerm))) {
                                    $isTracked = $true
                                    break
                                }
                            }
                        }
                        
                        if (-not $isTracked) {
                            $displayId = "Unknown"
                            if (-not [string]::IsNullOrWhiteSpace($modId)) { $displayId = $modId }
                            $displayName = $jar.BaseName
                            if (-not [string]::IsNullOrWhiteSpace($modName)) { $displayName = $modName }
                            
                            $untrackedJars += [pscustomobject]@{
                                File = $jar.Name
                                ID   = $displayId
                                Name = $displayName
                            }
                        }
                    }
                    
                    if ($untrackedJars.Count -eq 0) {
                        Write-Host "`n[SUCCESS] All $($jars.Count) mod jar files in directory are tracked!" -ForegroundColor Green
                    } else {
                        Write-Host "`n[NOTICE] Found $($untrackedJars.Count) untracked mod jar file(s):" -ForegroundColor Yellow
                        $untrackedJars | Format-Table -AutoSize
                        
                        $autoAdd = (Read-Host "`nWould you like to register untracked mod IDs to profile '$script:ActiveProfile'? (y/n)").Trim().ToLower()
                        if ($autoAdd -eq 'y' -or $autoAdd -eq 'yes') {
                            $toAddModrinth = @()
                            $toAddCurseForge = @()
                            
                            foreach ($uJar in ($untrackedJars | Where-Object { $_.ID -ne "Unknown" })) {
                                $rawId = $uJar.ID
                                $slug = $null
                                if ($aliasMap.ContainsKey($rawId)) {
                                    $slug = $aliasMap[$rawId]
                                } else {
                                    $slug = $rawId.Replace('_', '-')
                                }
                                
                                if ($slug -like "curseforge:*") {
                                    $cfId = ($slug -split ':')[1]
                                    $toAddCurseForge += $cfId
                                } elseif ($slug -like "cf:*") {
                                    $cfId = ($slug -split ':')[1]
                                    $toAddCurseForge += $cfId
                                } else {
                                    $toAddModrinth += $slug
                                }
                            }
                            
                            if ($toAddModrinth.Count -gt 0) {
                                Write-Host "[*] Registering $($toAddModrinth.Count) Modrinth project slugs to profile '$script:ActiveProfile'..." -ForegroundColor Cyan
                                & $script:FeriumExe add modrinth $toAddModrinth 2>&1 | Out-Null
                            }
                            
                            if ($toAddCurseForge.Count -gt 0) {
                                Write-Host "[*] Registering $($toAddCurseForge.Count) CurseForge project IDs to profile '$script:ActiveProfile'..." -ForegroundColor Cyan
                                & $script:FeriumExe add curseforge $toAddCurseForge 2>&1 | Out-Null
                            }
                            
                            Write-Host "[SUCCESS] Added untracked mod(s) to profile '$script:ActiveProfile'!" -ForegroundColor Green
                        }
                    }
                }
            }
        }
        "10" {
            Set-InstanceSettings
        }
        "11" {
            $confScript = Join-Path -Path $script:PSScriptRoot -ChildPath "CONFIGURE_SERVER.ps1"
            if (-not (Test-Path -Path $confScript)) {
                $confScript = Join-Path -Path $script:PSScriptRoot -ChildPath "..\script\CONFIGURE_SERVER.ps1"
            }
            if (Test-Path -Path $confScript) {
                Write-Host "`n[*] Triggering Server & World Configuration..." -ForegroundColor Cyan
                & $confScript
            } else {
                Write-Host "`n[ERROR] CONFIGURE_SERVER.ps1 script not found at $confScript" -ForegroundColor Red
            }
        }
        "12" {
            Write-Host "`nTerminating session..." -ForegroundColor Gray
            break
        }
        Default {
            Write-Host "`n[ERROR] Invalid selection. Awaiting input between 1 and 12." -ForegroundColor Red
        }
    }
    
    Write-Host ""
    Pause
}