
function Write-Success
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Message,

        [switch]
        $NoNewLine
    )

    Write-Host $Message -NoNewline:$NoNewLine -ForegroundColor Green
}

function Write-Information
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Message,

        [switch]
        $NoNewLine
    )

    Write-Host $Message -NoNewline:$NoNewLine -ForegroundColor Magenta
}


function Write-Details
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Message,

        [switch]
        $NoNewLine
    )

    Write-Host $Message -NoNewline:$NoNewLine -ForegroundColor Cyan
}


function Write-Notice
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Message,

        [switch]
        $NoNewLine
    )

    Write-Host $Message -NoNewline:$NoNewLine -ForegroundColor Yellow
}


function Write-Fail
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Message,

        [switch]
        $NoNewLine
    )

    Write-Host $Message -NoNewline:$NoNewLine -ForegroundColor Red
}


# returns the levenshtein distance between two strings
function Get-Levenshtein
{
    param (
        [string]
        $Value1,

        [string]
        $Value2
    )

    $len1 = $Value1.Length
    $len2 = $Value2.Length

    if ($len1 -eq 0) { return $len2 }
    if ($len2 -eq 0) { return $len1 }

    $Value1 = $Value1.ToLowerInvariant()
    $Value2 = $Value2.ToLowerInvariant()

    $dist = New-Object -Type 'int[,]' -Arg ($len1 + 1), ($len2 + 1)

    0..$len1 | ForEach-Object { $dist[$_, 0] = $_ }
    0..$len2 | ForEach-Object { $dist[0, $_] = $_ }

    $cost = 0

    for ($i = 1; $i -le $len1; $i++)
    {
        for ($j = 1; $j -le $len2; $j++)
        {
            $cost = 1
            if ($Value2[$j - 1] -ceq $Value1[$i - 1])
            {
                $cost = 0
            }
            
            $tempmin = [System.Math]::Min(([int]$dist[($i - 1), $j] + 1), ([int]$dist[$i, ($j - 1)] + 1))
            $dist[$i, $j] = [System.Math]::Min($tempmin, ([int]$dist[($i - 1), ($j - 1)] + $cost))
        }
    }
    
    # the actual distance is stored in the bottom right cell
    return $dist[$len1, $len2];
}


# checks to see if a passed path is a valid nuspec file path
function Test-NuspecPath
{
    param (
        [string]
        $Path
    )

    # ensure a path was passed
    if ([string]::IsNullOrWhiteSpace($Path))
    {
        return $false
    }

    # ensure path is exists, or is not just a directory path
    if (!(Test-Path $Path) -or (Test-PathDirectory $Path))
    {
        return $false
    }

    return $true
}


# checks to see if the file at passed path is a valid XML file
function Test-XmlContent
{
    param (
        [string]
        $Path
    )

    # fail if the path doesn't exist
    if ([string]::IsNullOrWhiteSpace($Path) -or !(Test-Path $Path))
    {
        return $false
    }

    # ensure the content parses as xml
    try
    {
        [xml](Get-Content $Path) | Out-Null
        return $true
    }
    catch [exception]
    {
        return $false
    }
}


# checks to see if the passed XML content is a valid nuspec file
function Test-NuspecContent
{
    param (
        [xml]
        $Content
    )

    return ($Content -ne $null -and $Content.package -ne $null -and $Content.package.metadata -ne $null)
}


# returns the XML content of the file at the passed path
function Get-XmlContent
{
    param (
        [string]
        $Path
    )

    if (!(Test-XmlContent $Path))
    {
        return $null
    }

    return [xml](Get-Content $Path)
}


# checks to see if a passed path is a directory
function Test-PathDirectory
{
    param (
        [string]
        $Path
    )

    if ([string]::IsNullOrWhiteSpace($Path) -or !(Test-Path $Path))
    {
        return $false
    }

    return ((Get-Item $Path) -is [System.IO.DirectoryInfo])
}


# returns a path to a fidgefile based on a passed path
function Get-FudgefilePath
{
    param (
        [string]
        $Path
    )

    $rootpath = './Fudgefile'
    if (![string]::IsNullOrWhiteSpace($Path))
    {
        if ((Test-Path $Path) -and (Test-PathDirectory $Path))
        {
            $rootpath = Join-Path $Path 'Fudgefile'
        }
        else
        {
            $rootpath = $Path
        }
    }

    return $rootpath
}


