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
        Actions: install, upgrade, uninstall, reinstall, pack, list, search, new, delete, prune, clean
        [Alias: -a]

    .PARAMETER Key
        The key represents a package/nuspec name in the Fudgefile
        [Alias: -k]
    
    .PARAMETER FudgefilePath
        This will override looking for a default 'Fudgefile' at the root of the current path, and allow you to specify
        other files instead. This allows you to have multiple Fudgefiles
        [Actions: install, upgrade, uninstall, reinstall, pack, list, new, delete, prune]
        [Default: ./Fudgefile]
        [Alias: -fp]

    .PARAMETER Limit
        This argument only applies for the 'search' action. It will limit the amount of packages returned when searching
        If 0 is supplied, the full list is returned
        [Actions: search]
        [Default: 10]
        [Alias: -l]

    .PARAMETER Source
        Passing this argument will allow you to specify custom source locations to get/download packages for Chocolatey.
        This allows you to install packages from local directories, or from custom Chocolatey servers. Passing this will
        also override the source specified in any Fudgefiles
        [Default: Chocolatey's server]
        [Actions: install, upgrade, reinstall, search]
        [Alias: -s]

    .PARAMETER Dev
        Switch parameter, if supplied will also action upon the devPackages in the Fudgefile
        [Actions: install, upgrade, uninstall, reinstall, list, delete, prune]
        [Alias: -d]

    .PARAMETER DevOnly
        Switch parameter, if supplied will only action upon the devPackages in the Fudgefile
        [Actions: install, upgrade, uninstall, reinstall, list, delete, prune]
        [Alias: -do]
    
    .PARAMETER Version
        Switch parameter, if supplied will just display the current version of Fudge installed
        [Alias: -v]

    .PARAMETER Install
        Switch parameter, if supplied will install packages after creating a new Fudgefile
        [Actions: new]
        [Alias: -i]
    
    .PARAMETER Uninstall
        Switch parameter, if supplied will uninstall packages before deleting a Fudgefile
        [Actions: delete]
        [Alias: -u]

    .EXAMPLE
        fudge install

    .EXAMPLE
        fudge install -d    # to also install devPackages (-do will only install devPackages)
    
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

    [Alias('s')]
    [string]
    $Source,

    [Alias('d')]
    [switch]
    $Dev,

    [Alias('do')]
    [switch]
    $DevOnly,

    [Alias('i')]
    [switch]
    $Install,

    [Alias('u')]
    [switch]
    $Uninstall,

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
Write-Success "Fudge $($ver)"

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
    $maintainActions = @('prune')
    $packingActions = @('pack')
    $miscActions = @('search', 'clean')
    $newActions = @('new')
    $alterActions = @('delete')
    $actions = ($packageActions + $maintainActions + $packingActions + $miscActions + $newActions + $alterActions)

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


    # get the Fudgefile path
    $FudgefilePath = Get-FudgefilePath $FudgefilePath


    # ensure that the Fudgefile exists (for certain actions), and deserialise it
    if (($packageActions + $maintainActions + $packingActions + $alterActions) -icontains $Action)
    {
        if (!(Test-Path $FudgefilePath))
        {
            throw "Path to Fudgefile does not exist: $($FudgefilePath)"
        }

        $config = Get-FudgefileContent $FudgefilePath

        # if we have a custom source in the config and no CLI source, set the source
        if ((Test-Empty $Source) -and $config -ne $null -and !(Test-Empty $config.source))
        {
            $Source = $config.source
        }
    }

    # ensure that the Fudgefile doesn't exist
    elseif ($newActions -icontains $Action)
    {
        if (Test-Path $FudgefilePath)
        {
            throw "Path to Fudgefile already exists: $($FudgefilePath)"
        }
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
    $isAdminAction = @('list', 'search', 'new', 'delete') -inotcontains $Action
    $actionNeedsAdmin = ($Action -ieq 'delete' -and $Uninstall) -or ($Action -ieq 'new' -and $Install)

    if ((!$isChocoInstalled -or $isAdminAction -or $actionNeedsAdmin) -and !(Test-AdminUser))
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


    # if we are using a custom source, output it for info
    if (!(Test-Empty $Source))
    {
        Write-Notice "Source: $($Source)`n"
    }
    else
    {
        Write-Host ([string]::Empty)
    }


    # invoke chocolatey based on the action required
    switch ($Action)
    {
        {($_ -ieq 'install') -or ($_ -ieq 'uninstall') -or ($_ -ieq 'upgrade')}
            {
                Invoke-ChocolateyAction -Action $Action -Key $Key -Source $Source -Config $config -Dev:$Dev -DevOnly:$DevOnly
            }
        
        {($_ -ieq 'reinstall')}
            {
                Invoke-ChocolateyAction -Action 'uninstall' -Key $Key -Source $Source -Config $config -Dev:$Dev -DevOnly:$DevOnly
                Invoke-ChocolateyAction -Action 'install' -Key $Key -Source $Source -Config $config -Dev:$Dev -DevOnly:$DevOnly
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
                Invoke-Search -Key $Key -Limit $Limit -Source $Source -LocalList $localList
            }

        {($_ -ieq 'new')}
            {
                New-Fudgefile -Path $FudgefilePath -Key $Key -Install:$Install -Dev:$Dev -DevOnly:$DevOnly
            }

        {($_ -ieq 'delete')}
            {
                Remove-Fudgefile -Path $FudgefilePath -Uninstall:$Uninstall -Dev:$Dev -DevOnly:$DevOnly
            }

        {($_ -ieq 'prune')}
            {
                $localList = Get-ChocolateyLocalList
                Invoke-FudgePrune -Config $config -LocalList $localList -Dev:$Dev -DevOnly:$DevOnly
            }

        {($_ -ieq 'clean')}
            {
                $localList = Get-ChocolateyLocalList
                Invoke-FudgeClean -LocalList $localList
            }
    }
}
finally
{
    Write-Details "`nDuration: $(([DateTime]::UtcNow - $timer).ToString())"
}