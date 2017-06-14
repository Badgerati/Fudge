<#
    .SYNOPSIS
        Fudge is a tool to help you manage and version control Chocolatey packages required for environments to function
    
    .DESCRIPTION
        Fudge is a tool to help you manage and version control Chocolatey packages required for environments to function.
        This is done via a Fudgefile which allows you to specify packages (and their versions) to install. You can also
        specify dev-specific packages (like git, or fiddler)

        You can also define pre/post install/upgrade/uninstall scripts for additional functionality that may be required
    
    .PARAMETER Action
        The action that Fudge should take: install, upgrade, uninstall
    
    .PARAMETER FudgefilePath
        This will override looking for a default 'Fudgefile' at the root of the current path, and allow you to specify
        other files instead. This allows you to have multiple Fudgefiles
    
    .PARAMETER Dev
        Switch parameter, if supplied will also action upon the devPackages in the Fudgefile

    .EXAMPLE
        fudge install

    .EXAMPLE
        fudge upgrade -Dev
#>
param (
    [string]
    $Action,
    
    [string]
    $FudgefilePath,

    [switch]
    $Dev,

    [switch]
    $Version
)

# ensure if there's an error, we stop
$ErrorActionPreference = 'Stop'


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
        Write-Host 'Error checking user administrator priviledges'
        Write-Host $_.Exception.Message -ForegroundColor Red
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

# cycle through the passed packages, actioning upon them
function Start-ActionPackages
{
    param (
        $Action,
        $Packages
    )

    if (Test-Empty $Packages)
    {
        return
    }

    foreach ($key in $Packages.psobject.properties.name)
    {
        Invoke-Chocolatey -Action $Action -Package $key -Version ($Packages.$key)
    }
}

# invoke scripts for pre/post actions
function Invoke-Script
{
    param (
        $Scripts,
        $Action,
        $Stage
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
    powershell.exe /C $script
}

# invoke chocolate for the specific action
function Invoke-Chocolatey
{
    param (
        $Action,
        $Package,
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
                    Write-Host "> Installing $($Package)" -ForegroundColor Green
                    choco install $Package -y | Out-Null
                }
                else
                {
                    Write-Host "> Installing $($Package) v$($Version)" -ForegroundColor Green
                    choco install $Package --version $Version -y | Out-Null
                }
            }
        
        'upgrade'
            {
                if ([string]::IsNullOrWhiteSpace($Version) -or $Version -ieq 'latest')
                {
                    Write-Host "> Upgrading $($Package)" -ForegroundColor Magenta
                    choco upgrade $Package -y | Out-Null
                }
                else
                {
                    Write-Host "> Upgrading $($Package) to v$($Version)" -ForegroundColor Magenta
                    choco upgrade $Package --version $Version -y | Out-Null
                }
            }

        'uninstall'
            {
                Write-Host "> Uninstalling $($Package)" -ForegroundColor Yellow
                choco uninstall $Package -y -x | Out-Null
            }
    }

    if (!$?)
    {
        throw "Failed to $($Action) package: $($Package)"
    }
}


# output the version
$ver = 'v$version$'
Write-Host "Fudge $($ver)`n" -ForegroundColor Cyan

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
    $actions = @('install', 'upgrade', 'uninstall')
    if ((Test-Empty $Action) -or $actions -inotcontains $Action)
    {
        Write-Host "Unrecognised action supplied '$($Action)', should be either: $($actions -join ', ')" -ForegroundColor Red
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
        Write-Host "Path to Fudgefile does not exist at: $($path)" -ForegroundColor Red
        return
    }


    # deserialise the Fudgefile
    $config = Get-Content -Path $path -Raw | ConvertFrom-Json
    if (!$?)
    {
        Write-Host "Failed to parse the Fudgefile at: $($path)" -ForegroundColor Red
        return
    }


    # if there are no packages, just return
    if ((Test-Empty $config.packages) -and (!$Dev -or ($Dev -and (Test-Empty $config.devPackages))))
    {
        Write-Warning "There are no packages to $($Action)"
        return
    }


    # check if the console is elevated
    if (!(Test-AdminUser))
    {
        Write-Warning 'Must be running with administrator priviledges for Fudge to fully function'
        return
    }


    # check to see if chocolatey is installed - else install it
    powershell.exe /C "choco -v" | Out-Null
    if ($LASTEXITCODE -ne 0)
    {
        Write-Host "Installing Chocolatey" -ForegroundColor Yellow

        $policies = @('Unrestricted', 'ByPass', 'AllSigned')
        if ($policies -inotcontains (Get-ExecutionPolicy))
        {
            Set-ExecutionPolicy  Bypass -Force
        }

        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1')) | Out-Null
        Write-Host "Chocolatey installed" -ForegroundColor Green
    }

    
    # invoke pre-script for current action
    Invoke-Script -Action $Action -Stage 'pre' -Scripts $config.scripts


    # invoke chocolatey based on the action
    Start-ActionPackages -Action $Action -Packages $config.packages
    if ($Dev)
    {
        Start-ActionPackages -Action $Action -Packages $config.devPackages
    }

    
    # invoke post-script for current action
    Invoke-Script -Action $Action -Stage 'post' -Scripts $config.scripts
}
finally
{
    Write-Host "`nDuration: $(([DateTime]::UtcNow - $timer).ToString())" -ForegroundColor Cyan
}