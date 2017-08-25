if ((Get-Module -Name FudgeTools | Measure-Object).Count -ne 0)
{
    Remove-Module -Name FudgeTools
}

$path = $MyInvocation.MyCommand.Path
$src = (Split-Path -Parent -Path $path) -ireplace '\\tests\\', '\src\'
$sut = ((Split-Path -Leaf -Path $path) -ireplace '\.Tests\.', '.') -ireplace '\.ps1', '.psm1'
Import-Module "$($src)\$($sut)"

Describe 'Write-Success' {
    Mock Write-Host { } -ModuleName FudgeTools

    Context 'With a message' {
        It 'Should write a message' {
            Write-Success -Message 'Tests'
            Assert-MockCalled Write-Host -Times 1 -Scope It -ModuleName FudgeTools
        }

        It 'Should write a message with no new line' {
            Write-Success -Message 'Tests' -NoNewLine
            Assert-MockCalled Write-Host -Times 1 -Scope It -ModuleName FudgeTools
        }
    }

    Context 'With no message passed' {
        It 'Should fail parameter validation' {
            { Write-Success -Message $null } | Should Throw 'The argument is null or empty'
            Assert-MockCalled Write-Host -Times 0 -Scope It -ModuleName FudgeTools
        }
    }
}


Describe 'Write-Information' {
    Mock Write-Host { } -ModuleName FudgeTools

    Context 'With a message' {
        It 'Should write a message' {
            Write-Information -Message 'Tests'
            Assert-MockCalled Write-Host -Times 1 -Scope It -ModuleName FudgeTools
        }

        It 'Should write a message with no new line' {
            Write-Information -Message 'Tests' -NoNewLine
            Assert-MockCalled Write-Host -Times 1 -Scope It -ModuleName FudgeTools
        }
    }

    Context 'With no message passed' {
        It 'Should fail parameter validation' {
            { Write-Information -Message $null } | Should Throw 'The argument is null or empty'
            Assert-MockCalled Write-Host -Times 0 -Scope It -ModuleName FudgeTools
        }
    }
}


Describe 'Write-Details' {
    Mock Write-Host { } -ModuleName FudgeTools

    Context 'With a message' {
        It 'Should write a message' {
            Write-Details -Message 'Tests'
            Assert-MockCalled Write-Host -Times 1 -Scope It -ModuleName FudgeTools
        }

        It 'Should write a message with no new line' {
            Write-Details -Message 'Tests' -NoNewLine
            Assert-MockCalled Write-Host -Times 1 -Scope It -ModuleName FudgeTools
        }
    }

    Context 'With no message passed' {
        It 'Should fail parameter validation' {
            { Write-Details -Message $null } | Should Throw 'The argument is null or empty'
            Assert-MockCalled Write-Host -Times 0 -Scope It -ModuleName FudgeTools
        }
    }
}


Describe 'Write-Notice' {
    Mock Write-Host { } -ModuleName FudgeTools

    Context 'With a message' {
        It 'Should write a message' {
            Write-Notice -Message 'Tests'
            Assert-MockCalled Write-Host -Times 1 -Scope It -ModuleName FudgeTools
        }

        It 'Should write a message with no new line' {
            Write-Notice -Message 'Tests' -NoNewLine
            Assert-MockCalled Write-Host -Times 1 -Scope It -ModuleName FudgeTools
        }
    }

    Context 'With no message passed' {
        It 'Should fail parameter validation' {
            { Write-Notice -Message $null } | Should Throw 'The argument is null or empty'
            Assert-MockCalled Write-Host -Times 0 -Scope It -ModuleName FudgeTools
        }
    }
}


Describe 'Write-Fail' {
    Mock Write-Host { } -ModuleName FudgeTools

    Context 'With a message' {
        It 'Should write a message' {
            Write-Fail -Message 'Tests'
            Assert-MockCalled Write-Host -Times 1 -Scope It -ModuleName FudgeTools
        }

        It 'Should write a message with no new line' {
            Write-Fail -Message 'Tests' -NoNewLine
            Assert-MockCalled Write-Host -Times 1 -Scope It -ModuleName FudgeTools
        }
    }

    Context 'With no message passed' {
        It 'Should fail parameter validation' {
            { Write-Fail -Message $null } | Should Throw 'The argument is null or empty'
            Assert-MockCalled Write-Host -Times 0 -Scope It -ModuleName FudgeTools
        }
    }
}


