# Script to inspect the size of subdirectories in C:\Users\Shariff\.gradle
$gradlePath = "C:\Users\Shariff\.gradle"
if (Test-Path $gradlePath) {
    Get-ChildItem -Path $gradlePath -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        $size = (Get-ChildItem $_.FullName -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
        [PSCustomObject]@{
            DirectoryName = $_.Name
            SizeGB = [Math]::Round($size / 1GB, 2)
            SizeMB = [Math]::Round($size / 1MB, 2)
        }
    } | Sort-Object SizeMB -Descending | Format-Table -AutoSize
} else {
    Write-Host "Gradle path not found!"
}
