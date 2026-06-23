# PowerShell script to perform the approved C drive cleanup

# 1. Update task.md progress
function Update-Progress {
    Write-Host "Updating task progress..." -ForegroundColor Cyan
}

$HomeDir = "C:\Users\Shariff"
$TempDir = "C:\Users\Shariff\AppData\Local\Temp"

# --- TASK 1: Remove Windsurf and Trae directories ---
Write-Host "--- Task 1: Removing Windsurf and Trae directories ---" -ForegroundColor Yellow
$EditorDirs = @(
    "$HomeDir\.trae",
    "$HomeDir\.trae-aicc",
    "$HomeDir\.windsurf",
    "$HomeDir\AppData\Roaming\Trae",
    "$HomeDir\AppData\Roaming\Windsurf"
)

foreach ($dir in $EditorDirs) {
    if (Test-Path $dir) {
        Write-Host "Deleting: $dir"
        Remove-Item -Path $dir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# --- TASK 2: Clean Gradle wrappers ---
Write-Host "--- Task 2: Cleaning old Gradle wrappers ---" -ForegroundColor Yellow
$WrapperDists = "$HomeDir\.gradle\wrapper\dists"
if (Test-Path $WrapperDists) {
    Get-ChildItem -Path $WrapperDists -Directory | ForEach-Object {
        $name = $_.Name
        if ($name -ne "gradle-9.1.0-all" -and $name -ne "gradle-8.11.1-all") {
            Write-Host "Deleting old wrapper: $name"
            Remove-Item -Path $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
        } else {
            Write-Host "Keeping wrapper: $name" -ForegroundColor Green
        }
    }
}

# --- TASK 3: Clean Gradle caches ---
Write-Host "--- Task 3: Cleaning old Gradle caches ---" -ForegroundColor Yellow
$CachesDir = "$HomeDir\.gradle\caches"
if (Test-Path $CachesDir) {
    Get-ChildItem -Path $CachesDir -Directory | ForEach-Object {
        $name = $_.Name
        # If the folder starts with a number (like 8.10, 7.5) and is not the active ones
        if ($name -match '^\d' -and $name -ne "8.11.1" -and $name -ne "9.1.0") {
            Write-Host "Deleting old cache version: $name"
            Remove-Item -Path $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
        } else {
            Write-Host "Keeping cache/folder: $name" -ForegroundColor Green
        }
    }
}

# --- TASK 4: Clean Gradle daemons ---
Write-Host "--- Task 4: Cleaning Gradle daemons ---" -ForegroundColor Yellow
$DaemonDir = "$HomeDir\.gradle\daemon"
if (Test-Path $DaemonDir) {
    Get-ChildItem -Path $DaemonDir -Directory | ForEach-Object {
        $name = $_.Name
        if ($name -ne "8.11.1" -and $name -ne "9.1.0") {
            Write-Host "Deleting daemon files for version: $name"
            Remove-Item -Path $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
        } else {
            # For active versions, clean log files but keep the directory (which might contain locked files)
            Write-Host "Cleaning log files in active daemon version: $name"
            Get-ChildItem -Path $_.FullName -File -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
                if ($_.Name -like "*.log" -or $_.Name -like "*.out") {
                    Remove-Item -Path $_.FullName -Force -ErrorAction SilentlyContinue
                }
            }
        }
    }
}

# --- TASK 5: Clean temporary files ---
Write-Host "--- Task 5: Cleaning Windows temp files ---" -ForegroundColor Yellow
if (Test-Path $TempDir) {
    Get-ChildItem -Path $TempDir -ErrorAction SilentlyContinue | ForEach-Object {
        try {
            Remove-Item -Path $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
        } catch {
            # Skip locked files
        }
    }
}

Write-Host "Cleanup completed!" -ForegroundColor Green
