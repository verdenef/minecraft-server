# ==============================================================================
# MINECRAFT SERVER WORLD RESET SCRIPT
# Resets the world while preserving all configs, mods, and server.properties
# ==============================================================================

Write-Host "`n[*] Starting Minecraft Server World Reset..." -ForegroundColor Cyan

$serverDir = "D:\Games\minecraft-server"

if (-not (Test-Path -Path $serverDir)) {
    Write-Host "[ERROR] Server directory not found at $serverDir" -ForegroundColor Red
    return
}

# 1. Delete World Folders
$worldFolders = @(
    (Join-Path -Path $serverDir -ChildPath "hustisya para kay rene"),
    (Join-Path -Path $serverDir -ChildPath "world")
)

foreach ($folder in $worldFolders) {
    if (Test-Path -Path $folder) {
        Write-Host "[*] Removing world folder: $folder..." -ForegroundColor Yellow
        Remove-Item -Path $folder -Recurse -Force
        Write-Host " -> Removed $folder" -ForegroundColor Green
    }
}

# 2. Delete usercache.json
$userCache = Join-Path -Path $serverDir -ChildPath "usercache.json"
if (Test-Path -Path $userCache) {
    Remove-Item -Path $userCache -Force
    Write-Host " -> Removed usercache.json" -ForegroundColor Green
}

Write-Host "`n[SUCCESS] World reset complete! Next server launch will generate a fresh world." -ForegroundColor Green
Write-Host "[NOTE] All mod configurations in config\ and mods\ were safely preserved." -ForegroundColor Cyan
Write-Host ""
Pause