Describe 'Get-Levenshtein' {
    Context 'With no values passed' {
        It 'Should return 0' {
            Get-Levenshtein | Should Be 0
        }
    }

    Context 'With only one value passed' {
        It 'Should return 5 for value1' {
            Get-Levenshtein -Value1 'Hello' | Should Be 5
        }

        It 'Should return 8 for value1' {
            Get-Levenshtein -Value2 'Potatoes' | Should Be 8
        }
    }

    Context 'With both values being passed' {
        It 'Should be 0 when they are the same' {
            Get-Levenshtein -Value1 'Hello' -Value2 'Hello' | Should Be 0
        }

        It 'Should be 7 when values are Hello/Potatoes' {
            Get-Levenshtein -Value1 'Hello' -Value2 'Potatoes' | Should Be 7
        }
    }
}


Describe 'Test-NuspecPath' {
    Context 'With no path passed' {
        It 'Should return false with no path' {
            Test-NuspecPath | Should Be $false
        }

        It 'Should return false with null path' {
            Test-NuspecPath -Path $null | Should Be $false
        }

        It 'Should return false with empty path' {
            Test-NuspecPath -Path ([string]::Empty) | Should Be $false
        }
    }

    Context 'With a path passed' {
        It 'Should fail when path does not exist' {
            Mock Test-Path { return $false } -ModuleName FudgeTools
            Test-NuspecPath -Path 'fake' | Should Be $false
            Assert-MockCalled Test-Path -Times 1 -Scope It -ModuleName FudgeTools
        }
        
        It 'Should fail when path is a directory' {
            Mock Test-Path { return $true } -ModuleName FudgeTools
            Mock Test-PathDirectory { return $true } -ModuleName FudgeTools

            Test-NuspecPath -Path 'fake' | Should Be $false

            Assert-MockCalled Test-Path -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Test-PathDirectory -Times 1 -Scope It -ModuleName FudgeTools
        }

        It 'Should pass when path is a file' {
            Mock Test-Path { return $true } -ModuleName FudgeTools
            Mock Test-PathDirectory { return $false } -ModuleName FudgeTools

            Test-NuspecPath -Path 'fake' | Should Be $true

            Assert-MockCalled Test-Path -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Test-PathDirectory -Times 1 -Scope It -ModuleName FudgeTools
        }
    }
}


Describe 'Test-XmlContent' {
    Context 'With no path passed' {
        It 'Should return false with no path' {
            Test-XmlContent | Should Be $false
        }

        It 'Should return false with null path' {
            Test-XmlContent -Path $null | Should Be $false
        }

        It 'Should return false with empty path' {
            Test-XmlContent -Path ([string]::Empty) | Should Be $false
        }
    }

    Context 'With a path passed' {
        It 'Should fail when path does not exist' {
            Mock Test-Path { return $false } -ModuleName FudgeTools
            Test-XmlContent -Path 'fake' | Should Be $false
            Assert-MockCalled Test-Path -Times 1 -Scope It -ModuleName FudgeTools
        }

        It 'Should fail when content is invalid XML' {
            Mock Test-Path { return $true } -ModuleName FudgeTools
            Mock Get-Content { return 'invalid xml' } -ModuleName FudgeTools

            Test-XmlContent -Path 'fake' | Should Be $false

            Assert-MockCalled Test-Path -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Get-Content -Times 1 -Scope It -ModuleName FudgeTools
        }

        It 'Should pass when content is valid XML' {
            Mock Test-Path { return $true } -ModuleName FudgeTools
            Mock Get-Content { return '<root><value>something</value></root>' } -ModuleName FudgeTools

            Test-XmlContent -Path 'fake' | Should Be $true

            Assert-MockCalled Test-Path -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Get-Content -Times 1 -Scope It -ModuleName FudgeTools
        }
    }
}


Describe 'Test-NuspecContent' {
    Context 'With no content passed' {
        It 'Should fail with no content' {
            Test-NuspecContent | Should Be $false
        }
        
        It 'Should fail with null content' {
            Test-NuspecContent -Content $null | Should Be $false
        }
    }

    Context 'With content passed' {
        It 'Should fail when no package section' {
            Test-NuspecContent -Content ([xml]'<root></root>') | Should Be $false
        }
        
        It 'Should fail when no metadata section' {
            Test-NuspecContent -Content ([xml]'<package></package>') | Should Be $false
        }
        
        It 'Should pass with right sections' {
            Test-NuspecContent -Content ([xml]'<package><metadata></metadata></package>') | Should Be $true
        }
    }
}