# returns the content of a passed fudgefile path
function Get-FudgefileContent
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path
    )

    if (!(Test-Path $Path))
    {
        throw "Path to Fudgefile does not exist: $($Path)"
    }

    $config = Get-Content -Path $Path -Raw | ConvertFrom-Json
    if (!$?)
    {
        throw "Failed to parse the Fudgefile at: $($Path)"
    }

    return $config
}


# removes an existing fudgefile, and if passed attempting to uninstall the packages
function Remove-Fudgefile
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path,

        [switch]
        $Uninstall,

        [switch]
        $Dev,

        [switch]
        $DevOnly
    )

    # ensure the path actually exists
    if (!(Test-Path $Path))
    {
        throw "Path to Fudgefile does not exist: $($Path)"
    }

    # uninstall packages first, if requested
    if ($Uninstall)
    {
        $config = Get-FudgefileContent $Path
        Invoke-ChocolateyAction -Action 'uninstall' -Key $null -Config $config -Dev:$Dev -DevOnly:$DevOnly
    }

    # remove the fudgefile
    Write-Information "> Deleting Fudgefile" -NoNewLine
    Remove-Item -Path $Path -Force -Confirm:$false | Out-Null
    Write-Success " > deleted"
    Write-Details "   > $($Path)"
}


# create a new empty fudgefile, or a new one from a nuspec file
function New-Fudgefile
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path,

        [string]
        $Key,

        [switch]
        $Install,

        [switch]
        $Dev,

        [switch]
        $DevOnly
    )

    # if the key is passed, ensure it's a valid nuspec file
    if (![string]::IsNullOrWhiteSpace($Key))
    {
        if (!(Test-NuspecPath $Key))
        {
            throw "Path to nuspec file doesn't exist or is invalid: $($Key)"
        }

        if (!(Test-XmlContent $Key))
        {
            throw "Nuspec file fails to parse as a valid XML document: $($Key)"
        }

        $nuspecData = Get-XmlContent $Key

        if (!(Test-NuspecContent $nuspecData))
        {
            throw "Nuspec file is missing the package/metadata XML sections: $($Key)"
        }

        $nuspecName = Split-Path -Leaf -Path $Key
        Write-Information "> Creating new Fudgefile using $($nuspecName)" -NoNewLine
    }
    else
    {
        Write-Information "> Creating new Fudgefile" -NoNewLine
    }

    # setup the empty fudgefile
    $fudge = @{
        'scripts' = @{
            'pre' = @{ 'install'= ''; 'uninstall'= ''; 'upgrade'= ''; 'pack'= ''; };
            'post' = @{ 'install'= ''; 'uninstall'= ''; 'upgrade'= ''; 'pack'= ''; };
        };
        'packages' = @{};
        'devPackages' = @{};
        'pack' = @{};
    }

    # insert any data from the nuspec
    if ($nuspecData -ne $null)
    {
        $meta = $nuspecData.package.metadata

        # if we have any dependencies, add them as packages
        if ($meta.dependencies -ne $null)
        {
            $meta.dependencies.dependency | ForEach-Object {
                $version = 'latest'
                if (![string]::IsNullOrWhiteSpace($_.version))
                {
                    $version = $_.version
                }

                $fudge.packages[$_.id] = $version
            }
        }

        # add the nuspec as a pack that can be packed
        $name = [System.IO.Path]::GetFileNameWithoutExtension($nuspecName)
        $fudge.pack[$name] = $Key
    }

    # save contents as json
    $fudge | ConvertTo-Json | Out-File -FilePath $Path -Encoding utf8 -Force
    Write-Success " > created"
    Write-Details "   > $($Path)"

    # now install the packages, if requested and if nuspec data was found
    if ($Install -and $nuspecData -ne $null)
    {
        $config = Get-FudgefileContent $Path
        Invoke-ChocolateyAction -Action 'install' -Key $null -Config $config -Dev:$Dev -DevOnly:$DevOnly
    }
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


