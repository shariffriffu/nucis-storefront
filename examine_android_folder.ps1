# Script to check what is inside C:\Users\Shariff\.android
$androidPath = "C:\Users\Shariff\.android"
if (Test-Path $androidPath) {
    # Get all items in .android folder
    Get-ChildItem -Path $androidPath -ErrorAction SilentlyContinue | ForEach-Object {
        $size = 0
        if ($_.PSIsContainer) {
            $size = (Get-ChildItem $_.FullName -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
        } else {
            $size = $_.Length
        }
        [PSCustomObject]@{
            Name = $_.Name
            Type = if ($_.PSIsContainer) { "Folder" } else { "File" }
            SizeMB = [Math]::Round($size / 1MB, 2)
        }
    } | Sort-Object SizeMB -Descending | Format-Table -AutoSize
} else {
    Write-Host ".android path not found!"
}