Describe 'Get-XmlContent' {
    Context 'When path doesn not exist or XML is invalid' {
        Mock Test-XmlContent { return $false } -ModuleName FudgeTools

        It 'Should return null with no path' {
            Get-XmlContent | Should Be $null
            Assert-MockCalled Test-XmlContent -Times 1 -Scope It -ModuleName FudgeTools
        }

        It 'Should return null with a path' {
            Get-XmlContent -Path 'fake' | Should Be $null
            Assert-MockCalled Test-XmlContent -Times 1 -Scope It -ModuleName FudgeTools
        }
    }

    Context 'When path exists with valid XML' {
        Mock Test-XmlContent { return $true } -ModuleName FudgeTools
        Mock Get-Content { return '<root><value>something</value></root>' } -ModuleName FudgeTools

        It 'Should return the XML content' {
            Get-XmlContent -Path 'fake' | Should BeOfType System.Xml.XmlDocument
            Assert-MockCalled Test-XmlContent -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Get-Content -Times 1 -Scope It -ModuleName FudgeTools
        }
    }
}


Describe 'Test-PathDirectory' {
    Context 'When no path is passed' {
        It 'Should return false with no path' {
            Test-PathDirectory | Should Be $false
        }

        It 'Should return false with null path' {
            Test-PathDirectory -Path $null | Should Be $false
        }

        It 'Should return false with empty path' {
            Test-PathDirectory -Path ([string]::Empty) | Should Be $false
        }
    }

    Context 'When a path is passed' {
        It 'Should return false when path does not exist' {
            Mock Test-Path { return $false } -ModuleName FudgeTools
            Test-PathDirectory -Path 'fake' | Should Be $false
            Assert-MockCalled Test-Path -Times 1 -Scope It -ModuleName FudgeTools
        }

        It 'Should return false when path is a file' {
            Mock Test-Path { return $true } -ModuleName FudgeTools
            Mock Get-Item { return (New-Object -TypeName 'System.IO.FileInfo' -ArgumentList 'fake') } -ModuleName FudgeTools

            Test-PathDirectory -Path 'fake' | Should Be $false

            Assert-MockCalled Test-Path -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Get-Item -Times 1 -Scope It -ModuleName FudgeTools
        }

        It 'Should return true when path is a directory' {
            Mock Test-Path { return $true } -ModuleName FudgeTools
            Mock Get-Item { return (New-Object -TypeName 'System.IO.DirectoryInfo' -ArgumentList 'fake') } -ModuleName FudgeTools

            Test-PathDirectory -Path 'fake' | Should Be $true

            Assert-MockCalled Test-Path -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Get-Item -Times 1 -Scope It -ModuleName FudgeTools
        }
    }
}


Describe 'Get-FudgefilePath' {
    Context 'When no path is passed' {
        It 'Should return the root Fudgefile with no path' {
            Get-FudgefilePath | Should Be './Fudgefile'
        }

        It 'Should return the root Fudgefile with null path' {
            Get-FudgefilePath -Path $null | Should Be './Fudgefile'
        }

        It 'Should return the root Fudgefile with empty path' {
            Get-FudgefilePath -Path ([string]::Empty) | Should Be './Fudgefile'
        }
    }

    Context 'When a directory path is passed' {
        It 'Should return the path if is does not exist' {
            Mock Test-Path { return $false } -ModuleName FudgeTools
            Get-FudgefilePath -Path 'some/fake/path' | Should Be 'some/fake/path'
            Assert-MockCalled Test-Path -Times 1 -Scope It -ModuleName FudgeTools
        }

        It 'Should return the default Fudgefile at that path' {
            Mock Test-Path { return $true } -ModuleName FudgeTools
            Mock Test-PathDirectory { return $true } -ModuleName FudgeTools
            Mock Join-Path { return 'some/fake/path/Fudgefile' } -ModuleName FudgeTools

            Get-FudgefilePath -Path 'some/fake/path' | Should Be 'some/fake/path/Fudgefile'

            Assert-MockCalled Test-Path -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Test-PathDirectory -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Join-Path -Times 1 -Scope It -ModuleName FudgeTools
        }
    }

    Context 'When a file path is passed' {
        It 'Should return the path if is does not exist' {
            Mock Test-Path { return $false } -ModuleName FudgeTools
            Get-FudgefilePath -Path 'some/fake/path.json' | Should Be 'some/fake/path.json'
            Assert-MockCalled Test-Path -Times 1 -Scope It -ModuleName FudgeTools
        }

        It 'Should return the path' {
            Mock Test-Path { return $true } -ModuleName FudgeTools
            Mock Test-PathDirectory { return $false } -ModuleName FudgeTools

            Get-FudgefilePath -Path 'some/fake/path.json' | Should Be 'some/fake/path.json'

            Assert-MockCalled Test-Path -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Test-PathDirectory -Times 1 -Scope It -ModuleName FudgeTools
        }
    }
}


