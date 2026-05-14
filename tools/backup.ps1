# Backup script using 7-Zip
# Backup directory is relative to the CURRENT WORKING DIRECTORY where the script is invoked

$ErrorActionPreference = 'Stop'

# Backup directory is relative to the CURRENT WORKING DIRECTORY where the script is invoked
$workDir = Get-Location
$backupDir = Join-Path $workDir '.backup'
if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir | Out-Null }

# Find 7z executable
$sevenZipExe = $null

# Priority 1: Local 7z-win-64 directory (provided tools)
$local7zDir = Join-Path $PSScriptRoot '7z-win-64'
if (Test-Path (Join-Path $local7zDir '7z.exe')) {
    $sevenZipExe = Join-Path $local7zDir '7z.exe'
    Write-Host "Using local 7z from: $local7zDir"
}

# Priority 2: System PATH
if (-not $sevenZipExe) {
    $sevenZipExe = (Get-Command 7z.exe -ErrorAction SilentlyContinue).Source
}

# Priority 3: Download to tools directory
if (-not $sevenZipExe) {
    Write-Host "7-Zip not found, downloading..."
    $toolsDir = $PSScriptRoot
    $sevenZipExe = Join-Path $toolsDir '7z.exe'
    
    if (-not (Test-Path $sevenZipExe)) {
        $msiPath = Join-Path $toolsDir '7z.msi'
        Invoke-WebRequest -Uri 'https://www.7-zip.org/a/7z2408-x64.msi' -OutFile $msiPath -UseBasicParsing
        
        # Extract MSI using msiexec
        $extractDir = Join-Path $toolsDir 'extracted'
        New-Item -ItemType Directory -Path $extractDir -Force | Out-Null
        Start-Process msiexec -ArgumentList "/a `"$msiPath`" /qn TARGETDIR=`"$extractDir`"" -Wait -NoNewWindow
        
        # Find and copy 7z.exe
        $found7z = Get-ChildItem $extractDir -Recurse -Filter '7z.exe' -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($found7z) {
            Copy-Item $found7z.FullName -Destination $sevenZipExe -Force
            $found7zDll = Get-ChildItem $extractDir -Recurse -Filter '7z.dll' -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($found7zDll) {
                Copy-Item $found7zDll.FullName -Destination (Join-Path $toolsDir '7z.dll') -Force
            }
        }
        
        # Clean up
        Remove-Item $msiPath -Force -ErrorAction SilentlyContinue
        Remove-Item $extractDir -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "7-Zip installed."
    }
}

# Verify 7z is available
if (-not $sevenZipExe -or -not (Test-Path $sevenZipExe)) {
    Write-Error "7-Zip is required but not found. Please install 7-Zip."
    exit 1
}

$dt = Get-Date -Format 'yyyy-MM-dd-HH-mm-ss'

# Shift backups: 10->11, 9->10, 8->9, ..., 1->2 (sorted by number descending)
Get-ChildItem -Path $backupDir -Filter '*.zip' | Sort-Object { [int]($_.BaseName -split '-')[0] } -Descending | ForEach-Object {
    if ($_.BaseName -match '^(\d+)-') {
        $num = [int]$matches[1]
        if ($num -lt 11) {
            $suffix = $_.BaseName.Substring($_.BaseName.IndexOf('-') + 1)
            $newName = '{0}-{1}' -f ($num + 1), $suffix
            Rename-Item -Path $_.FullName -NewName ($newName + $_.Extension) -Force
        }
    }
}

# Delete backup #11 (oldest)
Get-ChildItem -Path $backupDir -Filter '11-*.zip' | Remove-Item -Force -ErrorAction SilentlyContinue

# Create new backup #1
$backupFile = Join-Path $backupDir ('1-' + $dt + '.zip')
Write-Host "Creating backup: $backupFile"

# Use 7z - directly add all files and directories (includes empty dirs)
Write-Host "Using 7-Zip..."
Push-Location $workDir
& $sevenZipExe a -tzip $backupFile . "-xr!.backup" > $NULL 2>&1
Pop-Location

Write-Host ""
Write-Host "Backup completed!"
Get-ChildItem -Path $backupDir -Filter '*.zip' | Sort-Object Name | ForEach-Object { Write-Host $_.Name }