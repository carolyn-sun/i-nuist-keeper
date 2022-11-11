Write-Output "Detected V: "
Get-Command v
Write-Output "Version: "
v version
v -o i-nuist-keeper.exe -os windows .
Write-Output "Compilation done"
Pause