Describe 'Get-FudgefileContent' {
    Context 'When no path is passed' {
        It 'Should fail parameter validation for null' {
            { Get-FudgefileContent -Path $null } | Should Throw 'The argument is null or empty'
        }

        It 'Should fail parameter validation for empty' {
            { Get-FudgefileContent -Path ([string]::Empty) } | Should Throw 'The argument is null or empty'
        }
    }

    Context 'When a path is passed' {
        It 'Should fail because the path does not exist' {
            Mock Test-Path { return $false } -ModuleName FudgeTools
            { Get-FudgefileContent -Path 'fake' } | Should Throw 'Path to Fudgefile does not exist'
            Assert-MockCalled Test-Path -Times 1 -Scope It -ModuleName FudgeTools
        }

        It 'Should fail because content is not JSON' {
            Mock Test-Path { return $true } -ModuleName FudgeTools
            Mock Get-Content { return 'invalid json' } -ModuleName FudgeTools

            { Get-FudgefileContent -Path 'fake' } | Should Throw 'Invalid JSON'

            Assert-MockCalled Test-Path -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Get-Content -Times 1 -Scope It -ModuleName FudgeTools
        }
        

        It 'Should pass because content is valid JSON' {
            Mock Test-Path { return $true } -ModuleName FudgeTools
            Mock Get-Content { return "{""key"":""value""}" } -ModuleName FudgeTools

            Get-FudgefileContent -Path 'fake' | Should BeOfType PSCustomObject

            Assert-MockCalled Test-Path -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Get-Content -Times 1 -Scope It -ModuleName FudgeTools
        }
    }
}


Describe 'Remove-Fudgefile' {
    Mock Write-Information { } -ModuleName FudgeTools
    Mock Write-Success { } -ModuleName FudgeTools
    Mock Write-Details { } -ModuleName FudgeTools
    Mock Write-Fail { } -ModuleName FudgeTools

    Context 'When no path is passed' {
        It 'Should fail parameter validation for null' {
            { Remove-Fudgefile -Path $null } | Should Throw 'The argument is null or empty'
        }

        It 'Should fail parameter validation for empty' {
            { Remove-Fudgefile -Path ([string]::Empty) } | Should Throw 'The argument is null or empty'
        }
    }

    Context 'When a path is passed' {
        It 'Should fail because the path does not exist' {
            Mock Test-Path { return $false } -ModuleName FudgeTools
            { Remove-Fudgefile -Path 'fake' } | Should Not Throw
            Assert-MockCalled Test-Path -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Write-Fail -Times 1 -Scope It -ModuleName FudgeTools
        }

        It 'Should pass because the path exists' {
            Mock Test-Path { return $true } -ModuleName FudgeTools
            Mock Remove-Item { } -ModuleName FudgeTools

            { Remove-Fudgefile -Path 'fake' } | Should Not Throw

            Assert-MockCalled Test-Path -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Remove-Item -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Write-Information -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Write-Success -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Write-Details -Times 1 -Scope It -ModuleName FudgeTools
        }
    }

    Context 'When a path is passed with uninstall flag' {
        It 'Should pass because the path exists' {
            Mock Test-Path { return $true } -ModuleName FudgeTools
            Mock Get-FudgefileContent { return ('{"key":"value"}' | ConvertFrom-Json) } -ModuleName FudgeTools
            Mock Invoke-ChocolateyAction { } -ModuleName FudgeTools
            Mock Remove-Item { } -ModuleName FudgeTools

            { Remove-Fudgefile -Path 'fake' -Uninstall } | Should Not Throw

            Assert-MockCalled Test-Path -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Remove-Item -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Get-FudgefileContent -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Invoke-ChocolateyAction -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Write-Information -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Write-Success -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Write-Details -Times 1 -Scope It -ModuleName FudgeTools
        }
    }
}


