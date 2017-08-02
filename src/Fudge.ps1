<#
    .SYNOPSIS
        Fudge is a tool to help you manage and version control Chocolatey packages required for environments to function
    
    .DESCRIPTION
        Fudge is a tool to help you manage and version control Chocolatey packages required for environments to function.
        This is done via a Fudgefile which allows you to specify packages (and their versions) to install. You can also
        specify dev-specific packages (like git, or fiddler)

        You are also able to define pre/post install/upgrade/uninstall scripts for additional required functionality

        Furthermore, Fudge has a section to allow you to specify multiple nuspec files and pack the one you need
    
    .PARAMETER Action
        The action that Fudge should take: install, upgrade, uninstall, reinstall, pack
        [Alias: -a]

    .PARAMETER Key
        The key represents a package/nuspec name in the Fudgefile
        [Alias: -k]
    
    .PARAMETER FudgefilePath
        This will override looking for a default 'Fudgefile' at the root of the current path, and allow you to specify
        other files instead. This allows you to have multiple Fudgefiles
        [Alias: -fp]

    .PARAMETER Dev
        Switch parameter, if supplied will also action upon the devPackages in the Fudgefile
        [Alias: -d]
    
    .PARAMETER Version
        Switch parameter, if supplied will just display the current version of Fudge installed
        [Alias: -v]

    .EXAMPLE
        fudge install

    .EXAMPLE
        fudge upgrade -d
    
    .EXAMPLE
        fudge pack website

    .EXAMPLE
        fudge list
#>
param (
    [Alias('a')]
    [string]
    $Action,

    [Alias('k')]
    [string]
    $Key,
    
    [Alias('fp')]
    [string]
    $FudgefilePath,

    [Alias('d')]
    [switch]
    $Dev,

    [Alias('v')]
    [switch]
    $Version
)

# ensure if there's an error, we stop
$ErrorActionPreference = 'Stop'


# Import required modules
$root = Split-Path -Parent -Path $MyInvocation.MyCommand.Path
Import-Module "$($root)\Modules\FudgeTools.psm1" -ErrorAction Stop


# output the version
$ver = 'v$version$'
Write-Details "Fudge $($ver)`n"

# if we were only after the version, just return
if ($Version)
{
    return
}


try
{
    # start timer
    $timer = [DateTime]::UtcNow


    # ensure we have a valid action
    $actions = @('install', 'upgrade', 'uninstall', 'reinstall', 'pack', 'list')
    if ((Test-Empty $Action) -or $actions -inotcontains $Action)
    {
        Write-Fail "Unrecognised action supplied '$($Action)', should be either: $($actions -join ', ')"
        return
    }


    # ensure that the Fudgefile exists
    $path = './Fudgefile'
    if (![string]::IsNullOrWhiteSpace($FudgefilePath))
    {
        if ((Get-Item $FudgefilePath) -is [System.IO.DirectoryInfo])
        {
            $path = Join-Path $FudgefilePath 'Fudgefile'
        }
        else
        {
            $path = $FudgefilePath
        }
    }

    if (!(Test-Path $path))
    {
        Write-Fail "Path to Fudgefile does not exist at: $($path)"
        return
    }


    # deserialise the Fudgefile
    $config = Get-Content -Path $path -Raw | ConvertFrom-Json
    if (!$?)
    {
        Write-Fail "Failed to parse the Fudgefile at: $($path)"
        return
    }


    # if there are no packages to install or pack, just return
    if ($Action -ieq 'pack')
    {
        if (Test-Empty $config.pack)
        {
            Write-Warning 'There are no nuspecs to pack'
            return
        }

        if (![string]::IsNullOrWhiteSpace($Key) -and [string]::IsNullOrWhiteSpace($config.pack.$Key))
        {
            Write-Warning "Fudgefile does not contain a nuspec pack file for '$($Key)'"
            return
        }
    }
    else
    {
        if ((Test-Empty $config.packages) -and (!$Dev -or ($Dev -and (Test-Empty $config.devPackages))))
        {
            Write-Warning "There are no packages to $($Action)"
            return
        }
    }

    # check to see if chocolatey is installed
    powershell.exe /C "choco -v" | Out-Null
    $isChocoInstalled = ($LASTEXITCODE -eq 0)


    # check if the console is elevated (only needs to be done for certain actions)
    if ((!$isChocoInstalled -or @('list') -inotcontains $Action) -and !(Test-AdminUser))
    {
        Write-Warning 'Must be running with administrator priviledges for Fudge to fully function'
        return
    }


    # check to see if chocolatey is installed - else install it
    if (!$isChocoInstalled)
    {
        Write-Notice "Installing Chocolatey"

        $policies = @('Unrestricted', 'ByPass', 'AllSigned')
        if ($policies -inotcontains (Get-ExecutionPolicy))
        {
            Set-ExecutionPolicy  Bypass -Force
        }

        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1')) | Out-Null
        $isChocoInstalled = $true

        Write-Success "Chocolatey installed`n"
    }


    # invoke chocolatey based on the action required
    switch ($Action)
    {
        {($_ -ieq 'install') -or ($_ -ieq 'uninstall') -or ($_ -ieq 'upgrade')}
            {
                Invoke-ChocolateyAction -Action $Action -Key $Key -Config $config -Dev:$Dev
            }
        
        {($_ -ieq 'reinstall')}
            {
                Invoke-ChocolateyAction -Action 'uninstall' -Key $Key -Config $config -Dev:$Dev
                Invoke-ChocolateyAction -Action 'install' -Key $Key -Config $config -Dev:$Dev
            }

        {($_ -ieq 'pack')}
            {
                Invoke-ChocolateyAction -Action 'pack' -Key $Key -Config $config -Dev:$Dev
            }

        {($_ -ieq 'list')}
            {
                $localList = Get-ChocolateyLocalList
                Invoke-FudgeLocalDetails -Config $config -Key $Key -LocalList $localList -Dev:$Dev
            }
    }
}
finally
{
    Write-Details "`nDuration: $(([DateTime]::UtcNow - $timer).ToString())"
}