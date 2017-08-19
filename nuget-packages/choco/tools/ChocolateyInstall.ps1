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
Write-Host 'Updating environment Path'
$path = Join-Path $env:chocolateyPackageFolder 'tools/src'
Install-ChocolateyPath -PathToInstall $path -PathType 'Machine'
Update-SessionEnvironment