Describe 'New-Fudgefile' {
    Mock Write-Information { } -ModuleName FudgeTools
    Mock Write-Success { } -ModuleName FudgeTools
    Mock Write-Details { } -ModuleName FudgeTools
    Mock Write-Fail { } -ModuleName FudgeTools
    Mock Out-File { } -ModuleName FudgeTools
    Mock Invoke-ChocolateyAction { } -ModuleName FudgeTools

    Context 'When no path is passed' {
        It 'Should fail parameter validation for null' {
            { New-Fudgefile -Path $null } | Should Throw 'The argument is null or empty'
        }

        It 'Should fail parameter validation for empty' {
            { New-Fudgefile -Path ([string]::Empty) } | Should Throw 'The argument is null or empty'
        }
    }

    Context 'When no values are passed, except the path' {
        It 'Should create an empty template' {
            { New-Fudgefile -Path 'fake' } | Should Not Throw

            Assert-MockCalled Write-Information -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Out-File -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Write-Success -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Write-Details -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Invoke-ChocolateyAction -Times 0 -Scope It -ModuleName FudgeTools
        }

        It 'Should create an empty template, and not run install' {
            { New-Fudgefile -Path 'fake' -Install } | Should Not Throw

            Assert-MockCalled Write-Information -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Out-File -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Write-Success -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Write-Details -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Invoke-ChocolateyAction -Times 0 -Scope It -ModuleName FudgeTools
        }
    }

    Context 'When a nuspec path is passed' {
        It 'Should fail for an invalid nuspec path' {
            Mock Test-NuspecPath { return $false } -ModuleName FudgeTools
            Mock Test-XmlContent { return $true } -ModuleName FudgeTools
            Mock Test-NuspecContent { return $true } -ModuleName FudgeTools
            Mock Get-XmlContent { return ([xml]'<root></root>') } -ModuleName FudgeTools

            { New-Fudgefile -Path 'fake' -Key 'fake/path.nuspec' } | Should Not Throw

            Assert-MockCalled Test-NuspecPath -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Test-XmlContent -Times 0 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Test-NuspecContent -Times 0 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Get-XmlContent -Times 0 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Write-Information -Times 0 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Write-Fail -Times 1 -Scope It -ModuleName FudgeTools
        }

        It 'Should fail for invalid XML content in nuspec file' {
            Mock Test-NuspecPath { return $true } -ModuleName FudgeTools
            Mock Test-XmlContent { return $false } -ModuleName FudgeTools
            Mock Test-NuspecContent { return $true } -ModuleName FudgeTools
            Mock Get-XmlContent { return ([xml]'<root></root>') } -ModuleName FudgeTools

            { New-Fudgefile -Path 'fake' -Key 'fake/path.nuspec' } | Should Not Throw

            Assert-MockCalled Test-NuspecPath -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Test-XmlContent -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Test-NuspecContent -Times 0 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Get-XmlContent -Times 0 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Write-Information -Times 0 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Write-Fail -Times 1 -Scope It -ModuleName FudgeTools
        }

        It 'Should fail for invalid nuspec content in file' {
            Mock Test-NuspecPath { return $true } -ModuleName FudgeTools
            Mock Test-XmlContent { return $true } -ModuleName FudgeTools
            Mock Test-NuspecContent { return $false } -ModuleName FudgeTools
            Mock Get-XmlContent { return ([xml]'<root></root>') } -ModuleName FudgeTools

            { New-Fudgefile -Path 'fake' -Key 'fake/path.nuspec' } | Should Not Throw

            Assert-MockCalled Test-NuspecPath -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Test-XmlContent -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Test-NuspecContent -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Get-XmlContent -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Write-Information -Times 0 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Write-Fail -Times 1 -Scope It -ModuleName FudgeTools
        }

        It 'Should create a populated template' {
            Mock Test-NuspecPath { return $true } -ModuleName FudgeTools
            Mock Test-XmlContent { return $true } -ModuleName FudgeTools
            Mock Test-NuspecContent { return $true } -ModuleName FudgeTools
            Mock Get-XmlContent { return ([xml]'<root></root>') } -ModuleName FudgeTools

            { New-Fudgefile -Path 'fake' -Key 'fake/path.nuspec' } | Should Not Throw

            Assert-MockCalled Test-NuspecPath -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Test-XmlContent -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Test-NuspecContent -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Get-XmlContent -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Write-Information -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Out-File -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Write-Success -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Write-Details -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Invoke-ChocolateyAction -Times 0 -Scope It -ModuleName FudgeTools
        }

        It 'Should create a populated template, and run install' {
            Mock Test-NuspecPath { return $true } -ModuleName FudgeTools
            Mock Test-XmlContent { return $true } -ModuleName FudgeTools
            Mock Test-NuspecContent { return $true } -ModuleName FudgeTools
            Mock Get-XmlContent { return ([xml]'<root></root>') } -ModuleName FudgeTools
            Mock Get-FudgefileContent { return $null } -ModuleName FudgeTools

            { New-Fudgefile -Path 'fake' -Key 'fake/path.nuspec' -Install } | Should Not Throw

            Assert-MockCalled Test-NuspecPath -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Test-XmlContent -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Test-NuspecContent -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Get-XmlContent -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Write-Information -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Out-File -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Write-Success -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Write-Details -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Get-FudgefileContent -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Invoke-ChocolateyAction -Times 1 -Scope It -ModuleName FudgeTools
        }
    }
}


