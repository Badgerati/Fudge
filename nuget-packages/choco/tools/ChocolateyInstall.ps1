$ErrorActionPreference = 'Stop';

$packageName    = 'Fudge'
$toolsDir       = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$url            = 'https://github.com/Badgerati/Fudge/releases/download/v$version$/$version$-Binaries.zip'
$checksum       = '$checksum$'
$checksumType   = 'sha256'

$packageArgs = @{
  PackageName   = $packageName
  UnzipLocation = $toolsDir
  Url           = $url
  Checksum      = $checksum
  ChecksumType  = $checksumType
}

# Download
Install-ChocolateyZipPackage @packageArgs

# Install
$path = Join-Path $env:chocolateyPackageFolder 'tools/src'
Push-Location $path

try
{
    Write-Host 'Updating environment Path'
    Install-ChocolateyPath -PathToInstall $path -PathType 'Machine'
    Update-SessionEnvironment
}
finally
{
    Pop-Location
}
