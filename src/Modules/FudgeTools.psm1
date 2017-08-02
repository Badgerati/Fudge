
function Write-Success
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Message
    )

    Write-Host $Message -ForegroundColor Green
}

function Write-Information
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Message
    )

    Write-Host $Message -ForegroundColor Magenta
}


function Write-Details
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Message
    )

    Write-Host $Message -ForegroundColor Cyan
}


function Write-Notice
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Message
    )

    Write-Host $Message -ForegroundColor Yellow
}


function Write-Fail
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Message
    )

    Write-Host $Message -ForegroundColor Red
}


# checks to see if the user has administrator priviledges
function Test-AdminUser
{
    try
    {
        $principal = New-Object System.Security.Principal.WindowsPrincipal([System.Security.Principal.WindowsIdentity]::GetCurrent())

        if ($principal -eq $null)
        {
            return $false
        }

        return $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    catch [exception]
    {
        Write-Fail 'Error checking user administrator priviledges'
        Write-Fail $_.Exception.Message
        return $false
    }
}


# checks to see if the passed value is empty
function Test-Empty
{
    param (
        $Value
    )

    if ($Value -eq $null)
    {
        return $true
    }

    if ($Value.GetType().Name -ieq 'string')
    {
        return [string]::IsNullOrWhiteSpace($Value)
    }

    $type = $Value.GetType().BaseType.Name.ToLowerInvariant()
    switch ($type)
    {
        'valuetype'
            {
                return $false
            }

        'array'
            {
                return (($Value | Measure-Object).Count -eq 0 -or $Value.Count -eq 0)
            }
    }

    return ([string]::IsNullOrWhiteSpace($Value) -or ($Value | Measure-Object).Count -eq 0 -or $Value.Count -eq 0)
}


# invoke scripts for pre/post actions
function Invoke-Script
{
    param (
        [string]
        $Action,

        [string]
        $Stage,

        $Scripts
    )

    # if there are no scripts, return
    if ((Test-Empty $Scripts) -or (Test-Empty $Scripts.$Stage))
    {
        return
    }

    $script = $Scripts.$Stage.$Action
    if ([string]::IsNullOrWhiteSpace($script))
    {
        return
    }

    # run the script
    Invoke-Expression -Command $script
}


# cycle through the passed packages, actioning upon them
function Start-ActionPackages
{
    param (
        [string]
        $Action,

        [string]
        $Key,

        $Packages
    )

    if (Test-Empty $Packages)
    {
        return
    }

    foreach ($name in $Packages.psobject.properties.name)
    {
        if (![string]::IsNullOrWhiteSpace($Key) -and $name -ine $Key)
        {
            continue
        }

        Invoke-Chocolatey -Action $Action -Package $name -Version ($Packages.$name)
    }
}


# invokes a chocolatey action, which also runs the pre/post scripts
function Invoke-ChocolateyAction
{
    param (
        [string]
        $Action,

        [string]
        $Key,

        $Config,

        [switch]
        $Dev
    )

    # invoke pre-script for current action
    Invoke-Script -Action $Action -Stage 'pre' -Scripts $Config.scripts

    # invoke chocolatey based on the action
    if ($Action -ieq 'pack')
    {
        Start-ActionPackages -Action $Action -Packages $Config.pack
    }
    else
    {
        Start-ActionPackages -Action $Action -Packages $Config.packages
        if ($Dev)
        {
            Start-ActionPackages -Action $Action -Packages $Config.devPackages
        }
    }
    
    # invoke post-script for current action
    Invoke-Script -Action $Action -Stage 'post' -Scripts $Config.scripts
}


# returns a list of packages installed localled
function Get-ChocolateyLocalList
{
    $map = @{}
    
    $list = (choco list -lo | Select-Object -Skip 1 | Select-Object -SkipLast 1)
    if (!$?)
    {
        throw 'Failed to retrieve local list of installed packages'
    }

    $list | ForEach-Object {
        if ($_ -imatch '^(?<name>.*?)\s+(?<version>[\d\.]+)$')
        {
            $map[$Matches['name']] = $Matches['version']
        }
    }

    return $map
}


# invokes fudge to display details of local packages
function Invoke-FudgeLocalDetails
{
    param (
        $Config,

        [string]
        $Key,

        $LocalList,

        [switch]
        $Dev
    )

    # maps for filtering packages
    $installed = @{}
    $updating = @{}
    $missing = @{}

    # package map
    $packages = @{}
    $Config.packages.psobject.properties.name | ForEach-Object { $packages[$_] = $Config.packages.$_ }
    if ($Dev)
    {
        $Config.devPackages.psobject.properties.name | ForEach-Object { $packages[$_] = $Config.devPackages.$_ }
    }

    # loop through packages
    $packages.Keys | ForEach-Object {
        if ([string]::IsNullOrWhiteSpace($Key) -or $_ -ieq $Key)
        {
            $version = $packages[$_]

            if ($LocalList.ContainsKey($_))
            {
                if ($LocalList[$_] -ieq $version -or [string]::IsNullOrWhiteSpace($version) -or $version -ieq 'latest')
                {
                    $installed[$_] = $version
                }
                else
                {
                    $updating[$_] = $version
                }
            }
            else
            {
                $missing[$_] = $version
            }
        }
    }

    if (![string]::IsNullOrWhiteSpace($Key) -and (Test-Empty $installed) -and (Test-Empty $updating) -and (Test-Empty $missing))
    {
        $missing[$Key] = 'Not in Fudgefile'
    }

    # output the details
    Write-Host "Package details from Fudgefile:"
    $installed.Keys | Sort-Object | ForEach-Object { Write-Success ("{0,-30} {1,-20} (installed: {2})" -f $_, $installed[$_], $LocalList[$_]) }
    $updating.Keys | Sort-Object | ForEach-Object { Write-Notice ("{0,-30} {1,-20} (installed: {2})" -f $_, $updating[$_], $LocalList[$_]) }
    $missing.Keys | Sort-Object | ForEach-Object { Write-Fail ("{0,-30} {1,-20}" -f $_, $missing[$_]) }
}


# invoke chocolate for the specific action
function Invoke-Chocolatey
{
    param (
        [string]
        $Action,

        [string]
        $Package,

        [string]
        $Version
    )

    if ([string]::IsNullOrWhiteSpace($Package))
    {
        return
    }

    switch ($Action.ToLowerInvariant())
    {
        'install'
            {
                if ([string]::IsNullOrWhiteSpace($Version) -or $Version -ieq 'latest')
                {
                    Write-Information "> Installing $($Package) (latest)"
                    choco install $Package -y | Out-Null
                }
                else
                {
                    Write-Information "> Installing $($Package) v$($Version)"
                    choco install $Package --version $Version -y | Out-Null
                }
            }
        
        'upgrade'
            {
                if ([string]::IsNullOrWhiteSpace($Version) -or $Version -ieq 'latest')
                {
                    Write-Information "> Upgrading $($Package) to latest"
                    choco upgrade $Package -y | Out-Null
                }
                else
                {
                    Write-Information "> Upgrading $($Package) to v$($Version)"
                    choco upgrade $Package --version $Version -y | Out-Null
                }
            }

        'uninstall'
            {
                Write-Information "> Uninstalling $($Package)"
                choco uninstall $Package -y -x | Out-Null
            }

        'pack'
            {
                Write-Information "> Packing $($Package)"
                $path = Split-Path -Parent -Path $Version
                $name = Split-Path -Leaf -Path $Version

                try
                {
                    Push-Location $path
                    choco pack $name | Out-Null
                }
                finally
                {
                    Pop-Location
                }
            }
    }

    if (!$?)
    {
        throw "Failed to $($Action) package: $($Package)"
    }

    Write-Success "$("$($Action)ed" -ireplace 'eed$', 'ed')"
}