Describe 'Test-AdminUser' {
    Context 'When no user principal can be found' {
        It 'Should return false' {
            Mock New-Object { return $null } -ModuleName FudgeTools
            Test-AdminUser | Should Be $false
            Assert-MockCalled New-Object -Times 1 -Scope It -ModuleName FudgeTools
        }
    }
}


Describe 'Test-Empty' {
    Context 'When no value is passed' {
        It 'Should return true for no value' {
            Test-Empty | Should be $true
        }
        
        It 'Should return true for null value' {
            Test-Empty -Value $null | Should be $true
        }
    }

    Context 'When an empty value is passed' {
        It 'Should return true for an empty array' {
            Test-Empty -Value @() | Should Be $true
        }
        
        It 'Should return true for an empty hashtable' {
            Test-Empty -Value @{} | Should Be $true
        }

        It 'Should return true for an empty string' {
            Test-Empty -Value ([string]::Empty) | Should Be $true
        }

        It 'Should return true for a whitespace string' {
            Test-Empty -Value "  " | Should Be $true
        }
    }

    Context 'When a valid value is passed' {
        It 'Should return false for a string' {
            Test-Empty -Value "test" | Should Be $false
        }

        It 'Should return false for a number' {
            Test-Empty -Value 1 | Should Be $false
        }

        It 'Should return false for an array' {
            Test-Empty -Value @('test') | Should Be $false
        }

        It 'Should return false for a hashtable' {
            Test-Empty -Value @{'key'='value';} | Should Be $false
        }
    }
}


Describe 'Test-Chocolatey' {
    Context 'When testing if Chocolatey is installed' {
        It 'Should return false when not installed' {
            Mock Invoke-Expression { throw 'choco not found' } -ModuleName FudgeTools
            Test-Chocolatey | Should Be $false
            Assert-MockCalled Invoke-Expression -Times 1 -Scope It -ModuleName FudgeTools
        }

        It 'Should return true when installed' {
            Mock Invoke-Expression { return '0.10.3' } -ModuleName FudgeTools
            Mock Write-Details { } -ModuleName FudgeTools

            Test-Chocolatey | Should Be $true
            
            Assert-MockCalled Write-Details -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Invoke-Expression -Times 1 -Scope It -ModuleName FudgeTools
        }
    }
}


Describe 'Install-Chocolatey' {
    Mock Write-Notice { } -ModuleName FudgeTools
    Mock Write-Success { } -ModuleName FudgeTools

    Context 'When installing Chocolatey' {
        Mock Invoke-Expression { } -ModuleName FudgeTools

        It 'Should set the execution policy when invalid' {
            Mock Get-ExecutionPolicy { return 'Restricted' } -ModuleName FudgeTools
            Mock Set-ExecutionPolicy { } -ModuleName FudgeTools

            { Install-Chocolatey } | Should Not Throw
            
            Assert-MockCalled Get-ExecutionPolicy -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Set-ExecutionPolicy -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Invoke-Expression -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Write-Notice -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Write-Success -Times 1 -Scope It -ModuleName FudgeTools
        }

        It 'Should not set execution policy' {
            Mock Get-ExecutionPolicy { return 'Unrestricted' } -ModuleName FudgeTools
            Mock Set-ExecutionPolicy { } -ModuleName FudgeTools

            { Install-Chocolatey } | Should Not Throw
            
            Assert-MockCalled Get-ExecutionPolicy -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Set-ExecutionPolicy -Times 0 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Invoke-Expression -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Write-Notice -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Write-Success -Times 1 -Scope It -ModuleName FudgeTools
        }
    }
}