# check to see if chocolatey is installed on the current machine
function Test-Chocolatey
{
    try
    {
        $output = Invoke-Expression -Command 'choco -v'
        Write-Details "Chocolatey v$($output)`n"
        return $true
    }
    catch
    {
        return $false
    }
}


# installs chocolatey
function Install-Chocolatey
{
    Write-Notice "Installing Chocolatey"

    $policies = @('Unrestricted', 'ByPass', 'AllSigned')
    if ($policies -inotcontains (Get-ExecutionPolicy))
    {
        Set-ExecutionPolicy Bypass -Force
    }

    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1')) | Out-Null

    Write-Success "Chocolatey installed`n"
}


# invoke scripts for pre/post actions
function Invoke-Script
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Action,

        [string]
        $Stage,

        $Scripts
    )

    # if there is no  stage, return
    if (Test-Empty $Stage)
    {
        return
    }

    # if there are no scripts, return
    if ((Test-Empty $Scripts) -or (Test-Empty $Scripts.$Stage))
    {
        return
    }

    $script = $Scripts.$Stage.$Action
    if (Test-Empty $script)
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
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
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
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Action,

        [string]
        $Key,

        $Config,

        [switch]
        $Dev,

        [switch]
        $DevOnly
    )

    # ensure the config object exists
    if ($Config -eq $null)
    {
        throw "Invalid Fudge configuration supplied"
    }

    # invoke pre-script for current action
    Invoke-Script -Action $Action -Stage 'pre' -Scripts $Config.scripts

    # invoke chocolatey based on the action
    if ($Action -ieq 'pack')
    {
        Start-ActionPackages -Action $Action -Packages $Config.pack
    }
    else
    {
        if (!$DevOnly)
        {
            Start-ActionPackages -Action $Action -Packages $Config.packages
        }

        if ($Dev)
        {
            Start-ActionPackages -Action $Action -Packages $Config.devPackages
        }
    }
    
    # invoke post-script for current action
    Invoke-Script -Action $Action -Stage 'post' -Scripts $Config.scripts
}


# returns the list of search returns from chocolatey
function Get-ChocolateySearchList
{
    param (
        [string]
        $Key
    )

    $list = (choco search $Key)
    if (!$?)
    {
        Write-Fail "$($list)"
        throw 'Failed to retrieve search results from Chocolatey'
    }

    return (Format-ChocolateyList -List $list)
}


# returns a list of packages installed localled
function Get-ChocolateyLocalList
{
    $list = (choco list -lo)
    if (!$?)
    {
        Write-Fail "$($list)"
        throw 'Failed to retrieve local list of installed packages'
    }

    return (Format-ChocolateyList -List $list)
}


# formats list/search results from chocolatey into a hash table
function Format-ChocolateyList
{
    param (
        [string[]]
        $List
    )

    $map = @{}

    $List | ForEach-Object {
        $row = $_ -ireplace ' Downloads cached for licensed users', ''
        if ($row -imatch '^(?<name>.*?)\s+(?<version>[\d\.]+(\s+\[Approved\]){0,1}(\s+-\s+Possibly broken){0,1}).*?$')
        {
            $map[$Matches['name']] = $Matches['version']
        }
    }

    return $map
}


