# Fudge

[![MIT licensed](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/Badgerati/Fudge/master/LICENSE.txt)
[![MIT licensed](https://img.shields.io/badge/version-Beta-red.svg)](https://github.com/Badgerati/Fudge)

Fudge is a PowerShell tool to help manage software packages via Chocolatey for specific development projects. Think NPM and Bower, but for Chocolatey.

If you find any bugs, or have any feature requests, please raise them in the GitHub issues tab.

## Installing

[Fudge](https://chocolatey.org/packages/fudge) can be installed via Chocolatey soon.

## Features

* Uses a Fudgefile to control required software
* Allows you to version control required software to run websites, services and applications
* Ability to run pre/post install/upgrade/uninstall/pack scripts
* Can seperate out developer specific software which aren't needed for certain environments
* You can reinstall all packages, or just in/un/reinstall all packages
* Allows you to have mutliple nuspecs, which you can then pack one or all of with Fudge

## Description

Fudge is a PowerShell tool to help manage software packages via Chocolatey for specific development projects. Think NPM and Bower, but for Chocolatey.

Fudge uses a `Fudgefile` to control what software to install, upgrade or uninstall. You can define specific versions of software or just use the latest version.
Fudge also allows you to separate out specfic developer only software - which are only needed for developer/QA environments.

You can also define pre/post install/upgrade/uninstall scritps that need to be run. For example, you could install `redis` and have a `post install` script which sets up REDIS locally.

Fudge can also run `choco pack` on your nuspec files; allowing you to have mutliple nuspecs and then running `fudge pack website` for example, to pack your `website.nuspec`.
Just running `fudge pack` will pack everything.

## Example Fudgefile

Below is an example of what a `Fudgefile` looks like, with all components shown:

```json
{
    "scripts": {
        "pre": {
            "install": "<command or file-path>",
            "upgrade": "<command or file-path>",
            "uninstall": "<command or file-path>",
            "pack": "<command or file-path>"
        },
        "post": {
            "install": "<command or file-path>",
            "upgrade": "<command or file-path>",
            "uninstall": "<command or file-path>",
            "pack": "<command or file-path>"
        }
    },
    "packages": {
        "curl": "latest",
        "nodejs.install": "6.5.0"
    },
    "devPackages": {
        "git.install": "latest",
        "vim": "7.4.1641"
    },
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
| packages | These are the main packages that will be installed, upgraded or uninstalled |
| devPackages | These packages will only be touched if the `-Dev` switch is specified on the CLI |
| pack | This is a key-value map of paths to nuspecs files that can be packed via Chocolatey |

## Example Call

A normal call to Fudge will look as follows, assuming there's a Fudgefile at the current path:

```powershell
fudge install
fudge upgrade
fudge uninstall
fudge reinstall
fudge pack
```

To also install developer only packages:

```powershell
fudge install -Dev
```

To reinstall all packages:

```powershell
fudge reinstall
```

To only install one of the packages in the Fudgefile (also works with upgrade/uninstall/reinstall):

```powershell
fudge install 7zip.install
```

To pack all of your nuspec files:

```powershell
fudge pack
```

To only pack one of your nuspec files:

```powershell
fudge pack website
```

To specify a path to a Fudgefile:

```powershell
fudge upgrade -FudgefilePath '.\path\SomeFudgeFile'
```

## Todo

* Advanced search feature
* Add feature to add packages to the Fudgefile from the CLI
* `-DevOnly` flag, to only deal with `devPackages`
* Make `upgrade` install packages that are not yet installed from the Fudgefile

## Bugs and Feature Requests

For any bugs you may find or features you wish to request, please create an [issue](https://github.com/Badgerati/Fudge/issues "Issues") in GitHub.