Describe 'Invoke-Script' {
    Mock Invoke-Expression { } -ModuleName FudgeTools

    Context 'When no action is passed' {
        It 'Should fail parameter validation for null' {
            { Invoke-Script -Action $null } | Should Throw 'The argument is null or empty'
        }

        It 'Should fail parameter validation for empty' {
            { Invoke-Script -Action ([string]::Empty) } | Should Throw 'The argument is null or empty'
        }
    }

    Context 'When some of the parameter are not supplied' {        
        It 'Should do nothing when no stage is passed' {
            Mock Test-Empty { return $true } -ModuleName FudgeTools

            { Invoke-Script -Action 'action' } | Should Not Throw

            Assert-MockCalled Test-Empty -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Invoke-Expression -Times 0 -Scope It -ModuleName FudgeTools
        }
        
        It 'Should do nothing when no scripts are passed' {
            Mock Test-Empty { return $false } -ModuleName FudgeTools -ParameterFilter { $Value -ieq 'stage' }
            Mock Test-Empty { return $true } -ModuleName FudgeTools

            { Invoke-Script -Action 'action' -Stage 'stage' } | Should Not Throw

            Assert-MockCalled Test-Empty -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Test-Empty -Times 1 -Scope It -ModuleName FudgeTools -ParameterFilter { $Value -ieq 'stage' }
            Assert-MockCalled Invoke-Expression -Times 0 -Scope It -ModuleName FudgeTools
        }
    }

    Context 'When all values are passed' {
        It 'Should do nothing when a script does not exist for action' {
            Mock Test-Empty { return $true } -ModuleName FudgeTools -ParameterFilter { $Value -eq $null }
            Mock Test-Empty { return $false } -ModuleName FudgeTools

            { Invoke-Script -Action 'action' -Stage 'stage' -Scripts @{} } | Should Not Throw

            Assert-MockCalled Test-Empty -Times 3 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Test-Empty -Times 1 -Scope It -ModuleName FudgeTools -ParameterFilter { $Value -eq $null }
            Assert-MockCalled Invoke-Expression -Times 0 -Scope It -ModuleName FudgeTools
        }
        
        It 'Should invoke the script if one is found' {
            Mock Test-Empty { return $false } -ModuleName FudgeTools

            { Invoke-Script -Action 'install' -Stage 'pre' -Scripts @{'pre' = @{ 'install' = 'fake' }; } } | Should Not Throw

            Assert-MockCalled Test-Empty -Times 4 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Invoke-Expression -Times 1 -Scope It -ModuleName FudgeTools
        }
    }
}


Describe 'Start-ActionPackages' {
    Mock Invoke-Chocolatey { } -ModuleName FudgeTools

    Context 'When no action is passed' {
        It 'Should fail parameter validation for null' {
            { Start-ActionPackages -Action $null } | Should Throw 'The argument is null or empty'
        }

        It 'Should fail parameter validation for empty' {
            { Start-ActionPackages -Action ([string]::Empty) } | Should Throw 'The argument is null or empty'
        }
    }

    Context 'When parameters are passed' {
        It 'Should do nothing when no packages are passed' {
            Mock Test-Empty { return $true } -ModuleName FudgeTools
            { Start-ActionPackages -Action 'action' } | Should Not Throw
            Assert-MockCalled Test-Empty -Times 1 -Scope It -ModuleName FudgeTools
        }

        It 'Should call chocolatey once for one package' {
            $packages = '{"package1":""}' | ConvertFrom-Json
            Mock Test-Empty { return $false } -ModuleName FudgeTools

            { Start-ActionPackages -Action 'action' -Packages $packages } | Should Not Throw

            Assert-MockCalled Test-Empty -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Invoke-Chocolatey -Times 1 -Scope It -ModuleName FudgeTools
        }

        It 'Should call chocolatey once for one package and custom source' {
            $packages = '{"package1":""}' | ConvertFrom-Json
            Mock Test-Empty { return $false } -ModuleName FudgeTools
            Mock Invoke-Chocolatey { } -ModuleName FudgeTools -ParameterFilter { $Source -ieq 'custom' }

            { Start-ActionPackages -Action 'action' -Packages $packages -Source 'custom' } | Should Not Throw

            Assert-MockCalled Test-Empty -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Invoke-Chocolatey -Times 1 -Scope It -ModuleName FudgeTools -ParameterFilter { $Source -ieq 'custom' }
        }

        It 'Should call chocolatey thrice for three package' {
            $packages = '{"package1":"","package2":"","package3":""}' | ConvertFrom-Json
            Mock Test-Empty { return $false } -ModuleName FudgeTools

            { Start-ActionPackages -Action 'action' -Packages $packages } | Should Not Throw

            Assert-MockCalled Test-Empty -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Invoke-Chocolatey -Times 3 -Scope It -ModuleName FudgeTools
        }

        It 'Should call chocolatey once for three package, with key passed' {
            $packages = '{"package1":"","package2":"","package3":""}' | ConvertFrom-Json
            Mock Test-Empty { return $false } -ModuleName FudgeTools

            { Start-ActionPackages -Action 'action' -Key 'package2' -Packages $packages } | Should Not Throw

            Assert-MockCalled Test-Empty -Times 1 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Invoke-Chocolatey -Times 1 -Scope It -ModuleName FudgeTools
        }
    }
}


