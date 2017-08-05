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
        The action that Fudge should undertake
        Actions: install, upgrade, uninstall, reinstall, pack, list, search, new
        [Alias: -a]

    .PARAMETER Key
        The key represents a package/nuspec name in the Fudgefile
        [Alias: -k]
    
    .PARAMETER FudgefilePath
        This will override looking for a default 'Fudgefile' at the root of the current path, and allow you to specify
        other files instead. This allows you to have multiple Fudgefiles
        [Default: ./Fudgefile]
        [Alias: -fp]

    .PARAMETER Limit
        This argument only applies for the 'search' action. It will limit the amount of packages returned when searching
        If 0 is supplied, the full list is returned
        [Default: 10]
        [Alias: -l]

    .PARAMETER Dev
        Switch parameter, if supplied will also action upon the devPackages in the Fudgefile
        [Alias: -d]

    .PARAMETER DevOnly
        Switch parameter, if supplied will only action upon the devPackages in the Fudgefile
        [Alias: -do]
    
    .PARAMETER Version
        Switch parameter, if supplied will just display the current version of Fudge installed
        [Alias: -v]

    .EXAMPLE
        fudge install

    .EXAMPLE
        fudge upgrade -d    # to also upgrade devPackages

    .EXAMPLE
        fudge install -do   # to only install devPackages
    
    .EXAMPLE
        fudge pack website

    .EXAMPLE
        fudge list

    .EXAMPLE
        fudge search checksum
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

    [Alias('l')]
    [int]
    $Limit = 10,

    [Alias('d')]
    [switch]
    $Dev,

    [Alias('do')]
    [switch]
    $DevOnly,

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
Write-Details "Fudge $($ver)"

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
    $packageActions = @('install', 'upgrade', 'uninstall', 'reinstall', 'list')
    $packingActions = @('pack')
    $miscActions = @('search')
    $newActions = @('new')
    $actions = ($packageActions + $packingActions + $miscActions + $newActions)

    if ((Test-Empty $Action) -or $actions -inotcontains $Action)
    {
        Write-Fail "Unrecognised action supplied '$($Action)', should be either: $($actions -join ', ')"
        return
    }


    # if -devOnly is passed, set -dev to true
    if ($DevOnly)
    {
        $Dev = $true
    }


    # ensure that the Fudgefile exists (for certain actions), and deserialise it
    if ($packageActions -icontains $Action -or $packingActions -icontains $Action)
    {
        $FudgefilePath = Test-Fudgefile $FudgefilePath
        $config = Get-Fudgefile $FudgefilePath
    }

    # ensure that the Fudgefile doesn't exist
    elseif ($newActions -icontains $Action)
    {
        $FudgefilePath = Test-Fudgefile $FudgefilePath -DoesntExist
    }


    # if there are no packages to install or pack, just return
    if ($packingActions -icontains $Action)
    {
        if (Test-Empty $config.pack)
        {
            Write-Notice "There are no nuspecs to $($Action)"
            return
        }

        if (![string]::IsNullOrWhiteSpace($Key) -and [string]::IsNullOrWhiteSpace($config.pack.$Key))
        {
            Write-Notice "Fudgefile does not contain a nuspec pack file for '$($Key)'"
            return
        }
    }
    elseif ($packageActions -icontains $Action)
    {
        if ((Test-Empty $config.packages) -and (!$Dev -or ($Dev -and (Test-Empty $config.devPackages))))
        {
            Write-Notice "There are no packages to $($Action)"
            return
        }

        if ($DevOnly -and (Test-Empty $config.devPackages))
        {
            Write-Notice "There are no devPackages to $($Action)"
            return
        }
    }

    # check to see if chocolatey is installed
    $isChocoInstalled = Test-Chocolatey


    # check if the console is elevated (only needs to be done for certain actions)
    if ((!$isChocoInstalled -or (@('list', 'search', 'new') -inotcontains $Action)) -and !(Test-AdminUser))
    {
        Write-Notice 'Must be running with administrator priviledges for Fudge to fully function'
        return
    }


    # if chocolatey isn't installed, install it
    if (!$isChocoInstalled)
    {
        Install-Chocolatey
        $isChocoInstalled = $true
    }


    # invoke chocolatey based on the action required
    switch ($Action)
    {
        {($_ -ieq 'install') -or ($_ -ieq 'uninstall') -or ($_ -ieq 'upgrade')}
            {
                Invoke-ChocolateyAction -Action $Action -Key $Key -Config $config -Dev:$Dev -DevOnly:$DevOnly
            }
        
        {($_ -ieq 'reinstall')}
            {
                Invoke-ChocolateyAction -Action 'uninstall' -Key $Key -Config $config -Dev:$Dev -DevOnly:$DevOnly
                Invoke-ChocolateyAction -Action 'install' -Key $Key -Config $config -Dev:$Dev -DevOnly:$DevOnly
            }

        {($_ -ieq 'pack')}
            {
                Invoke-ChocolateyAction -Action 'pack' -Key $Key -Config $config
            }

        {($_ -ieq 'list')}
            {
                $localList = Get-ChocolateyLocalList
                Invoke-FudgeLocalDetails -Config $config -Key $Key -LocalList $localList -Dev:$Dev -DevOnly:$DevOnly
            }

        {($_ -ieq 'search')}
            {
                $localList = Get-ChocolateyLocalList
                Invoke-Search -Key $Key -Limit $Limit -LocalList $localList
            }

        {($_ -ieq 'new')}
            {
                New-Fudgefile -Key $Key -FudgefilePath $FudgefilePath
            }
    }
}
finally
{
    Write-Details "`nDuration: $(([DateTime]::UtcNow - $timer).ToString())"
}