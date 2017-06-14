# Uninstall
function Remove-Fudge($path)
{
    $current = (Get-EnvironmentVariable -Name 'PATH' -Scope 'Machine')
    $current = $current.Replace($path, [string]::Empty)
    Set-EnvironmentVariable -Name 'PATH' -Value $current -Scope 'Machine'
    Update-SessionEnvironment
}

$path = Join-Path $env:chocolateyPackageFolder 'tools/src'
$pathSemi = "$($path);"

Write-Host 'Removing Fudge from environment Path'
if (($env:Path.Contains($pathSemi)))
{
    Remove-Fudge $pathSemi
}
elseif (($env:Path.Contains($path)))
{
    Remove-Fudge $path
}