Describe 'Invoke-ChocolateyAction' {
    Mock Invoke-Script { } -ModuleName FudgeTools
    Mock Start-ActionPackages { } -ModuleName FudgeTools

    Context 'When no action is passed' {
        It 'Should fail parameter validation for null' {
            { Invoke-ChocolateyAction -Action $null } | Should Throw 'The argument is null or empty'
        }

        It 'Should fail parameter validation for empty' {
            { Invoke-ChocolateyAction -Action ([string]::Empty) } | Should Throw 'The argument is null or empty'
        }
    }

    Context 'When parameters are passed' {
        It 'Should fail when no config section is passed' {
            { Invoke-ChocolateyAction -Action 'action' -Config $null } | Should Throw 'Invalid Fudge configuration supplied'
        }

        It 'Should call pre, post and action once for packing' {
            { Invoke-ChocolateyAction -Action 'pack' -Config @{} } | Should Not Throw
            Assert-MockCalled Invoke-Script -Times 2 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Start-ActionPackages -Times 1 -Scope It -ModuleName FudgeTools
        }

        It 'Should call pre, post and action once for install and no dev' {
            { Invoke-ChocolateyAction -Action 'install' -Config @{} } | Should Not Throw
            Assert-MockCalled Invoke-Script -Times 2 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Start-ActionPackages -Times 1 -Scope It -ModuleName FudgeTools
        }

        It 'Should call pre, post and action twice for install with dev' {
            { Invoke-ChocolateyAction -Action 'install' -Config @{} -Dev } | Should Not Throw
            Assert-MockCalled Invoke-Script -Times 2 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Start-ActionPackages -Times 2 -Scope It -ModuleName FudgeTools
        }

        It 'Should call pre, post and action once for install and dev only' {
            { Invoke-ChocolateyAction -Action 'install' -Config @{} -DevOnly -Dev } | Should Not Throw
            Assert-MockCalled Invoke-Script -Times 2 -Scope It -ModuleName FudgeTools
            Assert-MockCalled Start-ActionPackages -Times 1 -Scope It -ModuleName FudgeTools
        }
    }
}


Describe 'Get-ChocolateySource' {
    Context 'When getting a Chocolatey source parameter' {
        It 'Should return empty for no source' {
            Get-ChocolateySource | Should Be ([string]::Empty)
        }
        
        It 'Should return empty for null source' {
            Get-ChocolateySource -Source $null | Should Be ([string]::Empty)
        }
        
        It 'Should return empty for empty source' {
            Get-ChocolateySource -Source ([string]::Empty) | Should Be ([string]::Empty)
        }

        It 'Should return a parameter string for a local source' {
            Get-ChocolateySource -Source '.' | Should Be "-s '.'"
        }

        It 'Should return a parameter string for a URL source' {
            Get-ChocolateySource -Source 'http://test.repo.com' | Should Be "-s 'http://test.repo.com'"
        }
    }
}


Describe 'Format-ChocolateyList' {
    Context 'When no list is passed' {
        It 'Should return an empty hashtable' {
            Format-ChocolateyList | Should BeNullOrEmpty
        }
    }

    Context 'When a list is passed' {
        It 'Should return an empty hashtable for invalid values' {
            Format-ChocolateyList -List @('something') | Should BeNullOrEmpty
        }

        It 'Should return a non-empty hashtable for valid values' {
            $value = Format-ChocolateyList -List @('git.install 2.3.2')
            $value | Should Not BeNullOrEmpty
            $value.'git.install' | Should Be '2.3.2'
        }
    }
}