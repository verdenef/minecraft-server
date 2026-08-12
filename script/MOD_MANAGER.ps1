<#
.SYNOPSIS
    Ferium Mod & Modpack Management Environment
.DESCRIPTION
    A resilient interactive CLI wrapper for managing Minecraft mods and modpacks using Ferium.
    Implements robust error handling, batch processing, state recovery, and folder scanning.
#>

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
                server = "C:\Users\Red\AppData\Roaming\.minecraft\instances\64290aca06184fb6b59be8d2ef380ff5\mods"
                main = "%APPDATA%\.minecraft\mods"
            }
        }
        $jsonStr = $defaultConfig | ConvertTo-Json -Depth 5
        Set-Content -Path $script:ConfigPath -Value $jsonStr -Force
    }
    
    try {
        $rawJson = Get-Content -Path $script:ConfigPath -Raw
        $script:ConfigObj = $rawJson | ConvertFrom-Json
        $script:ActiveProfile = $script:ConfigObj.active_profile
        
        $profileMods = $script:ConfigObj.profiles.PSObject.Properties[$script:ActiveProfile].Value
        if (-not [string]::IsNullOrWhiteSpace($profileMods)) {
            $script:MinecraftMods = [System.Environment]::ExpandEnvironmentVariables($profileMods)
        } else {
            $script:MinecraftMods = "$env:APPDATA\.minecraft\mods"
        }
    } catch {
        Write-Host "[WARNING] Failed to parse config.json. Using fallback .minecraft\mods" -ForegroundColor Yellow
        $script:ActiveProfile = "main"
        $script:MinecraftMods = "$env:APPDATA\.minecraft\mods"
    }
    
    Ensure-FeriumProfile
}

function Ensure-FeriumProfile {
    if (-not (Test-Path -Path $script:FeriumExe)) {
        return
    }
    
    if ([string]::IsNullOrWhiteSpace($script:ActiveProfile)) {
        $script:ActiveProfile = "main"
    }
    
    if (-not (Test-Path -Path $script:MinecraftMods)) {
        New-Item -ItemType Directory -Path $script:MinecraftMods -Force | Out-Null
    }
    
    $profilesOutput = & $script:FeriumExe profile list 2>&1 | Out-String
    $hasProfile = ($profilesOutput -match "(?m)^\s*$($script:ActiveProfile)\b") -or ($profilesOutput -match "(?m)^\s*$($script:ActiveProfile)\*")
    
    if (-not $hasProfile) {
        Write-Host "[*] Creating Ferium CLI profile '$script:ActiveProfile'..." -ForegroundColor Cyan
        & $script:FeriumExe profile create --name $script:ActiveProfile --output-dir "$script:MinecraftMods" --mod-loader fabric | Out-Null
    } else {
        & $script:FeriumExe profile switch $script:ActiveProfile | Out-Null
    }
    
    & $script:FeriumExe profile configure --output-dir "$script:MinecraftMods" | Out-Null
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
    $content = ""
    if (-not [string]::IsNullOrWhiteSpace($script:ManifestUrl)) {
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
            $candidates += Join-Path -Path $PSScriptRoot -ChildPath "server-mods.txt"
            $candidates += Join-Path -Path $PSScriptRoot -ChildPath "..\script\server-mods.txt"
        }
        $candidates += "script\server-mods.txt"
        $candidates += "server-mods.txt"
        
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
            Write-Host "[ERROR] No remote URL configured and local server-mods.txt not found!" -ForegroundColor Red
            return @()
        }
    }
    
    $mods = $content -split '[\r\n]+' | Where-Object { 
        $line = $_.Trim()
        $line -and -not $line.StartsWith("#")
    }
    return $mods
}

function Sync-ServerMods {
    Write-Host "`n[*] Starting Server Mod Synchronization..." -ForegroundColor Cyan
    Write-Host "[*] Target Mods Directory: $script:MinecraftMods" -ForegroundColor Gray
    
    if (-not (Test-Path -Path $script:MinecraftMods)) {
        New-Item -ItemType Directory -Path $script:MinecraftMods -Force | Out-Null
    }
    
    $mods = Get-ModManifest
    
    if ($mods.Count -eq 0) {
        Write-Host "[WARNING] No mods found in manifest to sync." -ForegroundColor Yellow
        return
    }
    
    Write-Host "[*] Registering $($mods.Count) mods into Ferium profile..." -ForegroundColor Cyan
    foreach ($mod in $mods) {
        Write-Host " -> Adding '$mod'..." -ForegroundColor Gray
        & $script:FeriumExe add $mod | Out-Null
    }
    
    Write-Host "`n[*] Pulling mod binaries to $script:MinecraftMods..." -ForegroundColor Cyan
    & $script:FeriumExe upgrade --output-dir "$script:MinecraftMods"
    
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
    Write-Host "     Ferium Mod Manager (Fabric 26.2)" -ForegroundColor Cyan
    Write-Host "   Target: [$script:ActiveProfile] -> $script:MinecraftMods" -ForegroundColor DarkCyan
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "  1. ⚡ 1-Click Server Mod Sync (Auto-Fetch & Upgrade)" -ForegroundColor Green
    Write-Host "  2. 🔄 Switch Target Instance Profile [$script:ActiveProfile]" -ForegroundColor Cyan
    Write-Host "  3. Upgrade / Sync Existing Mods" -ForegroundColor Yellow
    Write-Host "  4. Add New Mod(s) [Batch Supported]" -ForegroundColor Yellow
    Write-Host "  5. Add New Mod(s) AND Upgrade All" -ForegroundColor Yellow
    Write-Host "  6. List Currently Tracked Mods" -ForegroundColor Yellow
    Write-Host "  7. Remove a Tracked Mod" -ForegroundColor Red
    Write-Host "  8. Add / Configure & Upgrade a Modpack" -ForegroundColor Magenta
    Write-Host "  9. Scan Folder for Untracked Mods" -ForegroundColor Green
    Write-Host " 10. Exit" -ForegroundColor Gray
    Write-Host "==========================================" -ForegroundColor Cyan

    $choice = Read-Host "`nSelect an option (1-10)"

    switch ($choice) {
        "1" {
            Sync-ServerMods
        }
        "2" {
            Switch-ActiveProfile
        }
        "3" {
            Write-Host "`n[*] Checking for mod updates for profile [$script:ActiveProfile]..." -ForegroundColor Cyan
            & $script:FeriumExe upgrade --output-dir "$script:MinecraftMods"
            
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
            Write-Host "`nTerminating session..." -ForegroundColor Gray
            break
        }
        Default {
            Write-Host "`n[ERROR] Invalid selection. Awaiting input between 1 and 10." -ForegroundColor Red
        }
    }
    
    Write-Host ""
    Pause
}