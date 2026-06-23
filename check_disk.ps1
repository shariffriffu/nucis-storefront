# Check disk space using .NET API to avoid permissions/WMI issues
[System.IO.DriveInfo]::GetDrives() | ForEach-Object {
    if ($_.IsReady) {
        [PSCustomObject]@{
            Drive = $_.Name
            TotalGB = [Math]::Round($_.TotalSize / 1GB, 2)
            FreeGB = [Math]::Round($_.TotalFreeSpace / 1GB, 2)
        }
    }
} | Format-Table -AutoSize