# invokes fudge to search chocolatey for a package and display the results
function Invoke-Search
{
    param (
        [string]
        $Key,

        [int]
        $Limit,

        $LocalList
    )

    # basic validation on key and limit
    if ([string]::IsNullOrWhiteSpace($Key))
    {
        Write-Notice 'No search key provided'
        return
    }

    if ($Limit -lt 0)
    {
        Write-Notice "Limit for searching must be 0 or greater, found: $($Limit)"
        return
    }

    # get search results from chocolatey
    $results = Get-ChocolateySearchList -Key $Key
    $OrganisedResults = @()
    $count = 0

    # if limit is 0, set to total results returned
    if ($Limit -eq 0)
    {
        $Limit = ($results | Measure-Object).Count
    }

    # perfect match
    if ($results.ContainsKey($Key))
    {
        $count++
        $OrganisedResults += @{'name' = $Key; 'version' = $results[$Key]; }
        $results.Remove($Key)
    }

    # starts with (with added '.' for sub-packages)
    if ($count -lt $Limit)
    {
        $results.Clone().Keys | ForEach-Object {
            if ($_.StartsWith("$($Key)."))
            {
                $count++
                $OrganisedResults += @{'name' = $_; 'version' = $results[$_]; }
                $results.Remove($_)
            }
        }
    }

    # starts with
    if ($count -lt $Limit)
    {
        $results.Clone().Keys | ForEach-Object {
            if ($_.StartsWith($Key))
            {
                $count++
                $OrganisedResults += @{'name' = $_; 'version' = $results[$_]; }
                $results.Remove($_)
            }
        }
    }

    # contains
    if ($count -lt $Limit)
    {
        $results.Clone().Keys | ForEach-Object {
            if ($_.Contains($Key))
            {
                $count++
                $OrganisedResults += @{'name' = $_; 'version' = $results[$_]; }
                $results.Remove($_)
            }
        }
    }

    # levenshtein
    if ($count -lt $Limit)
    {
        $leven = @()

        $results.Keys | ForEach-Object {
            $leven += @{'name' = $_; 'version' = $results[$_]; 'dist' = (Get-Levenshtein $Key $_) }
        }

        $leven | Sort-Object { $_.dist } | ForEach-Object {
            $OrganisedResults += @{'name' = $_.name; 'version' = $_.version; }
        }
    }

    # display the search results
    $OrganisedResults | Select-Object -First $Limit | ForEach-Object {
        if ($LocalList.ContainsKey($_.name))
        {
            ($_.version -imatch '^(?<version>[\d\.]+).*?$') | Out-Null

            if ($Matches['version'] -eq $LocalList[$_.name])
            {
                Write-Success ("{0,-30} {1,-40} (installed: {2})" -f $_.name, $_.version, $LocalList[$_.name])
            }
            else
            {
                Write-Notice ("{0,-30} {1,-40} (installed: {2})" -f $_.name, $_.version, $LocalList[$_.name])
            }
        }
        else
        {
            Write-Host ("{0,-30} {1,-30}" -f $_.name, $_.version)
        }
    }

    # display the total
    $total = ($OrganisedResults | Measure-Object).Count
    Write-Notice "$($total) package(s) found"
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
        $Dev,

        [switch]
        $DevOnly
    )

    # maps for filtering packages
    $installed = @{}
    $updating = @{}
    $missing = @{}

    # package map
    $packages = @{}

    if (!$DevOnly)
    {
        $Config.packages.psobject.properties.name | ForEach-Object { $packages[$_] = $Config.packages.$_ }
    }

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
                    Write-Information "> Installing $($Package) (latest)" -NoNewLine
                    $output = choco install $Package -y
                }
                else
                {
                    Write-Information "> Installing $($Package) v$($Version)" -NoNewLine
                    $output = choco install $Package --version $Version -y
                }
            }
        
        'upgrade'
            {
                if ([string]::IsNullOrWhiteSpace($Version) -or $Version -ieq 'latest')
                {
                    Write-Information "> Upgrading $($Package) to latest" -NoNewLine
                    $output = choco upgrade $Package -y
                }
                else
                {
                    Write-Information "> Upgrading $($Package) to v$($Version)" -NoNewLine
                    $output = choco upgrade $Package --version $Version -y
                }
            }

        'uninstall'
            {
                Write-Information "> Uninstalling $($Package)" -NoNewLine
                $output = choco uninstall $Package -y -x
            }

        'pack'
            {
                Write-Information "> Packing $($Package)" -NoNewLine
                $path = Split-Path -Parent -Path $Version
                $name = Split-Path -Leaf -Path $Version

                try
                {
                    Push-Location $path
                    $output = choco pack $name
                }
                finally
                {
                    Pop-Location
                }
            }
    }

    if (!$?)
    {
        $fail = $true

        # if we're uninstalling, make sure it was successful and the error isnt false
        if ($Action -ieq 'uninstall' -and ($output -ilike '*has been successfully uninstalled*' -or $output -ilike '*Cannot uninstall a non-existent package*'))
        {
            $fail = $false
        }

        if ($fail)
        {
            Write-Notice "`n`n$($output)`n"
            throw "Failed to $($Action) package: $($Package)"
        }
    }

    Write-Success " > $("$($Action)ed" -ireplace 'eed$', 'ed')"
}