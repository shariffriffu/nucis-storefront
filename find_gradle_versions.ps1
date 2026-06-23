# Script to find Gradle wrapper versions used in projects under d:\app
$projects = @("d:\app\shariffs_hub", "d:\app\btapp-fltr3.23.3")

foreach ($proj in $projects) {
    if (Test-Path $proj) {
        Write-Host "Searching in $proj..." -ForegroundColor Cyan
        $files = Get-ChildItem -Path $proj -Filter "gradle-wrapper.properties" -Recurse -ErrorAction SilentlyContinue
        foreach ($file in $files) {
            $content = Get-Content $file.FullName
            foreach ($line in $content) {
                if ($line -like "*distributionUrl*") {
                    Write-Host "$($file.FullName): $line"
                }
            }
        }
    }
}
