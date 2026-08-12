<#
.SYNOPSIS
    Ferium Mod & Modpack Management Environment
.DESCRIPTION
    A resilient interactive CLI wrapper for managing Minecraft mods and modpacks using Ferium.
    Implements robust error handling, batch processing, state recovery, and folder scanning.
#>

# 1. Environment Setup & Validation
$FeriumDir = "D:\Downloads\appl"
$FeriumExe = Join-Path -Path $FeriumDir -ChildPath "ferium.exe"
$MinecraftRoot = "$env:APPDATA\.minecraft"

# Set preference to Continue so PowerShell doesn't crash on standard CLI errors
$ErrorActionPreference = "Continue" 

if (-not (Test-Path -Path $FeriumExe)) {
    Write-Host "`n[FATAL ERROR] Executable not found at expected path: $FeriumExe" -ForegroundColor Red
    Write-Host "Verify the directory structure before executing this script." -ForegroundColor Red
    Pause
    exit 1
}

Set-Location -Path $FeriumDir

# 2. Main Execution Loop
while ($true) {
    Clear-Host
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "     Ferium Mod Manager (Fabric 26.2)" -ForegroundColor Cyan
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "  1. Upgrade / Sync Existing Mods" -ForegroundColor Yellow
    Write-Host "  2. Add New Mod(s) [Batch Supported]" -ForegroundColor Yellow
    Write-Host "  3. Add New Mod(s) AND Upgrade All" -ForegroundColor Yellow
    Write-Host "  4. List Currently Tracked Mods" -ForegroundColor Yellow
    Write-Host "  5. Remove a Tracked Mod" -ForegroundColor Red
    Write-Host "  6. Add / Configure & Upgrade a Modpack" -ForegroundColor Magenta
    Write-Host "  7. Scan Folder for Untracked Mods" -ForegroundColor Green
    Write-Host "  8. Exit" -ForegroundColor Gray
    Write-Host "==========================================" -ForegroundColor Cyan

    $choice = Read-Host "`nSelect an option (1-8)"

    switch ($choice) {
        "1" {
            Write-Host "`n[*] Checking for mod updates..." -ForegroundColor Cyan
            & $FeriumExe upgrade
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "`n[SUCCESS] Mods synchronized successfully!" -ForegroundColor Green
            } else {
                Write-Host "`n[ERROR] Upgrade failed with Exit Code: $LASTEXITCODE. Review the Ferium output above." -ForegroundColor Red
            }
        }
        "2" {
            $inputString = (Read-Host "`nEnter Modrinth slugs or CF IDs (separate by space or comma)").Trim()
            if (-not [string]::IsNullOrWhiteSpace($inputString)) {
                # Split by space or comma and filter out empty strings
                $mods = $inputString -split '[\s,]+' | Where-Object { $_ -match '\S' }
                
                foreach ($mod in $mods) {
                    Write-Host "`n[*] Injecting '$mod' into profile..." -ForegroundColor Cyan
                    & $FeriumExe add $mod
                    
                    if ($LASTEXITCODE -eq 0) {
                        Write-Host "[SUCCESS] Added '$mod'." -ForegroundColor Green
                    } else {
                        Write-Host "[ERROR] Failed to add '$mod'. Verify the slug or ID." -ForegroundColor Red
                    }
                }
                Write-Host "`n[*] Batch operation complete. Run Option 1 to pull the binaries." -ForegroundColor Yellow
            } else {
                Write-Host "`n[WARNING] Empty input detected. Operation cancelled." -ForegroundColor Yellow
            }
        }
        "3" {
            $inputString = (Read-Host "`nEnter Modrinth slugs or CF IDs (separate by space or comma)").Trim()
            if (-not [string]::IsNullOrWhiteSpace($inputString)) {
                $mods = $inputString -split '[\s,]+' | Where-Object { $_ -match '\S' }
                
                $successCount = 0
                foreach ($mod in $mods) {
                    Write-Host "`n[*] Injecting '$mod' into profile..." -ForegroundColor Cyan
                    & $FeriumExe add $mod
                    
                    if ($LASTEXITCODE -eq 0) {
                        Write-Host "[SUCCESS] Added '$mod'." -ForegroundColor Green
                        $successCount++
                    } else {
                        Write-Host "[ERROR] Failed to add '$mod'." -ForegroundColor Red
                    }
                }
                
                if ($successCount -gt 0) {
                    Write-Host "`n[*] Upgrading repository..." -ForegroundColor Cyan
                    & $FeriumExe upgrade
                    Write-Host "`n[SUCCESS] Profile synchronized!" -ForegroundColor Green
                } else {
                    Write-Host "`n[ERROR] No mods were successfully added. Aborting upgrade sequence." -ForegroundColor Red
                }
            } else {
                Write-Host "`n[WARNING] Empty input detected. Operation cancelled." -ForegroundColor Yellow
            }
        }
        "4" {
            Write-Host "`n[*] Active Mod Profile:" -ForegroundColor Cyan
            & $FeriumExe list
        }
        "5" {
            Write-Host "`n[*] Active Mod Profile:" -ForegroundColor Cyan
            & $FeriumExe list
            
            $removeMod = (Read-Host "`nEnter the exact name or slug of the mod to REMOVE").Trim()
            if (-not [string]::IsNullOrWhiteSpace($removeMod)) {
                & $FeriumExe remove $removeMod
                
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
        "6" {
            $packSlug = (Read-Host "`nEnter Modrinth slug or CurseForge ID for the MODPACK").Trim()
            if (-not [string]::IsNullOrWhiteSpace($packSlug)) {
                Write-Host "`n[*] Processing Modpack: '$packSlug'..." -ForegroundColor Cyan
                
                & $FeriumExe modpack add $packSlug --output-dir $MinecraftRoot
                
                if ($LASTEXITCODE -ne 0) {
                    Write-Host "`n[*] Modpack may already be tracked. Enforcing directory configuration to '$MinecraftRoot'..." -ForegroundColor Yellow
                    & $FeriumExe modpack configure --output-dir $MinecraftRoot
                }

                Write-Host "`n[*] Pulling modpack components..." -ForegroundColor Cyan
                & $FeriumExe modpack upgrade
                
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "`n[SUCCESS] Modpack successfully configured and installed directly to root!" -ForegroundColor Green
                } else {
                    Write-Host "`n[ERROR] Modpack upgrade encountered a critical failure. Review the console trace." -ForegroundColor Red
                }
            } else {
                Write-Host "`n[WARNING] Empty input detected. Operation cancelled." -ForegroundColor Yellow
            }
        }
        "7" {
            Write-Host "`n[*] Scanning the mods directory for untracked .jar files..." -ForegroundColor Cyan
            & $FeriumExe scan
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "`n[SUCCESS] Untracked mods successfully identified and added to the Ferium profile!" -ForegroundColor Green
                Write-Host "Run Option 1 (Upgrade) to verify and sync them moving forward." -ForegroundColor Yellow
            } else {
                Write-Host "`n[ERROR] The scan encountered an issue. Review the console trace." -ForegroundColor Red
            }
        }
        "8" {
            Write-Host "`nTerminating session..." -ForegroundColor Gray
            break
        }
        Default {
            Write-Host "`n[ERROR] Invalid selection. Awaiting input between 1 and 8." -ForegroundColor Red
        }
    }
    
    Write-Host ""
    Pause
}