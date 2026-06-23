# Script to find directories related to Windsurf and Trae
$paths = @(
    "C:\Users\Shariff",
    "C:\Users\Shariff\AppData\Local",
    "C:\Users\Shariff\AppData\Roaming"
)

$Results = @()

foreach ($path in $paths) {
    if (Test-Path $path) {
        $items = Get-ChildItem -Path $path -ErrorAction SilentlyContinue | Where-Object {
            $_.Name -like "*trae*" -or $_.Name -like "*windsurf*"
        }
        foreach ($item in $items) {
            $size = (Get-ChildItem $item.FullName -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
            $Results += [PSCustomObject]@{
                Path = $item.FullName
                SizeMB = [Math]::Round($size / 1MB, 2)
            }
        }
    }
}

$Results | Format-Table -AutoSize
