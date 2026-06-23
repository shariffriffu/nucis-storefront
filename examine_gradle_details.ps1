# Script to inspect details of caches, wrapper, and daemon inside .gradle
$gradlePath = "C:\Users\Shariff\.gradle"

Write-Host "--- Inspecting .gradle\wrapper\dists ---"
$distsPath = Join-Path $gradlePath "wrapper\dists"
if (Test-Path $distsPath) {
    Get-ChildItem -Path $distsPath -Directory | ForEach-Object {
        $size = (Get-ChildItem $_.FullName -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
        [PSCustomObject]@{
            WrapperVersion = $_.Name
            SizeMB = [Math]::Round($size / 1MB, 2)
        }
    } | Sort-Object SizeMB -Descending | Format-Table -AutoSize
}

Write-Host "--- Inspecting .gradle\daemon ---"
$daemonPath = Join-Path $gradlePath "daemon"
if (Test-Path $daemonPath) {
    Get-ChildItem -Path $daemonPath -Directory | ForEach-Object {
        $size = (Get-ChildItem $_.FullName -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
        [PSCustomObject]@{
            DaemonVersion = $_.Name
            SizeMB = [Math]::Round($size / 1MB, 2)
        }
    } | Sort-Object SizeMB -Descending | Format-Table -AutoSize
}

Write-Host "--- Inspecting .gradle\caches ---"
$cachesPath = Join-Path $gradlePath "caches"
if (Test-Path $cachesPath) {
    Get-ChildItem -Path $cachesPath -Directory | ForEach-Object {
        $size = (Get-ChildItem $_.FullName -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
        [PSCustomObject]@{
            CacheFolder = $_.Name
            SizeMB = [Math]::Round($size / 1MB, 2)
        }
    } | Sort-Object SizeMB -Descending | Format-Table -AutoSize
}
