# PowerShell script to check large folders in C:\Users\Shariff and AppData

$TargetPaths = @(
    "C:\Users\Shariff",
    "C:\Users\Shariff\AppData\Local",
    "C:\Users\Shariff\AppData\Roaming"
)

Write-Host "Scanning directories for size. This may take a minute..." -ForegroundColor Cyan

$Results = [System.Collections.Generic.List[PSCustomObject]]::new()

foreach ($path in $TargetPaths) {
    if (Test-Path $path) {
        $subdirs = Get-ChildItem -Path $path -Directory -ErrorAction SilentlyContinue
        foreach ($dir in $subdirs) {
            $sum = 0
            # Get size of files in directory recursively
            Get-ChildItem -Path $dir.FullName -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
                $sum += $_.Length
            }
            if ($sum -gt 100MB) { # Show anything larger than 100MB
                $sizeGB = [Math]::Round($sum / 1GB, 2)
                $sizeMB = [Math]::Round($sum / 1MB, 2)
                $Results.Add([PSCustomObject]@{
                    Path = $dir.FullName
                    SizeGB = $sizeGB
                    SizeMB = $sizeMB
                })
            }
        }
    }
}

$Results | Sort-Object SizeMB -Descending | Format-Table -AutoSize
