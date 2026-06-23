# Script to inspect the size of subdirectories in C:\Users\Shariff\.gemini
$geminiPath = "C:\Users\Shariff\.gemini"
if (Test-Path $geminiPath) {
    Get-ChildItem -Path $geminiPath -ErrorAction SilentlyContinue | ForEach-Object {
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
    Write-Host ".gemini path not found!"
}
