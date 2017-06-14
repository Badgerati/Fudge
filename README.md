# Fudge

[![MIT licensed](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/Badgerati/Fudge/master/LICENSE.txt)
[![MIT licensed](https://img.shields.io/badge/version-Beta-red.svg)](https://github.com/Badgerati/Fudge)

Fudge is a PowerShell tool to help manage software packages via Chocolatey for specific development projects. Think NPM and Bower, but for Chocolatey.

Fudge is in Beta, so there may be bugs; any bugs/features should be raised in the GitHub issues tab.

## Installing

[Fudge](https://chocolatey.org/packages/fudge) can be installed via Chocolatey soon (and via NuGet soon also).

## Features

* Uses a Fudgefile to control required software
* Allows you to version control required software to run websites, services and applications
* Ability to run pre/post install/upgrade/uninstall scripts
* Can seperate out developer specific software which aren't needed for certain environments

## Description

Fudge is a PowerShell tool to help manage software packages via Chocolatey for specific development projects. Think NPM and Bower, but for Chocolatey.

Fudge uses a `Fudgefile` to control what software to install, upgrade or uninstall. You can define specific versions of software or just use the latest version.
Fudge also allows you to separate out specfic developer only software - which are only needed for developer/QA environments.

You can also define pre/post install/upgrade/uninstall scritps that need to be run. For example, you could install `redis` and have a `post install` script which sets up REDIS locally.

## Example Fudgefile

Below is an example of what a `Fudgefile` looks like, with all components shown:

```json
{
    "scripts": {
        "pre": {
            "install": "<command or file-path>",
            "upgrade": "<command or file-path>",
            "uninstall": "<command or file-path>"
        },
        "post": {
            "install": "<command or file-path>",
            "upgrade": "<command or file-path>",
            "uninstall": "<command or file-path>"
        }
    },
    "packages": {
        "curl": "latest",
        "nodejs.install": "6.5.0"
    },
    "devPackages": {
        "git.install": "latest",
        "vim": "7.4.1641"
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

## Example Call

A normal call to Fudge will look as follows, assuming there's a Fudgefile at the current path:

```powershell
fudge install
fudge upgrade
fudge uninstall
```

To also install developer only packages:

```powershell
fudge install -Dev
```

To specific a path to a Fudgefile:

```powershell
fudge upgrade -FudgefilePath '.\path\SomeFudgeFile'
```

## Bugs and Feature Requests

For any bugs you may find or features you wish to request, please create an [issue](https://github.com/Badgerati/Fudge/issues "Issues") in GitHub.