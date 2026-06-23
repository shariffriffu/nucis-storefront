# Script to check details of avd folder
$avdPath = "C:\Users\Shariff\.android\avd"
if (Test-Path $avdPath) {
    Get-ChildItem -Path $avdPath -ErrorAction SilentlyContinue | ForEach-Object {
        $size = 0
        if ($_.PSIsContainer) {
            $size = (Get-ChildItem $_.FullName -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
            [PSCustomObject]@{
                Name = $_.Name
                SizeGB = [Math]::Round($size / 1GB, 2)
                SizeMB = [Math]::Round($size / 1MB, 2)
            }
        }
    } | Sort-Object SizeMB -Descending | Format-Table -AutoSize
} else {
    Write-Host "AVD path not found!"
}
