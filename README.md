# Fudge

[![MIT licensed](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/Badgerati/Fudge/master/LICENSE.txt)
[![Build status](https://ci.appveyor.com/api/projects/status/23t545fdqhash4tc/branch/develop?svg=true)](https://ci.appveyor.com/project/Badgerati/fudge/branch/develop)

[![Chocolatey](https://img.shields.io/chocolatey/v/fudge.svg?colorB=a1301c)](https://chocolatey.org/packages/fudge)
[![Chocolatey](https://img.shields.io/chocolatey/dt/fudge.svg?label=downloads&colorB=a1301c)](https://chocolatey.org/packages/fudge)
[![NuGet](https://img.shields.io/nuget/v/fudge.svg?colorB=1a1c58)](https://www.nuget.org/packages/fudge/)
[![NuGet](https://img.shields.io/nuget/dt/fudge.svg?colorB=1a1c58)](https://www.nuget.org/packages/fudge/)

Fudge is a PowerShell tool to help manage software packages via [Chocolatey](https://chocolatey.org) for specific development projects. Think NPM and Bower, but for Chocolatey.

If you find any bugs, or have any feature requests, please raise them in the GitHub issues tab.

* [Installing Fudge](#installing-fudge)
* [Features](#features)
* [Description](#description)
* [Example Fudgefile](#example-fudgefile)
* [Example Calls](#example-calls)
* [Bugs and Feature Requests](#bugs-and-feature-requests)

## Installing Fudge

Fudge can be installed via [Chocolatey](https://chocolatey.org/packages/fudge):

```powershell
choco install fudge
```

or via [NuGet](https://www.nuget.org/packages/fudge/):

```powershell
Install-Package fudge
```

## Features

* Uses a Fudgefile to control required software
* Allows you to version control required software to run websites, services and applications
* Ability to run pre/post install/upgrade/downgrade/uninstall/pack scripts
* Can separate out developer specific software which aren't needed for certain environments
* You can reinstall all packages, or just in/un/reinstall all packages
* Allows you to have multiple nuspecs, which you can then pack one or all of with Fudge
* See details about packages in a Fudgefile - such as which ones are installed or need upgrading
* Create empty template Fudgefiles, or create them from nuspec files or local packages
* Prune the machine to remove packages not in a Fudgefile (except chocolatey/fudge obviously!)
* Clean a machine of all packages installed (again, except chocolatey/fudge)

## Description

Fudge is a PowerShell tool to help manage software packages via Chocolatey for specific development projects. Think NPM and Bower, but for Chocolatey.

Fudge uses a `Fudgefile` to control what software to install, upgrade, downgrade or uninstall. You can define specific versions of software or just use the latest version.
Fudge also allows you to separate out specific developer only software - which are only needed for developer/QA environments.

You can also define pre/post install/upgrade/downgrade/uninstall scripts that need to be run. For example, you could install `redis` and have a `post install` script which sets up REDIS locally.

Fudge can also run `choco pack` on your nuspec files; allowing you to have multiple nuspecs and then running `fudge pack website` for example, to pack your `website.nuspec`.
Just running `fudge pack` will pack everything.

## Example Fudgefile

Below is an example of what a `Fudgefile` looks like, with all components shown:

```json
{
    "scripts": {
        "pre": {
            "install": "<command or file-path>",
            "upgrade": "<command or file-path>",
            "downgrade": "<command or file-path>",
            "uninstall": "<command or file-path>",
            "pack": "<command or file-path>"
        },
        "post": {
            "install": "<command or file-path>",
            "upgrade": "<command or file-path>",
            "downgrade": "<command or file-path>",
            "uninstall": "<command or file-path>",
            "pack": "<command or file-path>"
        }
    },
    "source": "<custom sources || blank for chocolatey || use -s arg>",
    "packages": [
        { "name": "curl" },
        {
            "name": "nodejs.install",
            "version": "6.5.0",
            "source": "<custom source for this package>",
            "params": "<package parameters for installer>",
            "args": "<other arguments you wish to pass>"
        }
    ],
    "devPackages": [
        { "name": "git.install" },
        {
            "name": "vim",
            "version": "7.4.1641"
        }
    ],
    "pack": {
        "website": "./nuspecs/website.nuspec",
        "service": "./nuspecs/service.nuspec"
    }
}
```

And that's it!

### Sections Defined

| Name | Description |
| ---- | ----------- |
| scripts | The `scripts` section is optional. Scripts can either be direct PowerShell command like `"Write-Host 'hello, world!'"`, or a path to a PowerShell script |
| packages | These are the main packages that will be installed, upgraded, downgraded or uninstalled |
| devPackages | These packages will only be touched if the `-dev` switch is specified on the CLI |
| pack | This is a key-value map of paths to nuspecs files that can be packed via Chocolatey |

## Example Calls

A normal call to Fudge will look as follows, assuming there's a Fudgefile at the current path:

```powershell
fudge install                   # install one or all packages (one if a package_id is passed)
fudge upgrade                   # upgrade one or all packages
fudge downgrade                 # downgrade one or all packages
fudge uninstall                 # uninstall one or all packages
fudge reinstall                 # reinstall one or all packages (runs uninstall then install)
fudge pack <id>                 # pack one or all nuspec files
fudge list                      # list information about packages in the Fudgefile
fudge search <id>               # search chocolatey for packages, but results are sorted
fudge new <path|local>          # create an empty Fudgefile, or a populated one from a nuspec/local
fudge renew <nuspec|local>      # restores  fudgefile packages to nuspecs/local or empty
fudge delete                    # deletes a Fudgefile, with option of uninstalling packages first
fudge prune                     # uninstalls packages not in a Fudgefile (except choco/fudge)
fudge clean                     # uninstalls all packages currently installed (except choco/fudge)
fudge which <id>                # returns the path for a command (ie, 7z: C:\...\7z.exe)
fudge rebuild                   # rebuilds the machine by running "clean" then "install"
fudge add <id>                  # adds a new package to the Fudgefile
fudge remove <id>               # removes a package from the Fudgefile
```

* To install developer only packages (also works with upgrade/downgrade/uninstall/reinstall):

```powershell
fudge install -dev              # this will install from packages and devPackages
fudge install -devOnly          # this will only install from the devPackages
```

* To only install one of the packages in the Fudgefile (also works with upgrade/downgrade/uninstall/reinstall):

```powershell
fudge install 7zip
fudge install 7zip -ad          # will adhoc install 7zip without checking Fudgefile
```

* To pack one or all of your nuspec files:

```powershell
fudge pack
fudge pack website
```

* To list information about packages in the Fudgefile (such as are they installed, etc):

```powershell
fudge list
fudge list checksum
fudge list -dev
```

* To search chocolatey for packages. The results returned are sorted so what you're looking for will be at (or close to) the top

```powershell
fudge search checksum
fudge search git -l 20          # -l limits the results displayed, default is 10 (0 is everything)
```

* To create a new empty Fudgefile, or one from a nuspec:

```powershell
fudge new                       # creates a new empty template Fudgefile at the current path
fudge new <nuspec_path>         # creates a new template Fudgefile, with packages/pack populated
fudge new -fp './custom'        # creates a new Fudgefile, but with a custom name
fudge new <nuspec_path> -i      # create new template from a nuspec, then installs the packages
fudge new local                 # creates a new Fudgefile using the packages currently installed
```

* To delete a Fudgefile:

```powershell
fudge delete                    # delete the default Fudgefile at the current path
fudge delete -fp './custom'     # delete a custom Fudgefile
fudge delete -u                 # delete the Fudgefile, but first uninstall the packages
```

* To prune a machine of unneeded packages:

```powershell
fudge prune                     # prunes the machine using the default Fudgefile
fudge prune -fp './custum'      # prunes the machine using a custom Fudgefile
fudge prune -d                  # pruning now also respects the devPackages
```

* To clean a machine of all packages:

```powershell
fudge clean                     # cleans the machine of all packages installed
```

* To find out where a command is running from on your machine:

```powershell
fudge which 7z                  # returns the path for the 7z command
```

* To rebuild a machine:

```powershell
fudge rebuild                   # rebuild the machine using the default Fudgefile
fudge rebuild -fp './custum'    # rebuild the machine using a custom Fudgefile
fudge rebuild -d                # rebuilding now also respects the devPackages
```

* To add a new package to a Fudgefile:

```powershell
fudge add curl                  # adds the curl package to the Fudgefile
fudge add curl@7.57.0 -i        # adds curl v7.57.0 to the Fudgefile, and installs curl
fudge add curl -d               # adds curl to the devPackages
```

* To remove a new package from a Fudgefile:

```powershell
fudge remove curl               # removes the curl package from the Fudgefile
fudge remove curl -u            # removes curl from the Fudgefile, and uninstalls curl
fudge remove curl -d            # removes curl from the devPackages
```

## Bugs and Feature Requests

For any bugs you may find or features you wish to request, please create an [issue](https://github.com/Badgerati/Fudge/issues "Issues") in GitHub.