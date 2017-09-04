Write-Host 'Packing Fudge'

$build_version = $env:BUILD_VERSION
if ([string]::IsNullOrWhiteSpace($build_version))
{
    $build_version = '1.0.0'
}

$workspace = $env:WORKSPACE
if ([string]::IsNullOrWhiteSpace($workspace))
{
    $workspace = $pwd
}

# == VERSION =======================================================

Write-Host 'Setting version'
Push-Location './src'

try
{
    (Get-Content 'Fudge.ps1') | ForEach-Object { $_ -replace '\$version\$', $build_version } | Set-Content 'Fudge.ps1'
    Write-Host 'Version set'
}
finally
{
    Pop-Location
}

# == BUNDLE =======================================================

Write-Host "Copying scripts into package"

New-Item -ItemType Directory -Path './Package/src'
Copy-Item -Path './src/Modules' -Destination './Package/src/' -Force -Recurse
Copy-Item -Path './src/Fudge.ps1' -Destination './Package/src/' -Force

Write-Host "Scripts copied successfully"

# == ZIP =======================================================

Write-Host "Zipping package"
Push-Location "C:\Program Files\7-Zip\"
$zipName = "$build_version-Binaries.zip"

try
{
    .\7z.exe -tzip a "$workspace\$zipName" "$workspace\Package\*"
    Write-Host "Package zipped successfully"
}
finally
{
    Pop-Location
}

# == NUGET =======================================================

Write-Host "Building NuGet Package"
Push-Location "./nuget-packages/nuget"

try
{
    (Get-Content 'fudge.nuspec') | ForEach-Object { $_ -replace '\$version\$', $build_version } | Set-Content 'fudge.nuspec'
    nuget pack fudge.nuspec
}
finally
{
    Pop-Location
}

# == CHOCO =======================================================

Write-Host "Building Package Checksum"
Push-Location "$workspace"

try
{
    $checksum = (checksum -t sha256 -f $zipName)
    Write-Host "Checksum: $checksum"
}
finally
{
    Pop-Location
}

Write-Host "Building Choco Package"
Push-Location "./nuget-packages/choco"

try
{
    (Get-Content 'fudge.nuspec') | ForEach-Object { $_ -replace '\$version\$', $build_version } | Set-Content 'fudge.nuspec'
    Set-Location tools
    (Get-Content 'ChocolateyInstall.ps1') | ForEach-Object { $_ -replace '\$version\$', $build_version } | Set-Content 'ChocolateyInstall.ps1'
    (Get-Content 'Chocolateyinstall.ps1') | ForEach-Object { $_ -replace '\$checksum\$', $checksum } | Set-Content 'Chocolateyinstall.ps1'
    Set-Location ..
}
finally
{
    Pop-Location
}

# =========================================================

Write-Host 'Fudge Packed'